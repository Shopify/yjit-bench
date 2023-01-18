#include "liquid.h"
#include "resource_limits.h"

VALUE cLiquidResourceLimits;

static void resource_limits_free(void *ptr)
{
    resource_limits_t *resource_limits = ptr;
    xfree(resource_limits);
}

static size_t resource_limits_memsize(const void *ptr)
{
    return sizeof(resource_limits_t);
}

const rb_data_type_t resource_limits_data_type = {
    "liquid_resource_limits",
    { NULL, resource_limits_free, resource_limits_memsize },
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

static void resource_limits_reset(resource_limits_t *resource_limit)
{
    resource_limit->reached_limit = true;
    resource_limit->last_capture_length = -1;
    resource_limit->render_score = 0;
    resource_limit->assign_score = 0;
}

static VALUE resource_limits_allocate(VALUE klass)
{
    resource_limits_t *resource_limits;

    VALUE obj = TypedData_Make_Struct(klass, resource_limits_t, &resource_limits_data_type, resource_limits);

    resource_limits_reset(resource_limits);

    return obj;
}

static VALUE resource_limits_render_length_limit_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    return LONG2NUM(resource_limits->render_length_limit);
}

static VALUE resource_limits_set_render_length_limit_method(VALUE self, VALUE render_length_limit)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

     if (render_length_limit == Qnil) {
        resource_limits->render_length_limit = LONG_MAX;
    } else {
        resource_limits->render_length_limit = NUM2LONG(render_length_limit);
    }

    return Qnil;
}

static VALUE resource_limits_render_score_limit_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    return LONG2NUM(resource_limits->render_score_limit);
}

static VALUE resource_limits_set_render_score_limit_method(VALUE self, VALUE render_score_limit)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    if (render_score_limit == Qnil) {
        resource_limits->render_score_limit = LONG_MAX;
    } else {
        resource_limits->render_score_limit = NUM2LONG(render_score_limit);
    }

    return Qnil;
}

static VALUE resource_limits_assign_score_limit_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    return LONG2NUM(resource_limits->assign_score_limit);
}

static VALUE resource_limits_set_assign_score_limit_method(VALUE self, VALUE assign_score_limit)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    if (assign_score_limit == Qnil) {
        resource_limits->assign_score_limit = LONG_MAX;
    } else {
        resource_limits->assign_score_limit = NUM2LONG(assign_score_limit);
    }

    return Qnil;
}

static VALUE resource_limits_render_score_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    return LONG2NUM(resource_limits->render_score);
}

static VALUE resource_limits_assign_score_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    return LONG2NUM(resource_limits->assign_score);
}

static VALUE resource_limits_initialize_method(VALUE self, VALUE render_length_limit,
                                               VALUE render_score_limit, VALUE assign_score_limit)
{
    resource_limits_set_render_length_limit_method(self, render_length_limit);
    resource_limits_set_render_score_limit_method(self, render_score_limit);
    resource_limits_set_assign_score_limit_method(self, assign_score_limit);

    return Qnil;
}

__attribute__((noreturn))
void resource_limits_raise_limits_reached(resource_limits_t *resource_limit)
{
    resource_limit->reached_limit = true;
    rb_raise(cMemoryError, "Memory limits exceeded");
}

void resource_limits_increment_render_score(resource_limits_t *resource_limits, long amount)
{
    resource_limits->render_score = resource_limits->render_score + amount;

    if (resource_limits->render_score > resource_limits->render_score_limit) {
        resource_limits_raise_limits_reached(resource_limits);
    }
}

static VALUE resource_limits_increment_render_score_method(VALUE self, VALUE amount)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    resource_limits_increment_render_score(resource_limits, NUM2LONG(amount));

    return Qnil;
}

static void resource_limits_increment_assign_score(resource_limits_t *resource_limits, long amount)
{
    resource_limits->assign_score = resource_limits->assign_score + amount;

    if (resource_limits->assign_score > resource_limits->assign_score_limit) {
        resource_limits_raise_limits_reached(resource_limits);
    }
}

static VALUE resource_limits_increment_assign_score_method(VALUE self, VALUE amount)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    resource_limits_increment_assign_score(resource_limits, NUM2LONG(amount));

    return Qnil;
}

