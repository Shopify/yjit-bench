#ifndef VM_ASSEMBLER_H
#define VM_ASSEMBLER_H

#include <assert.h>
#include "liquid.h"
#include "c_buffer.h"
#include "intutil.h"

enum opcode {
    OP_LEAVE = 0,
    OP_WRITE_RAW_W = 1,
    OP_WRITE_NODE = 2,
    OP_POP_WRITE,
    OP_WRITE_RAW_SKIP,
    OP_PUSH_CONST,
    OP_PUSH_NIL,
    OP_PUSH_TRUE,
    OP_PUSH_FALSE,
    OP_PUSH_INT8,
    OP_PUSH_INT16,
    OP_FIND_STATIC_VAR,
    OP_FIND_VAR,
    OP_LOOKUP_CONST_KEY,
    OP_LOOKUP_KEY,
    OP_LOOKUP_COMMAND,
    OP_NEW_INT_RANGE,
    OP_HASH_NEW, // rb_hash_new & rb_hash_bulk_insert
    OP_FILTER,
    OP_BUILTIN_FILTER,
    OP_RENDER_VARIABLE_RESCUE, // setup state to rescue variable rendering
    OP_WRITE_RAW,
    OP_JUMP_FWD_W,
    OP_JUMP_FWD,
};

typedef struct {
    const char *name;
    VALUE sym;
} filter_desc_t;

extern filter_desc_t builtin_filters[];

typedef struct vm_assembler {
    c_buffer_t instructions;
    c_buffer_t constants;
    st_table *constants_table;
    size_t max_stack_size;
    size_t stack_size;
    size_t protected_stack_size;
    bool parsing; // prevent executing when incomplete or extending when complete
} vm_assembler_t;

void liquid_define_vm_assembler(void);
void vm_assembler_init(vm_assembler_t *code);
void vm_assembler_reset(vm_assembler_t *code);
void vm_assembler_free(vm_assembler_t *code);
void vm_assembler_gc_mark(vm_assembler_t *code);
VALUE vm_assembler_disassemble(const uint8_t *start_ip, const uint8_t *end_ip, const VALUE *constants);
void vm_assembler_concat(vm_assembler_t *dest, vm_assembler_t *src);
void vm_assembler_require_stack_args(vm_assembler_t *code, unsigned int count);

void vm_assembler_add_write_raw(vm_assembler_t *code, const char *string, size_t size);
void vm_assembler_add_write_node(vm_assembler_t *code, VALUE node);
void vm_assembler_add_push_fixnum(vm_assembler_t *code, VALUE num);
void vm_assembler_add_push_literal(vm_assembler_t *code, VALUE literal);
void vm_assembler_add_filter(vm_assembler_t *code, VALUE filter_name, size_t arg_count);

void vm_assembler_add_evaluate_expression_from_ruby(vm_assembler_t *code, VALUE code_obj, VALUE expression);
void vm_assembler_add_find_variable_from_ruby(vm_assembler_t *code, VALUE code_obj, VALUE expression);
void vm_assembler_add_lookup_command_from_ruby(vm_assembler_t *code, VALUE command);
void vm_assembler_add_lookup_key_from_ruby(vm_assembler_t *code, VALUE code_obj, VALUE expression);
void vm_assembler_add_new_int_range_from_ruby(vm_assembler_t *code);
void vm_assembler_add_hash_new_from_ruby(vm_assembler_t *code, VALUE hash_size_obj);
void vm_assembler_add_filter_from_ruby(vm_assembler_t *code, VALUE filter_name, VALUE arg_count_obj);

bool vm_assembler_opcode_has_constant(uint8_t ip);

static inline size_t vm_assembler_alloc_memsize(const vm_assembler_t *code)
{
    return c_buffer_capacity(&code->instructions) + c_buffer_capacity(&code->constants) + sizeof(st_table);
}

static inline void vm_assembler_write_opcode(vm_assembler_t *code, enum opcode op)
{
    c_buffer_write_byte(&code->instructions, op);
}

static inline uint16_t vm_assembler_write_ruby_constant(vm_assembler_t *code, VALUE constant)
{
    st_table *constants_table = code->constants_table;
    st_data_t index_value;

    if (st_lookup(constants_table, constant, &index_value)) {
        return (uint16_t)index_value;
    } else {
        uint16_t index = c_buffer_size(&code->constants) / sizeof(VALUE);
        st_insert(constants_table, constant, index);
        c_buffer_write(&code->constants, &constant, sizeof(VALUE));
        return index;
    }
}

static inline void vm_assembler_increment_stack_size(vm_assembler_t *code, size_t amount)
{
    code->stack_size += amount;
    if (code->stack_size > code->max_stack_size)
        code->max_stack_size = code->stack_size;
}

