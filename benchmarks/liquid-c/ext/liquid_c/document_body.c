#include <ruby.h>
#include <stdalign.h>
#include "liquid.h"
#include "vm_assembler.h"
#include "document_body.h"

static VALUE cLiquidCDocumentBody;

static void document_body_mark(void *ptr)
{
    document_body_t *body = ptr;
    /* When Liquid::C::BlockBody#freeze is called, it calls
     * document_body_write_block_body which sets the document_body_entry but
     * does not yet set the compiled flag to true. During this time, the only
     * reference to this Liquid::C::DocumentBody object is in the instance
     * variables of the parse_context which is marked movable by Ruby. This
     * causes the self reference here to be moved by compaction causing it to
     * point to an incorrect object. */
    rb_gc_mark(body->self);
    rb_gc_mark(body->constants);
}

static void document_body_free(void *ptr)
{
    document_body_t *body = ptr;
    c_buffer_free(&body->buffer);
    xfree(body);
}

static size_t document_body_memsize(const void *ptr)
{
    const document_body_t *body = ptr;
    return sizeof(document_body_t) + c_buffer_size(&body->buffer);
}

const rb_data_type_t document_body_data_type = {
    "liquid_document_body",
    { document_body_mark, document_body_free, document_body_memsize },
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE document_body_allocate(VALUE klass)
{
    document_body_t *body;

    VALUE obj = TypedData_Make_Struct(klass, document_body_t, &document_body_data_type, body);
    body->self = obj;
    body->constants = rb_ary_new();
    body->buffer = c_buffer_init();

    return obj;
}

#define DocumentBody_Get_Struct(obj, sval) TypedData_Get_Struct(obj, document_body_t, &document_body_data_type, sval)

VALUE document_body_new_instance(void)
{
    return rb_class_new_instance(0, NULL, cLiquidCDocumentBody);
}

document_body_entry_t document_body_write_block_body(VALUE self, bool blank, uint32_t render_score, vm_assembler_t *code)
{
    assert(!RB_OBJ_FROZEN(self));

    document_body_t *body;
    DocumentBody_Get_Struct(self, body);

    c_buffer_zero_pad_for_alignment(&body->buffer, alignof(block_body_header_t));

    size_t buffer_offset = c_buffer_size(&body->buffer);

    assert(c_buffer_size(&code->constants) % sizeof(VALUE) == 0);
    uint32_t constants_len = (uint32_t)(c_buffer_size(&code->constants) / sizeof(VALUE));

    block_body_header_t *buf_block_body = c_buffer_extend_for_write(&body->buffer, sizeof(block_body_header_t));
    buf_block_body->instructions_offset = (uint32_t)sizeof(block_body_header_t);
    buf_block_body->instructions_bytes = (uint32_t)c_buffer_size(&code->instructions);
    buf_block_body->constants_offset = (uint32_t)RARRAY_LEN(body->constants);
    buf_block_body->constants_len = constants_len;
    buf_block_body->flags = 0;
    if (blank) buf_block_body->flags |= BLOCK_BODY_HEADER_FLAG_BLANK;
    buf_block_body->render_score = render_score;
    buf_block_body->max_stack_size = code->max_stack_size;

    c_buffer_concat(&body->buffer, &code->instructions);

    rb_ary_cat(body->constants, (VALUE *)code->constants.data, constants_len);

    return (document_body_entry_t) { .body = body, .buffer_offset = buffer_offset };
}

void liquid_define_document_body(void)
{
    cLiquidCDocumentBody = rb_define_class_under(mLiquidC, "DocumentBody", rb_cObject);
    rb_global_variable(&cLiquidCDocumentBody);
    rb_define_alloc_func(cLiquidCDocumentBody, document_body_allocate);
}
