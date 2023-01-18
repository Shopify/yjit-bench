#if !defined(LIQUID_CONTEXT_H)
#define LIQUID_CONTEXT_H

#include "resource_limits.h"

typedef struct context {
    VALUE self;
    VALUE environments;
    VALUE static_environments;
    VALUE scopes;
    VALUE strainer;
    VALUE filter_methods;
    VALUE interrupts;
    VALUE resource_limits_obj;
    resource_limits_t *resource_limits;
    VALUE global_filter;
    bool strict_variables;
    bool strict_filters;
} context_t;

void liquid_define_context(void);
void context_internal_init(VALUE context_obj, context_t *context);
void context_mark(context_t *context);
VALUE context_find_variable(context_t *context, VALUE key, VALUE raise_on_not_found);
void context_maybe_raise_undefined_variable(VALUE self, VALUE key);

extern ID id_aset, id_set_context;

#ifndef RB_SPECIAL_CONST_P
// RB_SPECIAL_CONST_P added in Ruby 2.3
#define RB_SPECIAL_CONST_P SPECIAL_CONST_P
#endif

inline static VALUE value_to_liquid_and_set_context(VALUE value, VALUE context_to_set)
{
    // Scalar type stored directly in the VALUE, these all have a #to_liquid
    // that returns self, and should have no #context= method
    if (RB_SPECIAL_CONST_P(value))
        return value;

    VALUE klass = RBASIC(value)->klass;

    // More basic types having #to_liquid of self and no #context=
    if (klass == rb_cString || klass == rb_cArray || klass == rb_cHash)
        return value;

    value = rb_funcall(value, id_to_liquid, 0);

    if (rb_respond_to(value, id_set_context))
        rb_funcall(value, id_set_context, 1, context_to_set);

    return value;
}


inline static VALUE materialize_proc(VALUE context, VALUE scope, VALUE key, VALUE value)
{
    if (scope != Qnil && rb_obj_is_proc(value) && rb_respond_to(scope, id_aset)) {
        if (rb_proc_arity(value) == 1) {
            value = rb_funcall(value, id_call, 1, context);
        } else {
            value = rb_funcall(value, id_call, 0);
        }
        rb_funcall(scope, id_aset, 2, key, value);
    }
    return value;
}

#endif

