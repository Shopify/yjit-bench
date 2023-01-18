#include "liquid.h"
#include "vm_assembler.h"
#include "parser.h"
#include "vm.h"
#include "expression.h"

VALUE cLiquidCExpression;

static void expression_mark(void *ptr)
{
    expression_t *expression = ptr;
    vm_assembler_gc_mark(&expression->code);
}

static void expression_free(void *ptr)
{
    expression_t *expression = ptr;
    vm_assembler_free(&expression->code);
    xfree(expression);
}

static size_t expression_memsize(const void *ptr)
{
    const expression_t *expression = ptr;
    return sizeof(expression_t) + vm_assembler_alloc_memsize(&expression->code);
}

const rb_data_type_t expression_data_type = {
    "liquid_expression",
    { expression_mark, expression_free, expression_memsize, },
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE expression_new(VALUE klass, expression_t **expression_ptr)
{
    expression_t *expression;
    VALUE obj = TypedData_Make_Struct(klass, expression_t, &expression_data_type, expression);
    *expression_ptr = expression;
    vm_assembler_init(&expression->code);
    return obj;
}

static VALUE internal_expression_parse(parser_t *p)
{
    if (p->cur.type == TOKEN_EOS)
        return Qnil;

    // Avoid allocating an expression object just to wrap a constant
    VALUE const_obj = try_parse_constant_expression(p);
    if (const_obj != Qundef)
        return const_obj;

    expression_t *expression;
    VALUE expr_obj = expression_new(cLiquidCExpression, &expression);

    parse_and_compile_expression(p, &expression->code);
    assert(expression->code.stack_size == 1);
    vm_assembler_add_leave(&expression->code);

    return expr_obj;
}

static VALUE expression_strict_parse(VALUE klass, VALUE markup)
{
    if (NIL_P(markup))
        return Qnil;

    StringValue(markup);
    char *start = RSTRING_PTR(markup);

    parser_t p;
    init_parser(&p, start, start + RSTRING_LEN(markup));
    VALUE expr_obj = internal_expression_parse(&p);

    if (p.cur.type != TOKEN_EOS)
        rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "[:%s] is not a valid expression", symbol_names[p.cur.type]);

    return expr_obj;
}

VALUE expression_evaluate(VALUE self, VALUE context)
{
    expression_t *expression;
    Expression_Get_Struct(self, expression);
    return liquid_vm_evaluate(context, &expression->code);
}

VALUE internal_expression_evaluate(expression_t *expression, VALUE context)
{
    return liquid_vm_evaluate(context, &expression->code);
}

static VALUE expression_disassemble(VALUE self)
{
    expression_t *expression;
    Expression_Get_Struct(self, expression);

    VALUE constants = rb_ary_new();
    uint32_t constants_len = (uint32_t)(c_buffer_size(&expression->code.constants) / sizeof(VALUE));
    rb_ary_cat(constants, (VALUE *)expression->code.constants.data, constants_len);

    return vm_assembler_disassemble(
        expression->code.instructions.data,
        expression->code.instructions.data_end,
        &constants
    );
}

void liquid_define_expression(void)
{
    cLiquidCExpression = rb_define_class_under(mLiquidC, "Expression", rb_cObject);
    rb_undef_alloc_func(cLiquidCExpression);
    rb_define_singleton_method(cLiquidCExpression, "strict_parse", expression_strict_parse, 1);
    rb_define_method(cLiquidCExpression, "evaluate", expression_evaluate, 1);
    rb_define_method(cLiquidCExpression, "disassemble", expression_disassemble, 0);
}
