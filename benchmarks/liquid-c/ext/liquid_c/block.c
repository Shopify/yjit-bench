#include "liquid.h"
#include "block.h"
#include "intutil.h"
#include "tokenizer.h"
#include "stringutil.h"
#include "vm.h"
#include "variable.h"
#include "context.h"
#include "parse_context.h"
#include "vm_assembler.h"
#include <stdio.h>

static ID
    intern_raise_missing_variable_terminator,
    intern_raise_missing_tag_terminator,
    intern_is_blank,
    intern_parse,
    intern_square_brackets,
    intern_unknown_tag_in_liquid_tag,
    intern_ivar_nodelist;

static VALUE tag_registry;
static VALUE variable_placeholder = Qnil;

typedef struct tag_markup {
    VALUE name;
    VALUE markup;
} tag_markup_t;

typedef struct parse_context {
    tokenizer_t *tokenizer;
    VALUE tokenizer_obj;
    VALUE ruby_obj;
} parse_context_t;

static void ensure_body_compiled(const block_body_t *body)
{
    if (!body->compiled) {
        rb_raise(rb_eRuntimeError, "Liquid::C::BlockBody has not been compiled");
    }
}

static void block_body_mark(void *ptr)
{
    block_body_t *body = ptr;
    if (body->compiled) {
        document_body_entry_mark(&body->as.compiled.document_body_entry);
        rb_gc_mark(body->as.compiled.nodelist);
    } else {
        rb_gc_mark(body->as.intermediate.parse_context);
        if (body->as.intermediate.vm_assembler_pool)
            rb_gc_mark(body->as.intermediate.vm_assembler_pool->self);
        if (body->as.intermediate.code)
            vm_assembler_gc_mark(body->as.intermediate.code);
    }
}

static void block_body_free(void *ptr)
{
    block_body_t *body = ptr;
    if (!body->compiled && body->as.intermediate.code) {
        // Free the assembler instead of recycling it because the vm_assembler_pool may have been GC'd
        vm_assembler_pool_free_assembler(body->as.intermediate.code);
    }
    xfree(body);
}

static size_t block_body_memsize(const void *ptr)
{
    const block_body_t *body = ptr;
    if (!ptr) return 0;
    if (body->compiled) {
        return sizeof(block_body_t);
    } else {
        return sizeof(block_body_t) + vm_assembler_alloc_memsize(body->as.intermediate.code);
    }
}

const rb_data_type_t block_body_data_type = {
    "liquid_block_body",
    { block_body_mark, block_body_free, block_body_memsize, },
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

#define BlockBody_Get_Struct(obj, sval) TypedData_Get_Struct(obj, block_body_t, &block_body_data_type, sval)

static VALUE block_body_allocate(VALUE klass)
{
    block_body_t *body;
    VALUE obj = TypedData_Make_Struct(klass, block_body_t, &block_body_data_type, body);

    body->compiled = false;
    body->obj = obj;
    body->as.intermediate.blank = true;
    body->as.intermediate.render_score = 0;
    body->as.intermediate.vm_assembler_pool = NULL;
    body->as.intermediate.code = NULL;
    return obj;
}

static VALUE block_body_initialize(VALUE self, VALUE parse_context)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);

    body->as.intermediate.parse_context = parse_context;
    body->as.intermediate.vm_assembler_pool = parse_context_get_vm_assembler_pool(parse_context);
    body->as.intermediate.code = vm_assembler_pool_alloc_assembler(body->as.intermediate.vm_assembler_pool);
    vm_assembler_add_leave(body->as.intermediate.code);

    return Qnil;
}

static int is_id(int c)
{
    return rb_isalnum(c) || c == '_';
}

