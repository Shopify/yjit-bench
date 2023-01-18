#include "liquid.h"
#include "vm_assembler.h"
#include "expression.h"
#include "vm.h"

#define ARRAY_LENGTH(array) (sizeof(array) / sizeof(array[0]))

static st_table *builtin_filter_table;

// methods from Liquid::StandardFilters
filter_desc_t builtin_filters[] = {
    { .name = "size" },
    { .name = "downcase" },
    { .name = "upcase" },
    { .name = "capitalize" },
    { .name = "h" },
    { .name = "escape" },
    { .name = "escape_once" },
    { .name = "url_encode" },
    { .name = "url_decode" },
    { .name = "slice" },
    { .name = "truncate" },
    { .name = "truncatewords" },
    { .name = "split" },
    { .name = "strip" },
    { .name = "lstrip" },
    { .name = "rstrip" },
    { .name = "strip_html" },
    { .name = "strip_newlines" },
    { .name = "join" },
    { .name = "sort" },
    { .name = "sort_natural" },
    { .name = "where" },
    { .name = "uniq" },
    { .name = "reverse" },
    { .name = "map" },
    { .name = "compact" },
    { .name = "replace" },
    { .name = "replace_first" },
    { .name = "remove" },
    { .name = "remove_first" },
    { .name = "append" },
    { .name = "concat" },
    { .name = "prepend" },
    { .name = "newline_to_br" },
    { .name = "date" },
    { .name = "first" },
    { .name = "last" },
    { .name = "abs" },
    { .name = "plus" },
    { .name = "minus" },
    { .name = "times" },
    { .name = "divided_by" },
    { .name = "modulo" },
    { .name = "round" },
    { .name = "ceil" },
    { .name = "floor" },
    { .name = "at_least" },
    { .name = "at_most" },
    { .name = "default" },
};
static_assert(ARRAY_LENGTH(builtin_filters) < 256,
        "support for larger than byte sized indexing of filters has not yet been implemented");

static void vm_assembler_common_init(vm_assembler_t *code)
{
    code->max_stack_size = 0;
    code->stack_size = 0;
    code->protected_stack_size = 0;
    code->parsing = true;
}

void vm_assembler_init(vm_assembler_t *code)
{
    code->instructions = c_buffer_allocate(8);
    code->constants = c_buffer_allocate(8 * sizeof(VALUE));
    code->constants_table = st_init_numtable();
    vm_assembler_common_init(code);
}

void vm_assembler_reset(vm_assembler_t *code)
{
    c_buffer_reset(&code->instructions);
    c_buffer_reset(&code->constants);
    st_clear(code->constants_table);
    vm_assembler_common_init(code);
}

void vm_assembler_free(vm_assembler_t *code)
{
    c_buffer_free(&code->instructions);
    c_buffer_free(&code->constants);
    st_free_table(code->constants_table);
}

void vm_assembler_gc_mark(vm_assembler_t *code)
{
    c_buffer_rb_gc_mark(&code->constants);
}

