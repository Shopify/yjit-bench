#include "liquid.h"
#include "variable.h"
#include "parser.h"
#include "expression.h"
#include "vm.h"

#include <stdio.h>

static ID id_rescue_strict_parse_syntax_error;

static ID id_ivar_parse_context;
static ID id_ivar_name;
static ID id_ivar_filters;

VALUE cLiquidCVariableExpression;

static VALUE frozen_empty_array;

static VALUE try_variable_strict_parse(VALUE uncast_args)
{
    variable_parse_args_t *parse_args = (void *)uncast_args;
    parser_t p;
    init_parser(&p, parse_args->markup, parse_args->markup_end);
    vm_assembler_t *code = parse_args->code;

    if (p.cur.type == TOKEN_EOS) {
        vm_assembler_add_push_nil(code);
        return Qnil;
    }

    parse_and_compile_expression(&p, code);

    while (parser_consume(&p, TOKEN_PIPE).type) {
        lexer_token_t filter_name_token = parser_must_consume(&p, TOKEN_IDENTIFIER);
        VALUE filter_name = token_to_rsym(filter_name_token);

        size_t arg_count = 0;
        size_t keyword_arg_count = 0;
        VALUE push_keywords_obj = Qnil;
        vm_assembler_t *push_keywords_code = NULL;

        if (parser_consume(&p, TOKEN_COLON).type) {
            do {
                if (p.cur.type == TOKEN_IDENTIFIER && p.next.type == TOKEN_COLON) {
                    VALUE key = token_to_rstr(parser_consume_any(&p));
                    parser_consume_any(&p);

                    keyword_arg_count++;

                    if (push_keywords_obj == Qnil) {
                        expression_t *push_keywords_expr;
                        // use an object to automatically free on an exception
                        push_keywords_obj = expression_new(cLiquidCExpression, &push_keywords_expr);
                        rb_obj_hide(push_keywords_obj);
                        push_keywords_code = &push_keywords_expr->code;
                    }

                    vm_assembler_add_push_const(push_keywords_code, key);
                    parse_and_compile_expression(&p, push_keywords_code);
                } else {
                    parse_and_compile_expression(&p, code);
                    arg_count++;
                }
            } while (parser_consume(&p, TOKEN_COMMA).type);
        }

        if (keyword_arg_count) {
            arg_count++;
            if (keyword_arg_count > 255)
                rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "Too many filter keyword arguments");

            vm_assembler_concat(code, push_keywords_code);
            vm_assembler_add_hash_new(code, keyword_arg_count);

            RB_GC_GUARD(push_keywords_obj);
        }
        vm_assembler_add_filter(code, filter_name, arg_count);
    }

    parser_must_consume(&p, TOKEN_EOS);

    return Qnil;
}

typedef struct variable_strict_parse_rescue {
    variable_parse_args_t *parse_args;
    size_t instructions_size;
    size_t constants_size;
    size_t stack_size;
} variable_strict_parse_rescue_t;

static VALUE variable_strict_parse_rescue(VALUE uncast_args, VALUE exception)
{
    variable_strict_parse_rescue_t *rescue_args = (void *)uncast_args;
    variable_parse_args_t *parse_args = rescue_args->parse_args;
    vm_assembler_t *code = parse_args->code;

    // undo partial strict parse
    uint8_t *last_constants_data_end = (uint8_t *)code->constants.data + rescue_args->constants_size;
    VALUE *const_ptr = (VALUE *)last_constants_data_end;
    st_table *constants_table = code->constants_table;

    while((uint8_t *)const_ptr < code->constants.data_end) {
        st_data_t key = (st_data_t)const_ptr[0];
        st_delete(constants_table, &key, 0);
        const_ptr++;
    }

    code->instructions.data_end = code->instructions.data + rescue_args->instructions_size;
    code->constants.data_end = last_constants_data_end;
    code->stack_size = rescue_args->stack_size;

    if (rb_obj_is_kind_of(exception, cLiquidSyntaxError) == Qfalse)
        rb_exc_raise(exception);

    VALUE markup_obj = rb_enc_str_new(parse_args->markup, parse_args->markup_end - parse_args->markup, utf8_encoding);
    VALUE variable_obj = rb_funcall(
        cLiquidVariable, id_rescue_strict_parse_syntax_error, 3,
        exception, markup_obj, parse_args->parse_context
    );

    // lax parse
    code->protected_stack_size = code->stack_size;
    rb_funcall(variable_obj, id_compile_evaluate, 1, parse_args->code_obj);
    if (code->stack_size != code->protected_stack_size + 1) {
        rb_raise(rb_eRuntimeError, "Liquid::Variable#compile_evaluate didn't leave exactly 1 new element on the stack");
    }

    return Qnil;
}