void resource_limits_increment_write_score(resource_limits_t *resource_limits, VALUE output)
{
    long captured = RSTRING_LEN(output);

    if (resource_limits->last_capture_length >= 0) {
        long increment = captured - resource_limits->last_capture_length;
        resource_limits->last_capture_length = captured;
        resource_limits_increment_assign_score(resource_limits, increment);
    } else if (captured > resource_limits->render_length_limit) {
        resource_limits_raise_limits_reached(resource_limits);
    }
}

static VALUE resource_limits_increment_write_score_method(VALUE self, VALUE output)
{
    Check_Type(output, T_STRING);

    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    resource_limits_increment_write_score(resource_limits, output);

    return Qnil;
}

static VALUE resource_limits_raise_limits_reached_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    resource_limits_raise_limits_reached(resource_limits);
}

static VALUE resource_limits_reached_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    return resource_limits->reached_limit ? Qtrue : Qfalse;
}

struct capture_ensure_t {
    resource_limits_t *resource_limits;
    long old_capture_length;
};

static VALUE capture_ensure(VALUE data)
{
    struct capture_ensure_t *ensure_data = (struct capture_ensure_t *)data;
    ensure_data->resource_limits->last_capture_length = ensure_data->old_capture_length;

    return Qnil;
}

static VALUE resource_limits_with_capture_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);

    struct capture_ensure_t ensure_data = {
        .resource_limits = resource_limits,
        .old_capture_length = resource_limits->last_capture_length
    };

    resource_limits->last_capture_length = 0;

    return rb_ensure(rb_yield, Qundef, capture_ensure, (VALUE)&ensure_data);
}


static VALUE resource_limits_reset_method(VALUE self)
{
    resource_limits_t *resource_limits;
    ResourceLimits_Get_Struct(self, resource_limits);
    resource_limits_reset(resource_limits);
    return Qnil;
}

void liquid_define_resource_limits(void)
{
    cLiquidResourceLimits = rb_define_class_under(mLiquidC, "ResourceLimits", rb_cObject);
    rb_global_variable(&cLiquidResourceLimits);

    rb_define_alloc_func(cLiquidResourceLimits, resource_limits_allocate);
    rb_define_method(cLiquidResourceLimits, "initialize", resource_limits_initialize_method, 3);
    rb_define_method(cLiquidResourceLimits, "render_length_limit", resource_limits_render_length_limit_method, 0);
    rb_define_method(cLiquidResourceLimits, "render_length_limit=", resource_limits_set_render_length_limit_method, 1);
    rb_define_method(cLiquidResourceLimits, "render_score_limit", resource_limits_render_score_limit_method, 0);
    rb_define_method(cLiquidResourceLimits, "render_score_limit=", resource_limits_set_render_score_limit_method, 1);
    rb_define_method(cLiquidResourceLimits, "assign_score_limit", resource_limits_assign_score_limit_method, 0);
    rb_define_method(cLiquidResourceLimits, "assign_score_limit=", resource_limits_set_assign_score_limit_method, 1);
    rb_define_method(cLiquidResourceLimits, "render_score", resource_limits_render_score_method, 0);
    rb_define_method(cLiquidResourceLimits, "assign_score", resource_limits_assign_score_method, 0);
    rb_define_method(cLiquidResourceLimits, "increment_render_score", resource_limits_increment_render_score_method, 1);
    rb_define_method(cLiquidResourceLimits, "increment_assign_score", resource_limits_increment_assign_score_method, 1);
    rb_define_method(cLiquidResourceLimits, "increment_write_score", resource_limits_increment_write_score_method, 1);
    rb_define_method(cLiquidResourceLimits, "raise_limits_reached", resource_limits_raise_limits_reached_method, 0);
    rb_define_method(cLiquidResourceLimits, "reached?", resource_limits_reached_method, 0);
    rb_define_method(cLiquidResourceLimits, "reset", resource_limits_reset_method, 0);
    rb_define_method(cLiquidResourceLimits, "with_capture", resource_limits_with_capture_method, 0);
}
