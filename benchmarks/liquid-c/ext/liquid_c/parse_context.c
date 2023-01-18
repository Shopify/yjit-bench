#include "parse_context.h"
#include "document_body.h"

static ID id_document_body, id_vm_assembler_pool;

static bool parse_context_document_body_initialized_p(VALUE self)
{
    return RTEST(rb_attr_get(self, id_document_body));
}

static void parse_context_init_document_body(VALUE self)
{
    VALUE document_body = document_body_new_instance();
    rb_ivar_set(self, id_document_body, document_body);
}

VALUE parse_context_get_document_body(VALUE self)
{
    assert(parse_context_document_body_initialized_p(self));

    return rb_ivar_get(self, id_document_body);
}

vm_assembler_pool_t *parse_context_init_vm_assembler_pool(VALUE self)
{
    assert(!RTEST(rb_attr_get(self, id_vm_assembler_pool)));

    VALUE vm_assembler_pool_obj = vm_assembler_pool_new();
    rb_ivar_set(self, id_vm_assembler_pool, vm_assembler_pool_obj);

    vm_assembler_pool_t *vm_assembler_pool;
    VMAssemblerPool_Get_Struct(vm_assembler_pool_obj, vm_assembler_pool);

    return vm_assembler_pool;
}

vm_assembler_pool_t *parse_context_get_vm_assembler_pool(VALUE self)
{
    VALUE obj = rb_ivar_get(self, id_vm_assembler_pool);

    if (obj == Qnil) {
        rb_raise(rb_eRuntimeError, "Liquid::ParseContext#start_liquid_c_parsing has not yet been called");
    }

    vm_assembler_pool_t *vm_assembler_pool;
    VMAssemblerPool_Get_Struct(obj, vm_assembler_pool);
    return vm_assembler_pool;
}

static VALUE parse_context_start_liquid_c_parsing(VALUE self)
{
    if (RB_UNLIKELY(parse_context_document_body_initialized_p(self))) {
        rb_raise(rb_eRuntimeError, "liquid-c parsing already started for this parse context");
    }
    parse_context_init_document_body(self);
    parse_context_init_vm_assembler_pool(self);
    return Qnil;
}

static VALUE parse_context_cleanup_liquid_c_parsing(VALUE self)
{
    rb_obj_freeze(rb_ivar_get(self, id_document_body));
    rb_ivar_set(self, id_document_body, Qnil);
    rb_ivar_set(self, id_vm_assembler_pool, Qnil);
    return Qnil;
}

void liquid_define_parse_context(void)
{
    id_document_body = rb_intern("document_body");
    id_vm_assembler_pool = rb_intern("vm_assembler_pool");

    VALUE cLiquidParseContext = rb_const_get(mLiquid, rb_intern("ParseContext"));
    rb_define_method(cLiquidParseContext, "start_liquid_c_parsing", parse_context_start_liquid_c_parsing, 0);
    rb_define_method(cLiquidParseContext, "cleanup_liquid_c_parsing", parse_context_cleanup_liquid_c_parsing, 0);
}