VALUE vm_assembler_disassemble(const uint8_t *start_ip, const uint8_t *end_ip, const VALUE *constants)
{
    const uint8_t *ip = start_ip;
    VALUE output = rb_str_buf_new(32);
    VALUE constant = Qnil;

    while (ip < end_ip) {
        rb_str_catf(output, "0x%04lx: ", ip - start_ip);

        if (vm_assembler_opcode_has_constant(*ip)) {
            uint16_t constant_index = (ip[1] << 8) | ip[2];
            constant = RARRAY_AREF(*constants, constant_index);
        }

        switch (*ip) {
            case OP_LEAVE:
                rb_str_catf(output, "leave\n");
                break;

            case OP_POP_WRITE:
                rb_str_catf(output, "pop_write\n");
                break;

            case OP_PUSH_NIL:
                rb_str_catf(output, "push_nil\n");
                break;

            case OP_PUSH_TRUE:
                rb_str_catf(output, "push_true\n");
                break;

            case OP_PUSH_FALSE:
                rb_str_catf(output, "push_false\n");
                break;

            case OP_FIND_VAR:
                rb_str_catf(output, "find_var\n");
                break;

            case OP_LOOKUP_KEY:
                rb_str_catf(output, "lookup_key\n");
                break;

            case OP_NEW_INT_RANGE:
                rb_str_catf(output, "new_int_range\n");
                break;

            case OP_HASH_NEW:
                rb_str_catf(output, "hash_new(%u)\n", ip[1]);
                break;

            case OP_PUSH_INT8:
                rb_str_catf(output, "push_int8(%u)\n", ip[1]);
                break;

            case OP_PUSH_INT16:
            {
                int num = (ip[1] << 8) | ip[2];
                rb_str_catf(output, "push_int16(%u)\n", num);
                break;
            }

            case OP_RENDER_VARIABLE_RESCUE:
            {
                unsigned int line_number = bytes_to_uint24(ip + 1);
                rb_str_catf(output, "render_variable_rescue(line_number: %u)\n", line_number);
                break;
            }

            case OP_WRITE_RAW_W:
            case OP_WRITE_RAW:
            {
                const char *text;
                size_t size;
                const char *name;
                if (*ip == OP_WRITE_RAW_W) {
                    name = "write_raw_w";
                    size = bytes_to_uint24(&ip[1]);
                    text = (const char *)&ip[4];
                } else {
                    name = "write_raw";
                    size = ip[1];
                    text = (const char *)&ip[2];
                }
                VALUE string = rb_enc_str_new(text, size, utf8_encoding);
                rb_str_catf(output, "%s(%+"PRIsVALUE")\n", name, string);
                break;
            }

            case OP_WRITE_NODE:
                rb_str_catf(output, "write_node(%+"PRIsVALUE")\n", constant);
                break;

            case OP_PUSH_CONST:
                rb_str_catf(output, "push_const(%+"PRIsVALUE")\n", constant);
                break;

            case OP_FIND_STATIC_VAR:
                rb_str_catf(output, "find_static_var(%+"PRIsVALUE")\n", constant);
                break;

            case OP_LOOKUP_CONST_KEY:
                rb_str_catf(output, "lookup_const_key(%+"PRIsVALUE")\n", constant);
                break;

            case OP_LOOKUP_COMMAND:
                rb_str_catf(output, "lookup_command(%+"PRIsVALUE")\n", constant);
                break;

            case OP_FILTER:
            {
                VALUE filter_name = RARRAY_AREF(constant, 0);
                uint8_t num_args = RARRAY_AREF(constant, 1);
                rb_str_catf(output, "filter(name: %+"PRIsVALUE", num_args: %u)\n", filter_name, num_args);
                break;
            }

            case OP_BUILTIN_FILTER:
                rb_str_catf(output, "builtin_filter(name: :%s, num_args: %u)\n", builtin_filters[ip[1]].name, ip[2]);
                break;

            default:
                rb_str_catf(output, "<opcode number %d disassembly not implemented>\n", ip[0]);
                break;
        }
        liquid_vm_next_instruction(&ip);
    }
    return output;
}

struct merge_constants_table_func_args {
    st_table *hash;
    size_t increment_amount;
};

static int merge_constants_table(st_data_t key, st_data_t value, VALUE _arg)
{
    struct merge_constants_table_func_args *arg = (struct merge_constants_table_func_args *)_arg;
    st_table *dest_hash = arg->hash;
    uint16_t new_value = value + arg->increment_amount;
    st_insert(dest_hash, key, new_value);

    return ST_CONTINUE;
}

void update_instructions_constants_table_index_ref(c_buffer_t *instructions, size_t increment_amount, c_buffer_t *constants)
{
    uint8_t *ip = instructions->data;

    while (ip < instructions->data_end) {
        if (vm_assembler_opcode_has_constant(*ip)) {
            uint16_t constant_index = (ip[1] << 8) | ip[2];
            uint16_t new_constant_index = constant_index + increment_amount;
            ip[1] = new_constant_index >> 8;
            ip[2] = (uint8_t)new_constant_index;
        }

        liquid_vm_next_instruction((const uint8_t **)&ip);
    }
}