static tag_markup_t internal_block_body_parse(block_body_t *body, parse_context_t *parse_context)
{
    tokenizer_t *tokenizer = parse_context->tokenizer;
    token_t token;
    tag_markup_t unknown_tag = { Qnil, Qnil };
    int render_score_increment = 0;

    while (true) {
        int token_start_line_number = tokenizer->line_number;
        if (token_start_line_number != 0) {
            rb_ivar_set(parse_context->ruby_obj, id_ivar_line_number, UINT2NUM(token_start_line_number));
        }
        tokenizer_next(tokenizer, &token);

        switch (token.type) {
            case TOKENIZER_TOKEN_NONE:
                goto loop_break;

            case TOKEN_INVALID:
            {
                VALUE str = rb_enc_str_new(token.str_full, token.len_full, utf8_encoding);

                ID raise_method_id = intern_raise_missing_variable_terminator;
                if (token.str_full[1] == '%') raise_method_id = intern_raise_missing_tag_terminator;

                rb_funcall(cLiquidBlockBody, raise_method_id, 2, str, parse_context->ruby_obj);
                goto loop_break;
            }
            case TOKEN_RAW:
            {
                const char *start = token.str_full, *end = token.str_full + token.len_full;
                const char *token_start = start, *token_end = end;

                if (token.lstrip)
                    token_start = read_while(start, end, rb_isspace);

                if (token.rstrip) {
                    if (tokenizer->bug_compatible_whitespace_trimming) {
                        token_end = read_while_reverse(token_start + 1, end, rb_isspace);
                    } else {
                        token_end = read_while_reverse(token_start, end, rb_isspace);
                    }
                }

                // Skip token entirely if there is no data to be rendered.
                if (token_start == token_end)
                    break;

                vm_assembler_add_write_raw(body->as.intermediate.code, token_start, token_end - token_start);
                render_score_increment += 1;

                if (body->as.intermediate.blank) {
                    const char *end = token.str_full + token.len_full;

                    if (read_while(token.str_full, end, rb_isspace) < end)
                        body->as.intermediate.blank = false;
                }
                break;
            }
            case TOKEN_VARIABLE:
            {
                variable_parse_args_t parse_args = {
                    .markup = token.str_trimmed,
                    .markup_end = token.str_trimmed + token.len_trimmed,
                    .code = body->as.intermediate.code,
                    .code_obj = body->obj,
                    .parse_context = parse_context->ruby_obj,
                };
                internal_variable_compile(&parse_args, token_start_line_number);
                render_score_increment += 1;
                body->as.intermediate.blank = false;
                break;
            }
            case TOKEN_TAG:
            {
                const char *start = token.str_trimmed, *end = token.str_trimmed + token.len_trimmed;

                // Imitate \s*(\w+)\s*(.*)? regex
                const char *name_start = read_while(start, end, rb_isspace);
                const char *name_end = read_while(name_start, end, is_id);
                long name_len = name_end - name_start;

                if (name_len == 0) {
                    if (name_start < end && *name_start == '#') { // inline comment
                        name_end++;
                        name_len++;
                    } else {
                        VALUE str = rb_enc_str_new(token.str_trimmed, token.len_trimmed, utf8_encoding);
                        unknown_tag = (tag_markup_t) { str, str };
                        goto loop_break;
                    }
                }

                if (name_len == 6 && strncmp(name_start, "liquid", 6) == 0) {
                    const char *markup_start = read_while(name_end, end, rb_isspace);
                    int line_number = token_start_line_number;
                    if (line_number) {
                        line_number += count_newlines(token.str_full, markup_start);
                    }

                    tokenizer_t saved_tokenizer = *tokenizer;
                    tokenizer_setup_for_liquid_tag(tokenizer, markup_start, end, line_number);
                    unknown_tag = internal_block_body_parse(body, parse_context);
                    *tokenizer = saved_tokenizer;
                    if (unknown_tag.name != Qnil) {
                        rb_funcall(cLiquidBlockBody, intern_unknown_tag_in_liquid_tag, 2, unknown_tag.name, parse_context->ruby_obj);
                        goto loop_break;
                    }
                    break;
                }

                VALUE tag_name = rb_enc_str_new(name_start, name_end - name_start, utf8_encoding);
                VALUE tag_class = rb_funcall(tag_registry, intern_square_brackets, 1, tag_name);

                const char *markup_start = read_while(name_end, end, rb_isspace);
                VALUE markup = rb_enc_str_new(markup_start, end - markup_start, utf8_encoding);

                if (tag_class == Qnil) {
                    unknown_tag = (tag_markup_t) { tag_name, markup };
                    goto loop_break;
                }

                VALUE new_tag = rb_funcall(tag_class, intern_parse, 4,
                        tag_name, markup, parse_context->tokenizer_obj, parse_context->ruby_obj);

                if (body->as.intermediate.blank && !RTEST(rb_funcall(new_tag, intern_is_blank, 0)))
                    body->as.intermediate.blank = false;

                if (tokenizer->raw_tag_body) {
                    if (tokenizer->raw_tag_body_len) {
                        vm_assembler_add_write_raw(body->as.intermediate.code, tokenizer->raw_tag_body,
                                                tokenizer->raw_tag_body_len);
                    }
                    tokenizer->raw_tag_body = NULL;
                    tokenizer->raw_tag_body_len = 0;
                } else {
                    vm_assembler_add_write_node(body->as.intermediate.code, new_tag);
                }

                render_score_increment += 1;
                break;
            }
            case TOKEN_BLANK_LIQUID_TAG_LINE:
                break;
        }
    }
loop_break:
    body->as.intermediate.render_score += render_score_increment;
    return unknown_tag;
}