static inline void vm_assembler_reserve_stack_size(vm_assembler_t *code, size_t amount)
{
    vm_assembler_increment_stack_size(code, amount);
    code->stack_size -= amount;
}

static inline void vm_assembler_add_op_with_constant(vm_assembler_t *code, VALUE constant, uint8_t opcode)
{
    uint16_t index = vm_assembler_write_ruby_constant(code, constant);
    uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 3);
    instructions[0] = opcode;
    instructions[1] = index >> 8;
    instructions[2] = (uint8_t)index;
}

static inline void vm_assembler_add_leave(vm_assembler_t *code)
{
    vm_assembler_write_opcode(code, OP_LEAVE);
    code->parsing = false;
}

static inline void vm_assembler_remove_leave(vm_assembler_t *code)
{
    code->parsing = true;
    code->instructions.data_end--;
    assert(*code->instructions.data_end == OP_LEAVE);
}

static inline void vm_assembler_add_pop_write(vm_assembler_t *code)
{
    code->stack_size -= 1;
    vm_assembler_write_opcode(code, OP_POP_WRITE);
}

static inline void vm_assembler_add_hash_new(vm_assembler_t *code, size_t hash_size)
{
    if (hash_size > 255)
        rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "Hash literal has too many keys");
    code->stack_size -= hash_size * 2;
    code->stack_size++;
    uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 2);
    instructions[0] = OP_HASH_NEW;
    instructions[1] = hash_size;
}


static inline void vm_assembler_add_push_nil(vm_assembler_t *code)
{
    vm_assembler_increment_stack_size(code, 1);
    vm_assembler_write_opcode(code, OP_PUSH_NIL);
}

static inline void vm_assembler_add_push_true(vm_assembler_t *code)
{
    vm_assembler_increment_stack_size(code, 1);
    vm_assembler_write_opcode(code, OP_PUSH_TRUE);
}

static inline void vm_assembler_add_push_false(vm_assembler_t *code)
{
    vm_assembler_increment_stack_size(code, 1);
    vm_assembler_write_opcode(code, OP_PUSH_FALSE);
}

static inline void vm_assembler_add_push_int8(vm_assembler_t *code, int8_t value)
{
    vm_assembler_increment_stack_size(code, 1);
    uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 2);
    instructions[0] = OP_PUSH_INT8;
    instructions[1] = value;
}

static inline void vm_assembler_add_push_int16(vm_assembler_t *code, int16_t value)
{
    vm_assembler_increment_stack_size(code, 1);
    uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 3);
    instructions[0] = OP_PUSH_INT16;
    instructions[1] = value >> 8;
    instructions[2] = (uint8_t)value;
}

static inline void vm_assembler_add_push_const(vm_assembler_t *code, VALUE constant)
{
    vm_assembler_increment_stack_size(code, 1);
    vm_assembler_add_op_with_constant(code, constant, OP_PUSH_CONST);
}

static inline void vm_assembler_add_find_static_variable(vm_assembler_t *code, VALUE key)
{
    vm_assembler_increment_stack_size(code, 1);
    vm_assembler_add_op_with_constant(code, key, OP_FIND_STATIC_VAR);
}

static inline void vm_assembler_add_find_variable(vm_assembler_t *code)
{
    // pop 1, push 1
    vm_assembler_write_opcode(code, OP_FIND_VAR);
}

static inline void vm_assembler_add_lookup_const_key(vm_assembler_t *code, VALUE key)
{
    vm_assembler_reserve_stack_size(code, 1); // push 1, pop 2, push 1
    vm_assembler_add_op_with_constant(code, key, OP_LOOKUP_CONST_KEY);
}

static inline void vm_assembler_add_lookup_key(vm_assembler_t *code)
{
    code->stack_size--; // pop 2, push 1
    vm_assembler_write_opcode(code, OP_LOOKUP_KEY);
}

static inline void vm_assembler_add_lookup_command(vm_assembler_t *code, VALUE command)
{
    vm_assembler_reserve_stack_size(code, 1); // push 1, pop 2, push 1
    vm_assembler_add_op_with_constant(code, command, OP_LOOKUP_COMMAND);
}

static inline void vm_assembler_add_new_int_range(vm_assembler_t *code)
{
    code->stack_size--; // pop 2, push 1
    vm_assembler_write_opcode(code, OP_NEW_INT_RANGE);
}

static inline void vm_assembler_add_render_variable_rescue(vm_assembler_t *code, size_t node_line_number)
{
    uint8_t *instructions = c_buffer_extend_for_write(&code->instructions, 4);
    instructions[0] = OP_RENDER_VARIABLE_RESCUE;
    uint24_to_bytes((unsigned int)node_line_number, &instructions[1]);
}

#endif
