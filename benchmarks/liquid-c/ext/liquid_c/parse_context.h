#ifndef LIQUID_PARSE_CONTEXT_H
#define LIQUID_PARSE_CONTEXT_H

#include <ruby.h>
#include <stdbool.h>
#include "vm_assembler_pool.h"

void liquid_define_parse_context(void);
VALUE parse_context_get_document_body(VALUE self);

vm_assembler_pool_t *parse_context_get_vm_assembler_pool(VALUE self);

#endif
