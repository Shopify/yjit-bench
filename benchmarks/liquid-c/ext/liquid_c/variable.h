#if !defined(LIQUID_VARIABLE_H)
#define LIQUID_VARIABLE_H

#include "vm_assembler.h"
#include "block.h"
#include "expression.h"

extern VALUE cLiquidCVariableExpression;

typedef struct variable_parse_args {
    const char *markup;
    const char *markup_end;
    vm_assembler_t *code;
    VALUE code_obj;
    VALUE parse_context;
} variable_parse_args_t;

void liquid_define_variable(void);
void internal_variable_compile(variable_parse_args_t *parse_args, unsigned int line_number);
void internal_variable_compile_evaluate(variable_parse_args_t *parse_args);
VALUE internal_variable_expression_evaluate(expression_t *expression, VALUE context);

#endif