static void ensure_intermediate(block_body_t *body)
{
    if (body->compiled) {
        rb_raise(rb_eRuntimeError, "Liquid::C::BlockBody is already compiled");
    }
}

static void ensure_intermediate_not_parsing(block_body_t *body)
{
    ensure_intermediate(body);

    if (body->as.intermediate.code->parsing) {
        rb_raise(rb_eRuntimeError, "Liquid::C::BlockBody is in a incompletely parsed state");
    }
}

static VALUE block_body_parse(VALUE self, VALUE tokenizer_obj, VALUE parse_context_obj)
{
    parse_context_t parse_context = {
        .tokenizer_obj = tokenizer_obj,
        .ruby_obj = parse_context_obj,
    };
    Tokenizer_Get_Struct(tokenizer_obj, parse_context.tokenizer);
    block_body_t *body;
    BlockBody_Get_Struct(self, body);

    ensure_intermediate_not_parsing(body);
    if (body->as.intermediate.parse_context != parse_context_obj) {
        rb_raise(rb_eArgError, "Liquid::C::BlockBody#parse called with different parse context");
    }
    vm_assembler_remove_leave(body->as.intermediate.code); // to extend block

    tag_markup_t unknown_tag = internal_block_body_parse(body, &parse_context);
    vm_assembler_add_leave(body->as.intermediate.code);

    return rb_yield_values(2, unknown_tag.name, unknown_tag.markup);
}


static VALUE block_body_freeze(VALUE self)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);

    if (body->compiled) return Qnil;

    VALUE parse_context = body->as.intermediate.parse_context;
    VALUE document_body = parse_context_get_document_body(parse_context);
    rb_check_frozen(document_body);

    vm_assembler_pool_t *assembler_pool = body->as.intermediate.vm_assembler_pool;
    vm_assembler_t *assembler = body->as.intermediate.code;
    bool blank = body->as.intermediate.blank;
    uint32_t render_score = body->as.intermediate.render_score;
    vm_assembler_t *code = body->as.intermediate.code;
    body->as.compiled.document_body_entry = document_body_write_block_body(document_body, blank, render_score, code);
    body->as.compiled.nodelist = Qundef;
    body->compiled = true;
    vm_assembler_pool_recycle_assembler(assembler_pool, assembler);

    rb_call_super(0, NULL);

    return Qnil;
}

static VALUE block_body_render_to_output_buffer(VALUE self, VALUE context, VALUE output)
{
    Check_Type(output, T_STRING);
    check_utf8_encoding(output, "output");

    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_body_compiled(body);
    document_body_entry_t *entry = &body->as.compiled.document_body_entry;
    document_body_ensure_compile_finished(entry->body);

    liquid_vm_render(document_body_get_block_body_header_ptr(entry), document_body_get_constants_ptr(entry), context, output);
    return output;
}