void vm_assembler_concat(vm_assembler_t *dest, vm_assembler_t *src)
{
    size_t dest_element_count = c_buffer_size(&dest->constants) / sizeof(VALUE);

    // merge src constants table into dest constants table with new index
    struct merge_constants_table_func_args arg;
    arg.hash = dest->constants_table;
    arg.increment_amount = dest_element_count;
    st_foreach(src->constants_table, merge_constants_table, (VALUE)&arg);

    // merge constants array
    c_buffer_concat(&dest->constants, &src->constants);

    update_instructions_constants_table_index_ref(&src->instructions, dest_element_count, &dest->constants);
    c_buffer_concat(&dest->instructions, &src->instructions);

    size_t max_src_stack_size = dest->stack_size + src->max_stack_size;
    if (max_src_stack_size > dest->max_stack_size)
        dest->max_stack_size = max_src_stack_size;

    dest->stack_size += src->stack_size;
}

void vm_assembler_require_stack_args(vm_assembler_t *code, unsigned int count)
{
    if (code->stack_size < code->protected_stack_size + count) {
        rb_raise(rb_eRuntimeError, "insufficient number of values on the stack");
    }
}


void vm_assembler_add_write_raw(vm_assembler_t *code, const char *string, size_t size)
{
    if (size > UINT8_MAX) {
        uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 4);
        instructions[0] = OP_WRITE_RAW_W;
        uint24_to_bytes((unsigned int)size, &instructions[1]);
    } else {
        uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 2);
        instructions[0] = OP_WRITE_RAW;
        instructions[1] = size;
    }

    c_buffer_write(&code->instructions, (char *)string, size);
}

void vm_assembler_add_write_node(vm_assembler_t *code, VALUE node)
{
    vm_assembler_add_op_with_constant(code, node, OP_WRITE_NODE);
}

void vm_assembler_add_push_fixnum(vm_assembler_t *code, VALUE num)
{
    long x = FIX2LONG(num);
    if (x >= INT8_MIN && x <= INT8_MAX) {
        vm_assembler_add_push_int8(code, x);
    } else if (x >= INT16_MIN && x <= INT16_MAX) {
        vm_assembler_add_push_int16(code, x);
    } else {
        vm_assembler_add_push_const(code, num);
    }
}

void vm_assembler_add_push_literal(vm_assembler_t *code, VALUE literal)
{
    switch (literal) {
    case Qnil:
        vm_assembler_add_push_nil(code);
        break;
    case Qtrue:
        vm_assembler_add_push_true(code);
        break;
    case Qfalse:
        vm_assembler_add_push_false(code);
        break;
    default:
        if (RB_FIXNUM_P(literal)) {
            vm_assembler_add_push_fixnum(code, literal);
        } else {
            vm_assembler_add_push_const(code, literal);
        }
        break;
    }
}

void vm_assembler_add_filter(vm_assembler_t *code, VALUE filter_name, size_t arg_count)
{
    if (arg_count > 254) {
        rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "Too many filter arguments");
    }
    code->stack_size -= arg_count; // pop arg_count + 1, push 1

    st_data_t builtin_index;
    bool is_builtin = st_lookup(builtin_filter_table, filter_name, &builtin_index);

    if (is_builtin) {
        uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 3);
        *instructions++ = OP_BUILTIN_FILTER;
        *instructions++ = builtin_index;
        *instructions++ = arg_count + 1; // include input
    } else {
        VALUE filter_args = rb_ary_new_capa(2);
        rb_ary_push(filter_args, filter_name);
        rb_ary_push(filter_args, arg_count + 1);
        vm_assembler_add_op_with_constant(code, filter_args, OP_FILTER);
    }
}

static void ensure_parsing(vm_assembler_t *code)
{
    if (!code->parsing)
        rb_raise(rb_eRuntimeError, "cannot extend code after it has finished being compiled");
}

