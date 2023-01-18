#if !defined(LIQUID_EXPRESSION_H)
#define LIQUID_EXPRESSION_H

#include "vm_assembler.h"
#include "parser.h"

extern VALUE cLiquidCExpression;
extern const rb_data_type_t expression_data_type;

typedef struct expression {
    vm_assembler_t code;
} expression_t;

extern const rb_data_type_t expression_data_type;
#define Expression_Get_Struct(obj, sval) TypedData_Get_Struct(obj, expression_t, &expression_data_type, sval)

void liquid_define_expression(void);

VALUE expression_new(VALUE klass, expression_t **expression_ptr);
VALUE expression_evaluate(VALUE self, VALUE context);
VALUE internal_expression_evaluate(expression_t *expression, VALUE context);

#endif