static VALUE block_body_blank_p(VALUE self)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    if (body->compiled) {
        block_body_header_t *body_header = document_body_get_block_body_header_ptr(&body->as.compiled.document_body_entry);
        return BLOCK_BODY_HEADER_BLANK_P(body_header) ? Qtrue : Qfalse;
    } else {
        return body->as.intermediate.blank ? Qtrue : Qfalse;
    }
}

static VALUE block_body_remove_blank_strings(VALUE self)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);

    ensure_intermediate_not_parsing(body);

    if (!body->as.intermediate.blank) {
        rb_raise(rb_eRuntimeError, "remove_blank_strings only support being called on a blank block body");
    }

    uint8_t *ip = body->as.intermediate.code->instructions.data;

    while (*ip != OP_LEAVE) {
        if (*ip == OP_WRITE_RAW) {
            if (ip[1]) { // if (size != 0)
                ip[0] = OP_JUMP_FWD; // effectively a no-op
                body->as.intermediate.render_score--;
            }
        } else if (*ip == OP_WRITE_RAW_W) {
            if (ip[1] || ip[2] || ip[3]) { // if (size != 0)
                ip[0] = OP_JUMP_FWD_W; // effectively a no-op
                body->as.intermediate.render_score--;
            }
        }
        liquid_vm_next_instruction((const uint8_t **)&ip);
    }

    return Qnil;
}

static void memoize_variable_placeholder(void)
{
    if (variable_placeholder == Qnil) {
        VALUE cLiquidCVariablePlaceholder = rb_const_get(mLiquidC, rb_intern("VariablePlaceholder"));
        variable_placeholder = rb_class_new_instance(0, NULL, cLiquidCVariablePlaceholder);
    }
}

// Deprecated: avoid using this for the love of performance
static VALUE block_body_nodelist(VALUE self)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_body_compiled(body);
    document_body_entry_t *entry = &body->as.compiled.document_body_entry;
    block_body_header_t *body_header = document_body_get_block_body_header_ptr(entry);

    memoize_variable_placeholder();

    if (body->as.compiled.nodelist != Qundef)
        return body->as.compiled.nodelist;

    VALUE nodelist = rb_ary_new_capa(body_header->render_score);

    const VALUE *constants = &entry->body->constants;
    const uint8_t *ip = block_body_instructions_ptr(body_header);
    while (true) {
        switch (*ip) {
            case OP_LEAVE:
                goto loop_break;
            case OP_WRITE_RAW_W:
            case OP_WRITE_RAW:
            {
                const char *text;
                size_t size;
                if (*ip == OP_WRITE_RAW_W) {
                    size = bytes_to_uint24(&ip[1]);
                    text = (const char *)&ip[4];
                } else {
                    size = ip[1];
                    text = (const char *)&ip[2];
                }
                VALUE string = rb_enc_str_new(text, size, utf8_encoding);
                rb_ary_push(nodelist, string);
                break;
            }
            case OP_WRITE_NODE:
            {
                uint16_t constant_index = (ip[1] << 8) | ip[2];
                VALUE node = RARRAY_AREF(*constants, constant_index);
                rb_ary_push(nodelist, node);
                break;
            }

            case OP_RENDER_VARIABLE_RESCUE:
                rb_ary_push(nodelist, variable_placeholder);
                break;
        }
        liquid_vm_next_instruction(&ip);
    }
loop_break:

    rb_ary_freeze(nodelist);
    body->as.compiled.nodelist = nodelist;
    return nodelist;
}

static VALUE block_body_disassemble(VALUE self)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    document_body_entry_t *entry = &body->as.compiled.document_body_entry;
    block_body_header_t *header = document_body_get_block_body_header_ptr(entry);
    const uint8_t *start_ip = block_body_instructions_ptr(header);
    return vm_assembler_disassemble(
        start_ip,
        start_ip + header->instructions_bytes,
        &entry->body->constants
    );
}


