#ifndef LIQUID_C_BUFFER_H
#define LIQUID_C_BUFFER_H

#include <ruby.h>

typedef struct c_buffer {
    uint8_t *data;
    uint8_t *data_end;
    uint8_t *capacity_end;
} c_buffer_t;

static inline c_buffer_t c_buffer_init(void)
{
    return (c_buffer_t) { NULL, NULL, NULL };
}

static inline c_buffer_t c_buffer_allocate(size_t capacity)
{
    uint8_t *data = xmalloc(capacity);
    return (c_buffer_t) { data, data, data + capacity };
}

static inline void c_buffer_free(c_buffer_t *buffer)
{
    xfree(buffer->data);
}

static inline void c_buffer_reset(c_buffer_t *buffer)
{
    buffer->data_end = buffer->data;
}

static inline size_t c_buffer_size(const c_buffer_t *buffer)
{
    return buffer->data_end - buffer->data;
}

static inline size_t c_buffer_capacity(const c_buffer_t *buffer)
{
    return buffer->capacity_end - buffer->data;
}

void c_buffer_zero_pad_for_alignment(c_buffer_t *buffer, size_t alignment);

void c_buffer_reserve_for_write(c_buffer_t *buffer, size_t write_size);
void c_buffer_write(c_buffer_t *buffer, void *data, size_t size);

static inline void *c_buffer_extend_for_write(c_buffer_t *buffer, size_t write_size) {
    c_buffer_reserve_for_write(buffer, write_size);
    void *write_ptr = buffer->data_end;
    buffer->data_end += write_size;
    return write_ptr;
}

static inline void c_buffer_write_byte(c_buffer_t *buffer, uint8_t byte) {
    c_buffer_write(buffer, &byte, 1);
}

static inline void c_buffer_write_ruby_value(c_buffer_t *buffer, VALUE value) {
    c_buffer_write(buffer, &value, sizeof(VALUE));
}

static inline void c_buffer_rb_gc_mark(c_buffer_t *buffer)
{
    VALUE *buffer_end = (VALUE *)buffer->data_end;
    for (VALUE *obj_ptr = (VALUE *)buffer->data; obj_ptr < buffer_end; obj_ptr++) {
        rb_gc_mark(*obj_ptr);
    }
}

static inline void c_buffer_concat(c_buffer_t *dest, c_buffer_t *src)
{
    c_buffer_write(dest, src->data, c_buffer_size(src));
}

#endif