void vm_assembler_add_evaluate_expression_from_ruby(vm_assembler_t *code, VALUE code_obj, VALUE expression)
{
    ensure_parsing(code);

    if (RB_SPECIAL_CONST_P(expression)) {
        vm_assembler_add_push_literal(code, expression);
        return;
    }

    switch (RB_BUILTIN_TYPE(expression)) {
        case T_DATA:
            if (RBASIC_CLASS(expression) == cLiquidCExpression) {
                vm_assembler_concat(code, &((expression_t *)DATA_PTR(expression))->code);
                vm_assembler_remove_leave(code);
                return;
            }
            break;
        case T_OBJECT:
        {
            VALUE klass = RBASIC_CLASS(expression);
            if (klass == cLiquidVariableLookup || klass == cLiquidRangeLookup) {
                rb_funcall(expression, id_compile_evaluate, 1, code_obj);
                return;
            }
            break;
        }
        default:
            break;
    }

    vm_assembler_add_push_const(code, expression);
}

void vm_assembler_add_find_variable_from_ruby(vm_assembler_t *code, VALUE code_obj, VALUE expression)
{
    ensure_parsing(code);

    if (RB_TYPE_P(expression, T_STRING)) {
        vm_assembler_add_find_static_variable(code, expression);
    } else {
        vm_assembler_add_evaluate_expression_from_ruby(code, code_obj, expression);
        vm_assembler_add_find_variable(code);
    }
}

void vm_assembler_add_lookup_command_from_ruby(vm_assembler_t *code, VALUE command)
{
    StringValue(command);
    ensure_parsing(code);
    vm_assembler_require_stack_args(code, 1);

    vm_assembler_add_lookup_command(code, command);
}

void vm_assembler_add_lookup_key_from_ruby(vm_assembler_t *code, VALUE code_obj, VALUE expression)
{
    ensure_parsing(code);
    vm_assembler_require_stack_args(code, 1);

    if (RB_TYPE_P(expression, T_STRING)) {
        vm_assembler_add_lookup_const_key(code, expression);
    } else {
        vm_assembler_add_evaluate_expression_from_ruby(code, code_obj, expression);
        vm_assembler_add_lookup_key(code);
    }
}

void vm_assembler_add_new_int_range_from_ruby(vm_assembler_t *code)
{
    ensure_parsing(code);
    vm_assembler_require_stack_args(code, 2);
    vm_assembler_add_new_int_range(code);
}

void vm_assembler_add_hash_new_from_ruby(vm_assembler_t *code, VALUE hash_size_obj)
{
    ensure_parsing(code);
    unsigned int hash_size = NUM2USHORT(hash_size_obj);
    vm_assembler_require_stack_args(code, hash_size * 2);

    vm_assembler_add_hash_new(code, hash_size);
}

void vm_assembler_add_filter_from_ruby(vm_assembler_t *code, VALUE filter_name, VALUE arg_count_obj)
{
    ensure_parsing(code);
    unsigned int arg_count = NUM2USHORT(arg_count_obj);
    vm_assembler_require_stack_args(code, arg_count + 1);
    filter_name = rb_str_intern(filter_name);

    vm_assembler_add_filter(code, filter_name, arg_count);
}

bool vm_assembler_opcode_has_constant(uint8_t ip) {
    if (
        ip == OP_PUSH_CONST ||
        ip == OP_WRITE_NODE ||
        ip == OP_FIND_STATIC_VAR ||
        ip == OP_LOOKUP_CONST_KEY ||
        ip == OP_LOOKUP_COMMAND ||
        ip == OP_FILTER
    ) {
        return true;
    }
    return false;
}

void liquid_define_vm_assembler(void)
{
    builtin_filter_table = st_init_numtable_with_size(ARRAY_LENGTH(builtin_filters));
    for (unsigned int i = 0; i < ARRAY_LENGTH(builtin_filters); i++) {
        filter_desc_t *filter = &builtin_filters[i];
        filter->sym = ID2SYM(rb_intern(filter->name));
        st_insert(builtin_filter_table, filter->sym, i);
    }
}
