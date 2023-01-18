#include "liquid.h"
#include "context.h"
#include "variable_lookup.h"
#include "variable.h"
#include "vm.h"
#include "expression.h"
#include "document_body.h"

static VALUE cLiquidUndefinedVariable;
ID id_aset, id_set_context;
static ID id_has_key, id_aref, id_strainer, id_filter_methods_hash, id_strict_filters, id_global_filter;
static ID id_ivar_scopes, id_ivar_environments, id_ivar_static_environments, id_ivar_strict_variables, id_ivar_interrupts, id_ivar_resource_limits, id_ivar_document_body;

void context_internal_init(VALUE context_obj, context_t *context)
{
    context->self = context_obj;

    context->environments = rb_ivar_get(context_obj, id_ivar_environments);
    Check_Type(context->environments, T_ARRAY);

    context->static_environments = rb_ivar_get(context_obj, id_ivar_static_environments);
    Check_Type(context->static_environments, T_ARRAY);

    context->scopes = rb_ivar_get(context_obj, id_ivar_scopes);
    Check_Type(context->scopes, T_ARRAY);

    context->strainer = rb_funcall(context->self, id_strainer, 0);
    Check_Type(context->strainer, T_OBJECT);

    context->filter_methods = rb_funcall(RBASIC_CLASS(context->strainer), id_filter_methods_hash, 0);
    Check_Type(context->filter_methods, T_HASH);

    context->interrupts = rb_ivar_get(context->self, id_ivar_interrupts);
    Check_Type(context->interrupts, T_ARRAY);

    context->resource_limits_obj = rb_ivar_get(context->self, id_ivar_resource_limits);;
    ResourceLimits_Get_Struct(context->resource_limits_obj, context->resource_limits);

    context->strict_variables = false;
    context->strict_filters = RTEST(rb_funcall(context->self, id_strict_filters, 0));
    context->global_filter = rb_funcall(context->self, id_global_filter, 0);
}

void context_mark(context_t *context)
{
    rb_gc_mark(context->self);
    rb_gc_mark(context->environments);
    rb_gc_mark(context->static_environments);
    rb_gc_mark(context->scopes);
    rb_gc_mark(context->strainer);
    rb_gc_mark(context->filter_methods);
    rb_gc_mark(context->interrupts);
    rb_gc_mark(context->resource_limits_obj);
    rb_gc_mark(context->global_filter);
}

static context_t *context_from_obj(VALUE self)
{
    return &vm_from_context(self)->context;
}

static VALUE context_evaluate(VALUE self, VALUE expression)
{
    // Scalar type stored directly in the VALUE, this needs to be checked anyways to use RB_BUILTIN_TYPE
    if (RB_SPECIAL_CONST_P(expression))
        return expression;

    switch (RB_BUILTIN_TYPE(expression)) {
        case T_DATA:
        {
            if (RTYPEDDATA_P(expression) && RTYPEDDATA_TYPE(expression) == &expression_data_type) {
                if (RBASIC_CLASS(expression) == cLiquidCExpression) {
                    return internal_expression_evaluate(DATA_PTR(expression), self);
                } else {
                    assert(RBASIC_CLASS(expression) == cLiquidCVariableExpression);
                    return internal_variable_expression_evaluate(DATA_PTR(expression), self);
                }
            }
            break; // e.g. BigDecimal
        }
        case T_OBJECT: // may be Liquid::VariableLookup or Liquid::RangeLookup
        {
            VALUE result = rb_check_funcall(expression, id_evaluate, 1, &self);
            return RB_LIKELY(result != Qundef) ? result : expression;
        }
        default:
            break;
    }
    return expression;
}

void context_maybe_raise_undefined_variable(VALUE self, VALUE key)
{
    context_t *context = context_from_obj(self);
    if (context->strict_variables) {
        Check_Type(key, T_STRING);
        rb_enc_raise(utf8_encoding, cLiquidUndefinedVariable, "undefined variable %s", RSTRING_PTR(key));
    }
}

static bool environments_find_variable(VALUE environments, VALUE key, bool strict_variables, VALUE raise_on_not_found, VALUE *scope_out, VALUE *variable_out) {
    VALUE variable = Qnil;
    Check_Type(environments, T_ARRAY);

    for (long i = 0; i < RARRAY_LEN(environments); i++) {
        VALUE this_environ = RARRAY_AREF(environments, i);
        if (RB_LIKELY(TYPE(this_environ) == T_HASH)) {
            // Does not invoke any default value proc, this is equivalent in
            // cost and semantics to #key? but loads the value as well
            variable = rb_hash_lookup2(this_environ, key, Qundef);
            if (variable != Qundef) {
                *variable_out = variable;
                *scope_out = this_environ;
                return true;
            }

            if (!(RTEST(raise_on_not_found) && strict_variables)) {
                // If we aren't running strictly, we need to invoke the default
                // value proc, rb_hash_aref does this
                variable = rb_hash_aref(this_environ, key);
                if (variable != Qnil) {
                    *variable_out = variable;
                    *scope_out = this_environ;
                    return true;
                }
            }
        } else if (RTEST(rb_funcall(this_environ, id_has_key, 1, key))) {
            // Slow path: It is valid to pass a non-hash value to Liquid as an
            // environment if it supports #key? and #[]
            *variable_out = rb_funcall(this_environ, id_aref, 1, key);
            *scope_out = this_environ;
            return true;
        }
    }
    return false;
}

