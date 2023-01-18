#include <stdint.h>
#include <assert.h>

#include "liquid.h"
#include "vm.h"
#include "variable_lookup.h"
#include "intutil.h"
#include "document_body.h"

ID id_render_node;
ID id_vm;

static VALUE cLiquidCVM;

static void vm_mark(void *ptr)
{
    vm_t *vm = ptr;

    c_buffer_rb_gc_mark(&vm->stack);
    context_mark(&vm->context);
}

static void vm_free(void *ptr)
{
    vm_t *vm = ptr;
    c_buffer_free(&vm->stack);
    xfree(vm);
}

static size_t vm_memsize(const void *ptr)
{
    const vm_t *vm = ptr;
    return sizeof(vm_t) + c_buffer_capacity(&vm->stack);
}

const rb_data_type_t vm_data_type = {
    "liquid_vm",
    { vm_mark, vm_free, vm_memsize, },
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE vm_internal_new(VALUE context)
{
    vm_t *vm;
    VALUE obj = TypedData_Make_Struct(cLiquidCVM, vm_t, &vm_data_type, vm);
    vm->stack = c_buffer_init();

    vm->invoking_filter = false;

    context_internal_init(context, &vm->context);

    return obj;
}

vm_t *vm_from_context(VALUE context)
{
    VALUE vm_obj = rb_attr_get(context, id_vm);
    if (vm_obj == Qnil) {
        vm_obj = vm_internal_new(context);
        rb_ivar_set(context, id_vm, vm_obj);
    }
    // instance variable is hidden from ruby so should be safe to unwrap it without type checking
    return DATA_PTR(vm_obj);
}

bool liquid_vm_filtering(VALUE context)
{
    VALUE vm_obj = rb_attr_get(context, id_vm);
    if (vm_obj == Qnil)
        return false;
    vm_t *vm = DATA_PTR(vm_obj);
    return vm->invoking_filter;
}

static void write_fixnum(VALUE output, VALUE fixnum)
{
    long long number = RB_NUM2LL(fixnum);
    int write_length = snprintf(NULL, 0, "%lld", number);
    long old_size = RSTRING_LEN(output);
    long new_size = old_size + write_length;
    long capacity = rb_str_capacity(output);

    if (new_size > capacity) {
        do {
            capacity *= 2;
        } while (new_size > capacity);
        rb_str_resize(output, capacity);
    }
    rb_str_set_len(output, new_size);

    snprintf(RSTRING_PTR(output) + old_size, write_length + 1, "%lld", number);
}

static VALUE obj_to_s(VALUE obj)
{
    VALUE str = rb_funcall(obj, id_to_s, 0);

    if (RB_LIKELY(RB_TYPE_P(str, T_STRING)))
        return str;

    rb_raise(rb_eTypeError, "%"PRIsVALUE"#to_s returned a non-String convertible value of type %"PRIsVALUE,
            rb_obj_class(obj), rb_obj_class(str));
}

static void write_obj(VALUE output, VALUE obj)
{
    switch (TYPE(obj)) {
        default:
            obj = obj_to_s(obj);
            // fallthrough
        case T_STRING:
            rb_str_buf_append(output, obj);
            break;
        case T_FIXNUM:
            write_fixnum(output, obj);
            break;
        case T_ARRAY:
            for (long i = 0; i < RARRAY_LEN(obj); i++)
            {
                VALUE item = RARRAY_AREF(obj, i);

                if (RB_UNLIKELY(RB_TYPE_P(item, T_ARRAY))) {
                    // Normally liquid arrays are flat, but for safety and simplicity we
                    // leverage ruby's join that detects and raises on a recursion loop
                    rb_str_buf_append(output, rb_ary_join(item, Qnil));
                } else {
                    write_obj(output, item);
                }
            }
            break;
        case T_NIL:
            break;
    }
}

static inline void vm_stack_push(vm_t *vm, VALUE value)
{
    VALUE *stack_ptr = (VALUE *)vm->stack.data_end;
    assert(stack_ptr < (VALUE *)vm->stack.capacity_end);
    *stack_ptr++ = value;
    vm->stack.data_end = (uint8_t *)stack_ptr;
}

static inline VALUE vm_stack_pop(vm_t *vm)
{
    VALUE *stack_ptr = (VALUE *)vm->stack.data_end;
    stack_ptr--;
    assert((VALUE *)vm->stack.data <= stack_ptr);
    vm->stack.data_end = (uint8_t *)stack_ptr;
    return *stack_ptr;
}

static inline VALUE *vm_stack_pop_n_use_in_place(vm_t *vm, size_t n)
{
    VALUE *stack_ptr = (VALUE *)vm->stack.data_end;
    stack_ptr -= n;
    assert((VALUE *)vm->stack.data <= stack_ptr);
    vm->stack.data_end = (uint8_t *)stack_ptr;
    return stack_ptr;
}

static inline void vm_stack_reserve_for_write(vm_t *vm, size_t num_values)
{
    c_buffer_reserve_for_write(&vm->stack, num_values * sizeof(VALUE));
}

static VALUE vm_invoke_filter(vm_t *vm, VALUE filter_name, int num_args, VALUE *args)
{
    bool not_invokable = rb_hash_lookup(vm->context.filter_methods, filter_name) != Qtrue;
    if (RB_UNLIKELY(not_invokable)) {
        if (vm->context.strict_filters) {
            VALUE error_class = rb_const_get(mLiquid, rb_intern("UndefinedFilter"));
            rb_raise(error_class, "undefined filter %"PRIsVALUE, rb_sym2str(filter_name));
        }
        return args[0];
    }

    vm->invoking_filter = true;
    VALUE result = rb_funcallv(vm->context.strainer, RB_SYM2ID(filter_name), num_args, args);
    vm->invoking_filter = false;
    return rb_funcall(result, id_to_liquid, 0);
}

typedef struct vm_render_until_error_args {
    vm_t *vm;
    const uint8_t *ip; // use for initial address and to save an address for rescuing
    const size_t *const_ptr;

    /* rendering fields */
    VALUE output;
    const uint8_t *node_line_number;
} vm_render_until_error_args_t;

static VALUE raise_invalid_integer(VALUE unused_arg, VALUE exc)
{
    rb_raise(cLiquidArgumentError, "invalid integer");
}

// Equivalent to Integer(string) if string is an instance of String
static VALUE try_string_to_integer(VALUE string)
{
    return rb_str_to_inum(string, 0, true);
}

static VALUE range_value_to_integer(VALUE value)
{
    if (RB_INTEGER_TYPE_P(value)) {
        return value;
    } else if (value == Qnil) {
        return INT2FIX(0);
    } else if (RB_TYPE_P(value, T_STRING)) {
        return rb_str_to_inum(value, 0, false); // equivalent to String#to_i
    } else {
        value = obj_to_s(value);
        return rb_rescue2(try_string_to_integer, value, raise_invalid_integer, Qnil, rb_eArgError, (VALUE)0);
    }
}

#ifdef HAVE_RB_HASH_BULK_INSERT
#define hash_bulk_insert rb_hash_bulk_insert
#else
static void hash_bulk_insert(long argc, const VALUE *argv, VALUE hash)
{
    for (long i = 0; i < argc; i += 2) {
        rb_hash_aset(hash, argv[i], argv[i + 1]);
    }
}
#endif

// Actually returns a bool resume_rendering value
static VALUE vm_render_until_error(VALUE uncast_args)
{
    vm_render_until_error_args_t *args = (void *)uncast_args;
    const VALUE *constants = args->const_ptr;
    const uint8_t *ip = args->ip;
    vm_t *vm = args->vm;
    VALUE output = args->output;
    uint16_t constant_index;
    VALUE constant = Qnil;
    args->ip = NULL; // used by vm_render_rescue, NULL to indicate that it isn't in a rescue block

    while (true) {
        switch (*ip++) {
            case OP_LEAVE:
                return false;
            case OP_PUSH_NIL:
                vm_stack_push(vm, Qnil);
                break;
            case OP_PUSH_TRUE:
                vm_stack_push(vm, Qtrue);
                break;
            case OP_PUSH_FALSE:
                vm_stack_push(vm, Qfalse);
                break;
            case OP_PUSH_INT8:
            {
                int num = *(int8_t *)ip++; // signed
                vm_stack_push(vm, RB_INT2FIX(num));
                break;
            }
            case OP_PUSH_INT16:
            {
                int num = *(int8_t *)ip++; // big endian encoding, so first byte has sign
                num = (num << 8) | *ip++;
                vm_stack_push(vm, RB_INT2FIX(num));
                break;
            }
            case OP_FIND_STATIC_VAR:
            {
                constant_index = (ip[0] << 8) | ip[1];
                constant = constants[constant_index];
                ip += 2;
                VALUE value = context_find_variable(&vm->context, constant, Qtrue);
                vm_stack_push(vm, value);
                break;
            }
            case OP_FIND_VAR:
            {
                VALUE key = vm_stack_pop(vm);
                VALUE value = context_find_variable(&vm->context, key, Qtrue);
                vm_stack_push(vm, value);
                break;
            }
            case OP_LOOKUP_CONST_KEY:
            case OP_LOOKUP_COMMAND:
            {
                constant_index = (ip[0] << 8) | ip[1];
                constant = constants[constant_index];
                ip += 2;
                vm_stack_push(vm, constant);
            }
            /* fallthrough */
            case OP_LOOKUP_KEY:
            {
                bool is_command = ip[-3] == OP_LOOKUP_COMMAND;
                VALUE key = vm_stack_pop(vm);
                VALUE object = vm_stack_pop(vm);
                VALUE result = variable_lookup_key(vm->context.self, object, key, is_command);
                vm_stack_push(vm, result);
                break;
            }

            case OP_NEW_INT_RANGE:
            {
                VALUE end = range_value_to_integer(vm_stack_pop(vm));
                VALUE begin = range_value_to_integer(vm_stack_pop(vm));
                bool exclude_end = false;
                vm_stack_push(vm, rb_range_new(begin, end, exclude_end));
                break;
            }
            case OP_HASH_NEW:
            {
                size_t hash_size = *ip++;
                size_t num_keys_and_values = hash_size * 2;
                VALUE hash = rb_hash_new();
                VALUE *args_ptr = vm_stack_pop_n_use_in_place(vm, num_keys_and_values);
                hash_bulk_insert(num_keys_and_values, args_ptr, hash);
                vm_stack_push(vm, hash);
                break;
            }
            case OP_FILTER:
            case OP_BUILTIN_FILTER:
            {
                VALUE filter_name;
                uint8_t num_args;

                if (ip[-1] == OP_FILTER) {
                    constant_index = (ip[0] << 8) | ip[1];
                    constant = constants[constant_index];
                    filter_name = RARRAY_AREF(constant, 0);
                    num_args = RARRAY_AREF(constant, 1);
                    ip += 2;
                } else {
                    assert(ip[-1] == OP_BUILTIN_FILTER);
                    filter_name = builtin_filters[*ip++].sym;
                    num_args = *ip++; // includes input argument
                }

                VALUE *args_ptr = vm_stack_pop_n_use_in_place(vm, num_args);
                VALUE result = vm_invoke_filter(vm, filter_name, num_args, args_ptr);
                vm_stack_push(vm, result);
                break;
            }

            // Rendering instructions

            case OP_WRITE_RAW_W:
            case OP_WRITE_RAW:
            {
                const char *text;
                size_t size;
                if (ip[-1] == OP_WRITE_RAW_W) {
                    size = bytes_to_uint24(ip);
                    text = (const char *)&ip[3];
                    ip += 3 + size;
                } else {
                    size = *ip;
                    text = (const char *)&ip[1];
                    ip += 1 + size;
                }
                rb_str_cat(output, text, size);
                resource_limits_increment_write_score(vm->context.resource_limits, output);
                break;
            }
            case OP_JUMP_FWD_W:
            {
                size_t size = bytes_to_uint24(ip);
                ip += 3 + size;
                break;
            }

            case OP_JUMP_FWD:
            {
                uint8_t size = *ip;
                ip += 1 + size;
                break;
            }

            case OP_PUSH_CONST:
            {
                constant_index = (ip[0] << 8) | ip[1];
                constant = constants[constant_index];
                ip += 2;
                vm_stack_push(vm, constant);
                break;
            }

            case OP_WRITE_NODE:
            {
                constant_index = (ip[0] << 8) | ip[1];
                constant = constants[constant_index];
                ip += 2;
                rb_funcall(cLiquidBlockBody, id_render_node, 3, vm->context.self, output, constant);

                if (RARRAY_LEN(vm->context.interrupts)) {
                    return false;
                }

                resource_limits_increment_write_score(vm->context.resource_limits, output);
                break;
            }
            case OP_RENDER_VARIABLE_RESCUE:
                // Save state used by vm_render_rescue to rescue from a variable rendering exception
                args->node_line_number = ip;
                // vm_render_rescue will iterate from this instruction to the instruction
                // following OP_POP_WRITE_VARIABLE to resume rendering from
                ip += 3;
                args->ip = ip;
                break;
            case OP_POP_WRITE:
            {
                VALUE var_result = vm_stack_pop(vm);
                if (vm->context.global_filter != Qnil)
                    var_result = rb_funcall(vm->context.global_filter, id_call, 1, var_result);
                write_obj(output, var_result);
                args->ip = NULL; // mark the end of a rescue block, used by vm_render_rescue
                resource_limits_increment_write_score(vm->context.resource_limits, output);
                break;
            }

            default:
                rb_bug("invalid opcode: %u", ip[-1]);
        }
    }
}

// Evaluate instructions that avoid using rendering instructions and leave with the result on
// the top of the stack
VALUE liquid_vm_evaluate(VALUE context, vm_assembler_t *code)
{
    vm_t *vm = vm_from_context(context);
    vm_stack_reserve_for_write(vm, code->max_stack_size);
#ifndef NDEBUG
    size_t old_stack_byte_size = c_buffer_size(&vm->stack);
#endif

    vm_render_until_error_args_t args = {
        .vm = vm,
        .const_ptr = (const size_t *)code->constants.data,
        .ip = code->instructions.data
    };
    vm_render_until_error((VALUE)&args);
    VALUE ret = vm_stack_pop(vm);
    assert(old_stack_byte_size == c_buffer_size(&vm->stack));
    return ret;
}

void liquid_vm_next_instruction(const uint8_t **ip_ptr)
{
    const uint8_t *ip = *ip_ptr;

    switch (*ip++) {
        case OP_LEAVE:
        case OP_POP_WRITE:
        case OP_PUSH_NIL:
        case OP_PUSH_TRUE:
        case OP_PUSH_FALSE:
        case OP_FIND_VAR:
        case OP_LOOKUP_KEY:
        case OP_NEW_INT_RANGE:
            break;

        case OP_HASH_NEW:
        case OP_PUSH_INT8:
            ip++;
            break;

        case OP_BUILTIN_FILTER:
        case OP_PUSH_INT16:
        case OP_PUSH_CONST:
        case OP_WRITE_NODE:
        case OP_FIND_STATIC_VAR:
        case OP_LOOKUP_CONST_KEY:
        case OP_LOOKUP_COMMAND:
        case OP_FILTER:
            ip += 2;
            break;

        case OP_RENDER_VARIABLE_RESCUE:
            ip += 3;
            break;

        case OP_WRITE_RAW_W:
        case OP_JUMP_FWD_W:
        {
            size_t size = bytes_to_uint24(ip);
            ip += 3 + size;
            break;
        }

        case OP_WRITE_RAW:
        case OP_JUMP_FWD:
        {
            uint8_t size = *ip;
            ip += 1 + size;
            break;
        }

        default:
            rb_bug("invalid opcode: %u", ip[-1]);
    }
    *ip_ptr = ip;
}

VALUE vm_translate_if_filter_argument_error(vm_t *vm, VALUE exception)
{
    if (vm->invoking_filter) {
        if (rb_obj_is_kind_of(exception, rb_eArgError)) {
            VALUE cLiquidStrainerTemplate = rb_const_get(mLiquid, rb_intern("StrainerTemplate"));
            exception = rb_funcall(cLiquidStrainerTemplate, rb_intern("arg_exc_to_liquid_exc"), 1, exception);
        }
        vm->invoking_filter = false;
    }
    return exception;
}

typedef struct vm_render_rescue_args {
    vm_render_until_error_args_t *render_args;
    size_t old_stack_byte_size;
} vm_render_rescue_args_t;

// Actually returns a bool resume_rendering value
static VALUE vm_render_rescue(VALUE uncast_args, VALUE exception)
{
    vm_render_rescue_args_t *args = (void *)uncast_args;
    VALUE blank_tag = Qfalse; // tags are still rendered using Liquid::BlockBody.render_node
    vm_render_until_error_args_t *render_args = args->render_args;
    vm_t *vm = render_args->vm;

    exception = vm_translate_if_filter_argument_error(vm, exception);

    const uint8_t *ip = render_args->ip;
    if (!ip)
        rb_exc_raise(exception);

    // rescue for variable render, where ip is at the start of the render and we need to
    // skip to the end of the variable render to resume rendering if the error is handled
    enum opcode last_op;
    do {
        last_op = *ip;
        liquid_vm_next_instruction(&ip);
    } while (last_op != OP_POP_WRITE);
    render_args->ip = ip;
    // remove temporary stack values from variable evaluation
    vm->stack.data_end = vm->stack.data + args->old_stack_byte_size;

    assert(render_args->node_line_number);
    unsigned int node_line_number = bytes_to_uint24(render_args->node_line_number);
    VALUE line_number = node_line_number != 0 ? UINT2NUM(node_line_number) : Qnil;

    rb_funcall(cLiquidBlockBody, rb_intern("c_rescue_render_node"), 5,
        vm->context.self, render_args->output, line_number, exception, blank_tag);
    return true;
}

void liquid_vm_render(block_body_header_t *body, const VALUE *const_ptr, VALUE context, VALUE output)
{
    vm_t *vm = vm_from_context(context);

    vm_stack_reserve_for_write(vm, body->max_stack_size);
    resource_limits_increment_render_score(vm->context.resource_limits, body->render_score);

    vm_render_until_error_args_t render_args = {
        .vm = vm,
        .const_ptr = const_ptr,
        .ip = block_body_instructions_ptr(body),
        .output = output,
    };
    vm_render_rescue_args_t rescue_args = {
        .render_args = &render_args,
        .old_stack_byte_size = c_buffer_size(&vm->stack),
    };

    while (rb_rescue(vm_render_until_error, (VALUE)&render_args, vm_render_rescue, (VALUE)&rescue_args)) {
    }
    assert(rescue_args.old_stack_byte_size == c_buffer_size(&vm->stack));
}


void liquid_define_vm(void)
{
    id_render_node = rb_intern("render_node");
    id_vm = rb_intern("vm");

    cLiquidCVM = rb_define_class_under(mLiquidC, "VM", rb_cObject);
    rb_undef_alloc_func(cLiquidCVM);
    rb_global_variable(&cLiquidCVM);
}
