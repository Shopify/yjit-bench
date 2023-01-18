#ifndef LIQUID_DOCUMENT_BODY_H
#define LIQUID_DOCUMENT_BODY_H

#include "c_buffer.h"
#include "vm_assembler.h"

typedef struct block_body_header {
    uint32_t instructions_offset;
    uint32_t instructions_bytes;
    uint32_t constants_offset;
    uint32_t constants_len;
    uint32_t flags;
    uint32_t render_score;
    uint64_t max_stack_size;
} block_body_header_t;

#define BLOCK_BODY_HEADER_FLAG_BLANK (1 << 0)
#define BLOCK_BODY_HEADER_BLANK_P(header) (header->flags & BLOCK_BODY_HEADER_FLAG_BLANK)

typedef struct document_body {
    VALUE self;
    VALUE constants;
    c_buffer_t buffer;
} document_body_t;

typedef struct document_body_entry {
    document_body_t *body;
    size_t buffer_offset;
} document_body_entry_t;

void liquid_define_document_body(void);
VALUE document_body_new_instance(void);
document_body_entry_t document_body_write_block_body(VALUE self, bool blank, uint32_t render_score, vm_assembler_t *code);

static inline void document_body_entry_mark(document_body_entry_t *entry)
{
    rb_gc_mark(entry->body->self);
    rb_gc_mark(entry->body->constants);
}

static inline block_body_header_t *document_body_get_block_body_header_ptr(const document_body_entry_t *entry)
{
    return (block_body_header_t *)(entry->body->buffer.data + entry->buffer_offset);
}

static inline const VALUE *document_body_get_constants_ptr(const document_body_entry_t *entry)
{
    block_body_header_t *header = document_body_get_block_body_header_ptr(entry);
    return RARRAY_PTR(entry->body->constants) + header->constants_offset;
}

static inline void document_body_ensure_compile_finished(document_body_t *body)
{
    if (RB_UNLIKELY(!RB_OBJ_FROZEN(body->self))) {
        rb_raise(rb_eRuntimeError, "Liquid document hasn't finished compilation");
    }
}

#endif