VALUE context_find_variable(context_t *context, VALUE key, VALUE raise_on_not_found)
{
    VALUE self = context->self;
    VALUE scope = Qnil, variable = Qnil;

    VALUE scopes = context->scopes;
    for (long i = 0; i < RARRAY_LEN(scopes); i++) {
        VALUE this_scope = RARRAY_AREF(scopes, i);
        if (RB_LIKELY(TYPE(this_scope) == T_HASH)) {
            // Does not invoke any default value proc, this is equivalent in
            // cost and semantics to #key? but loads the value as well
            variable = rb_hash_lookup2(this_scope, key, Qundef);
            if (variable != Qundef) {
                scope = this_scope;
                goto variable_found;
            }
        } else if (RTEST(rb_funcall(this_scope, id_has_key, 1, key))) {
            // Slow path: It is valid to pass a non-hash value to Liquid as a
            // scope if it supports #key? and #[]
            variable = rb_funcall(this_scope, id_aref, 1, key);
            goto variable_found;
        }
    }

    if (environments_find_variable(context->environments, key, context->strict_variables, raise_on_not_found,
                                   &scope, &variable))
        goto variable_found;

    if (environments_find_variable(context->static_environments, key, context->strict_variables, raise_on_not_found,
                                   &scope, &variable))
        goto variable_found;

    if (RTEST(raise_on_not_found)) {
        context_maybe_raise_undefined_variable(self, key);
    }
    variable = Qnil;

variable_found:
    variable = materialize_proc(self, scope, key, variable);
    variable = value_to_liquid_and_set_context(variable, self);

    return variable;
}

static VALUE context_find_variable_method(VALUE self, VALUE key, VALUE raise_on_not_found)
{
    return context_find_variable(context_from_obj(self), key, raise_on_not_found);
}

static VALUE context_set_strict_variables(VALUE self, VALUE strict_variables)
{
    context_t *context = context_from_obj(self);
    context->strict_variables = RTEST(strict_variables);
    rb_ivar_set(self, id_ivar_strict_variables, strict_variables);
    return Qnil;
}

// Shopify requires checking if we are filtering, so provide a
// way to do that in liquid-c until we figure out how we want to
// support that longer term.
VALUE context_filtering_p(VALUE self)
{
    return liquid_vm_filtering(self) ? Qtrue : Qfalse;
}

void liquid_define_context(void)
{
    id_has_key = rb_intern("key?");
    id_aset = rb_intern("[]=");
    id_aref = rb_intern("[]");
    id_set_context = rb_intern("context=");
    id_strainer = rb_intern("strainer");
    id_filter_methods_hash = rb_intern("filter_methods_hash");
    id_strict_filters = rb_intern("strict_filters");
    id_global_filter = rb_intern("global_filter");

    id_ivar_scopes = rb_intern("@scopes");
    id_ivar_environments = rb_intern("@environments");
    id_ivar_static_environments = rb_intern("@static_environments");
    id_ivar_strict_variables = rb_intern("@strict_variables");
    id_ivar_interrupts = rb_intern("@interrupts");
    id_ivar_resource_limits = rb_intern("@resource_limits");
    id_ivar_document_body = rb_intern("@document_body");

    cLiquidVariableLookup = rb_const_get(mLiquid, rb_intern("VariableLookup"));
    rb_global_variable(&cLiquidVariableLookup);

    cLiquidUndefinedVariable = rb_const_get(mLiquid, rb_intern("UndefinedVariable"));
    rb_global_variable(&cLiquidUndefinedVariable);

    VALUE cLiquidContext = rb_const_get(mLiquid, rb_intern("Context"));
    rb_define_method(cLiquidContext, "c_evaluate", context_evaluate, 1);
    rb_define_method(cLiquidContext, "c_find_variable", context_find_variable_method, 2);
    rb_define_method(cLiquidContext, "c_strict_variables=", context_set_strict_variables, 1);
    rb_define_private_method(cLiquidContext, "c_filtering?", context_filtering_p, 0);
}