void internal_variable_compile_evaluate(variable_parse_args_t *parse_args)
{
    vm_assembler_t *code = parse_args->code;
    variable_strict_parse_rescue_t rescue_args = {
        .parse_args = parse_args,
        .instructions_size = c_buffer_size(&code->instructions),
        .constants_size = c_buffer_size(&code->constants),
        .stack_size = code->stack_size,
    };
    rb_rescue(try_variable_strict_parse, (VALUE)parse_args, variable_strict_parse_rescue, (VALUE)&rescue_args);
}

void internal_variable_compile(variable_parse_args_t *parse_args, unsigned int line_number)
{
    vm_assembler_t *code = parse_args->code;
    vm_assembler_add_render_variable_rescue(code, line_number);
    internal_variable_compile_evaluate(parse_args);
    vm_assembler_add_pop_write(code);
}

static VALUE variable_strict_parse_method(VALUE self, VALUE markup)
{
    StringValue(markup);
    check_utf8_encoding(markup, "markup");

    VALUE parse_context = rb_ivar_get(self, id_ivar_parse_context);

    expression_t *expression;
    VALUE expression_obj = expression_new(cLiquidCVariableExpression, &expression);

    variable_parse_args_t parse_args = {
        .markup = RSTRING_PTR(markup),
        .markup_end = RSTRING_END(markup),
        .code = &expression->code,
        .code_obj = expression_obj,
        .parse_context = parse_context,
    };
    try_variable_strict_parse((VALUE)&parse_args);
    RB_GC_GUARD(markup);
    assert(expression->code.stack_size == 1);
    vm_assembler_add_leave(&expression->code);

    rb_ivar_set(self, id_ivar_name, expression_obj);
    rb_ivar_set(self, id_ivar_filters, frozen_empty_array);

    return Qnil;
}

typedef struct {
    expression_t *expression;
    VALUE context;
} variable_expression_evaluate_args_t;

static VALUE try_variable_expression_evaluate(VALUE uncast_args)
{
    variable_expression_evaluate_args_t *args = (void *)uncast_args;
    return liquid_vm_evaluate(args->context, &args->expression->code);
}

static VALUE rescue_variable_expression_evaluate(VALUE uncast_args, VALUE exception)
{
    variable_expression_evaluate_args_t *args = (void *)uncast_args;
    vm_t *vm = vm_from_context(args->context);
    exception = vm_translate_if_filter_argument_error(vm, exception);
    rb_exc_raise(exception);
}

VALUE internal_variable_expression_evaluate(expression_t *expression, VALUE context)
{
    variable_expression_evaluate_args_t args = { expression, context };
    return rb_rescue(try_variable_expression_evaluate, (VALUE)&args, rescue_variable_expression_evaluate, (VALUE)&args);
}

static VALUE variable_expression_evaluate_method(VALUE self, VALUE context)
{
    expression_t *expression;
    Expression_Get_Struct(self, expression);
    return internal_variable_expression_evaluate(expression, context);
}

void liquid_define_variable(void)
{
    id_rescue_strict_parse_syntax_error = rb_intern("rescue_strict_parse_syntax_error");

    id_ivar_parse_context = rb_intern("@parse_context");
    id_ivar_name = rb_intern("@name");
    id_ivar_filters = rb_intern("@filters");

    frozen_empty_array = rb_ary_new();
    rb_ary_freeze(frozen_empty_array);
    rb_global_variable(&frozen_empty_array);

    rb_define_method(cLiquidVariable, "c_strict_parse", variable_strict_parse_method, 1);

    cLiquidCVariableExpression = rb_define_class_under(mLiquidC, "VariableExpression", cLiquidCExpression);
    rb_global_variable(&cLiquidCVariableExpression);
    rb_define_method(cLiquidCVariableExpression, "evaluate", variable_expression_evaluate_method, 1);
}

