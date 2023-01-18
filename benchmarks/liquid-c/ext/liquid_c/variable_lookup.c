#include "liquid.h"
#include "context.h"

static ID id_has_key, id_aref, id_fetch, id_to_liquid_value;

VALUE variable_lookup_key(VALUE context, VALUE object, VALUE key, bool is_command)
{
    if (rb_obj_class(key) != rb_cString) {
        VALUE key_value = rb_check_funcall(key, id_to_liquid_value, 0, 0);

        if (key_value != Qundef) {
            key = key_value;
        }
    }

    if (rb_respond_to(object, id_aref) && (
        (rb_respond_to(object, id_has_key) && rb_funcall(object, id_has_key, 1, key)) ||
        (rb_obj_is_kind_of(key, rb_cInteger) && rb_respond_to(object, id_fetch))
    )) {
        VALUE next_object = rb_funcall(object, id_aref, 1, key);
        next_object = materialize_proc(context, object, key, next_object);
        return value_to_liquid_and_set_context(next_object, context);
    }

    if (is_command) {
        Check_Type(key, T_STRING);
        ID intern_key = rb_intern(RSTRING_PTR(key));
        if (rb_respond_to(object, intern_key)) {
            VALUE next_object = rb_funcall(object, intern_key, 0);
            return value_to_liquid_and_set_context(next_object, context);
        }
    }

    context_maybe_raise_undefined_variable(context, key);
    return Qnil;
}

void liquid_define_variable_lookup(void)
{
    id_has_key = rb_intern("key?");
    id_aref = rb_intern("[]");
    id_fetch = rb_intern("fetch");
    id_to_liquid_value = rb_intern("to_liquid_value");
}
