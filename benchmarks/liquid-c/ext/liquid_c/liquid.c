#include "liquid.h"
#include "tokenizer.h"
#include "variable.h"
#include "lexer.h"
#include "parser.h"
#include "raw.h"
#include "resource_limits.h"
#include "expression.h"
#include "document_body.h"
#include "block.h"
#include "context.h"
#include "parse_context.h"
#include "variable_lookup.h"
#include "vm_assembler_pool.h"
#include "vm.h"
#include "usage.h"

ID id_evaluate;
ID id_to_liquid;
ID id_to_s;
ID id_call;
ID id_compile_evaluate;
ID id_ivar_line_number;

VALUE mLiquid, mLiquidC, cLiquidVariable, cLiquidTemplate, cLiquidBlockBody;
VALUE cLiquidVariableLookup, cLiquidRangeLookup;
VALUE cLiquidArgumentError, cLiquidSyntaxError, cMemoryError;

rb_encoding *utf8_encoding;
int utf8_encoding_index;

__attribute__((noreturn)) void raise_non_utf8_encoding_error(VALUE string, const char *value_name)
{
    rb_raise(rb_eEncCompatError, "non-UTF8 encoded %s (%"PRIsVALUE") not supported", value_name, rb_obj_encoding(string));
}

RUBY_FUNC_EXPORTED void Init_liquid_c(void)
{
    id_evaluate = rb_intern("evaluate");
    id_to_liquid = rb_intern("to_liquid");
    id_to_s = rb_intern("to_s");
    id_call = rb_intern("call");
    id_compile_evaluate = rb_intern("compile_evaluate");
    id_ivar_line_number = rb_intern("@line_number");

    utf8_encoding = rb_utf8_encoding();
    utf8_encoding_index = rb_enc_to_index(utf8_encoding);

    mLiquid = rb_define_module("Liquid");
    rb_global_variable(&mLiquid);

    mLiquidC = rb_define_module_under(mLiquid, "C");
    rb_global_variable(&mLiquidC);

    cLiquidArgumentError = rb_const_get(mLiquid, rb_intern("ArgumentError"));
    rb_global_variable(&cLiquidArgumentError);

    cLiquidSyntaxError = rb_const_get(mLiquid, rb_intern("SyntaxError"));
    rb_global_variable(&cLiquidSyntaxError);

    cMemoryError = rb_const_get(mLiquid, rb_intern("MemoryError"));
    rb_global_variable(&cMemoryError);

    cLiquidVariable = rb_const_get(mLiquid, rb_intern("Variable"));
    rb_global_variable(&cLiquidVariable);

    cLiquidTemplate = rb_const_get(mLiquid, rb_intern("Template"));
    rb_global_variable(&cLiquidTemplate);

    cLiquidBlockBody = rb_const_get(mLiquid, rb_intern("BlockBody"));
    rb_global_variable(&cLiquidBlockBody);

    cLiquidVariableLookup = rb_const_get(mLiquid, rb_intern("VariableLookup"));
    rb_global_variable(&cLiquidVariableLookup);

    cLiquidRangeLookup = rb_const_get(mLiquid, rb_intern("RangeLookup"));
    rb_global_variable(&cLiquidRangeLookup);

    liquid_define_tokenizer();
    liquid_define_parser();
    liquid_define_raw();
    liquid_define_resource_limits();
    liquid_define_expression();
    liquid_define_variable();
    liquid_define_document_body();
    liquid_define_block_body();
    liquid_define_context();
    liquid_define_parse_context();
    liquid_define_variable_lookup();
    liquid_define_vm_assembler_pool();
    liquid_define_vm_assembler();
    liquid_define_vm();
    liquid_define_usage();
}

