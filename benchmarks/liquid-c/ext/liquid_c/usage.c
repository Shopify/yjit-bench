#include "usage.h"

static VALUE cLiquidUsage;
static ID id_increment;

void usage_increment(const char *name)
{
    VALUE name_str = rb_str_new_cstr(name);
    rb_funcall(cLiquidUsage, id_increment, 1, name_str);
}

void liquid_define_usage(void)
{
    cLiquidUsage = rb_const_get(mLiquid, rb_intern("Usage"));
    rb_global_variable(&cLiquidUsage);

    id_increment = rb_intern("increment");
}