static VALUE block_body_add_evaluate_expression(VALUE self, VALUE expression)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_evaluate_expression_from_ruby(body->as.intermediate.code, self, expression);
    return self;
}

static VALUE block_body_add_find_variable(VALUE self, VALUE expression)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_find_variable_from_ruby(body->as.intermediate.code, self, expression);
    return self;
}

static VALUE block_body_add_lookup_command(VALUE self, VALUE name)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_lookup_command_from_ruby(body->as.intermediate.code, name);
    return self;
}

static VALUE block_body_add_lookup_key(VALUE self, VALUE expression)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_lookup_key_from_ruby(body->as.intermediate.code, self, expression);
    return self;
}

static VALUE block_body_add_new_int_range(VALUE self)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_new_int_range_from_ruby(body->as.intermediate.code);
    return self;
}

static VALUE block_body_add_hash_new(VALUE self, VALUE hash_size)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_hash_new_from_ruby(body->as.intermediate.code, hash_size);
    return self;
}

static VALUE block_body_add_filter(VALUE self, VALUE filter_name, VALUE num_args)
{
    block_body_t *body;
    BlockBody_Get_Struct(self, body);
    ensure_intermediate(body);
    vm_assembler_add_filter_from_ruby(body->as.intermediate.code, filter_name, num_args);
    return self;
}


void liquid_define_block_body(void)
{
    intern_raise_missing_variable_terminator = rb_intern("raise_missing_variable_terminator");
    intern_raise_missing_tag_terminator = rb_intern("raise_missing_tag_terminator");
    intern_is_blank = rb_intern("blank?");
    intern_parse = rb_intern("parse");
    intern_square_brackets = rb_intern("[]");
    intern_unknown_tag_in_liquid_tag = rb_intern("unknown_tag_in_liquid_tag");
    intern_ivar_nodelist = rb_intern("@nodelist");

    tag_registry = rb_funcall(cLiquidTemplate, rb_intern("tags"), 0);
    rb_global_variable(&tag_registry);

    VALUE cLiquidCBlockBody = rb_define_class_under(mLiquidC, "BlockBody", rb_cObject);
    rb_define_alloc_func(cLiquidCBlockBody, block_body_allocate);

    rb_define_method(cLiquidCBlockBody, "initialize", block_body_initialize, 1);
    rb_define_method(cLiquidCBlockBody, "parse", block_body_parse, 2);
    rb_define_method(cLiquidCBlockBody, "freeze", block_body_freeze, 0);
    rb_define_method(cLiquidCBlockBody, "render_to_output_buffer", block_body_render_to_output_buffer, 2);
    rb_define_method(cLiquidCBlockBody, "remove_blank_strings", block_body_remove_blank_strings, 0);
    rb_define_method(cLiquidCBlockBody, "blank?", block_body_blank_p, 0);
    rb_define_method(cLiquidCBlockBody, "nodelist", block_body_nodelist, 0);
    rb_define_method(cLiquidCBlockBody, "disassemble", block_body_disassemble, 0);

    rb_define_method(cLiquidCBlockBody, "add_evaluate_expression", block_body_add_evaluate_expression, 1);
    rb_define_method(cLiquidCBlockBody, "add_find_variable", block_body_add_find_variable, 1);
    rb_define_method(cLiquidCBlockBody, "add_lookup_command", block_body_add_lookup_command, 1);
    rb_define_method(cLiquidCBlockBody, "add_lookup_key", block_body_add_lookup_key, 1);
    rb_define_method(cLiquidCBlockBody, "add_new_int_range", block_body_add_new_int_range, 0);

    rb_define_method(cLiquidCBlockBody, "add_hash_new", block_body_add_hash_new, 1);
    rb_define_method(cLiquidCBlockBody, "add_filter", block_body_add_filter, 2);

    rb_global_variable(&variable_placeholder);
}

