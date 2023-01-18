#include "liquid.h"
#include "parser.h"
#include "lexer.h"

static VALUE empty_string;
static ID id_to_i, idEvaluate;

void init_parser(parser_t *p, const char *str, const char *end)
{
    p->str_end = end;
    p->cur.type = p->next.type = TOKEN_EOS;
    p->str = lex_one(str, end, &p->cur);
    p->str = lex_one(p->str, end, &p->next);
}

lexer_token_t parser_consume_any(parser_t *p)
{
    lexer_token_t cur = p->cur;
    p->cur = p->next;
    p->next.type = TOKEN_EOS;
    p->str = lex_one(p->str, p->str_end, &p->next);
    return cur;
}

lexer_token_t parser_must_consume(parser_t *p, unsigned char type)
{
    if (p->cur.type != type) {
        rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "Expected %s but found %s",
                 symbol_names[type], symbol_names[p->cur.type]);
    }
    return parser_consume_any(p);
}

lexer_token_t parser_consume(parser_t *p, unsigned char type)
{
    if (p->cur.type != type) {
        lexer_token_t zero = {0};
        return zero;
    }
    return parser_consume_any(p);
}

inline static int rstring_eq(VALUE rstr, const char *str) {
    size_t str_len = strlen(str);

    return TYPE(rstr) == T_STRING &&
           str_len == (size_t)RSTRING_LEN(rstr) &&
           memcmp(RSTRING_PTR(rstr), str, str_len) == 0;
}

static VALUE parse_number(parser_t *p)
{
    VALUE out;
    lexer_token_t token = parser_must_consume(p, TOKEN_NUMBER);

    // Set up sentinel for rb_cstr operations.
    char tmp = *token.val_end;
    *(char *)token.val_end = '\0';

    if (token.flags & TOKEN_FLOAT_NUMBER) {
        out = DBL2NUM(rb_cstr_to_dbl(token.val, 1));
    } else {
        out = rb_cstr_to_inum(token.val, 10, 1);
    }

    *(char *)token.val_end = tmp;
    return out;
}

static void raise_invalid_expression_type(const char *expr, int expr_len)
{
    rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "Invalid expression type '%.*s' in range expression", expr_len, expr);
}

static VALUE try_parse_constant_range(parser_t *p)
{
    parser_t saved_state = *p;

    parser_must_consume(p, TOKEN_OPEN_ROUND);

    const char *begin_str = p->cur.val;
    VALUE begin = try_parse_constant_expression(p);
    const char *begin_str_end = p->cur.val;
    if (begin == Qundef) {
        *p = saved_state;
        return Qundef;
    }
    parser_must_consume(p, TOKEN_DOTDOT);

    const char *end_str = p->cur.val;
    VALUE end = try_parse_constant_expression(p);
    const char *end_str_end = p->cur.val;
    if (end == Qundef) {
        *p = saved_state;
        return Qundef;
    }
    parser_must_consume(p, TOKEN_CLOSE_ROUND);

    begin = rb_check_funcall(begin, id_to_i, 0, NULL);
    if (begin == Qundef) raise_invalid_expression_type(begin_str, begin_str_end - begin_str);

    end = rb_check_funcall(end, id_to_i, 0, NULL);
    if (end == Qundef) raise_invalid_expression_type(end_str, end_str_end - end_str);

    bool exclude_end = false;
    return rb_range_new(begin, end, exclude_end);
}

static void parse_and_compile_range(parser_t *p, vm_assembler_t *code)
{
    VALUE const_range = try_parse_constant_range(p);
    if (const_range != Qundef) {
        vm_assembler_add_push_const(code, const_range);
        return;
    }

    parser_must_consume(p, TOKEN_OPEN_ROUND);
    parse_and_compile_expression(p, code);
    parser_must_consume(p, TOKEN_DOTDOT);
    parse_and_compile_expression(p, code);
    parser_must_consume(p, TOKEN_CLOSE_ROUND);
    vm_assembler_add_new_int_range(code);
}

static void parse_and_compile_variable_lookup(parser_t *p, vm_assembler_t *code)
{
    if (parser_consume(p, TOKEN_OPEN_SQUARE).type) {
        parse_and_compile_expression(p, code);
        parser_must_consume(p, TOKEN_CLOSE_SQUARE);
        vm_assembler_add_find_variable(code);
    } else {
        VALUE name = token_to_rstr_leveraging_existing_symbol(parser_must_consume(p, TOKEN_IDENTIFIER));
        vm_assembler_add_find_static_variable(code, name);
    }

    while (true) {
        if (p->cur.type == TOKEN_OPEN_SQUARE) {
            parser_consume_any(p);
            parse_and_compile_expression(p, code);
            parser_must_consume(p, TOKEN_CLOSE_SQUARE);
            vm_assembler_add_lookup_key(code);
        } else if (p->cur.type == TOKEN_DOT) {
            parser_consume_any(p);
            VALUE key = token_to_rstr_leveraging_existing_symbol(parser_must_consume(p, TOKEN_IDENTIFIER));

            if (rstring_eq(key, "size") || rstring_eq(key, "first") || rstring_eq(key, "last"))
                vm_assembler_add_lookup_command(code, key);
            else
                vm_assembler_add_lookup_const_key(code, key);
        } else {
            break;
        }
    }
}

static VALUE try_parse_literal(parser_t *p)
{
    if (p->next.type == TOKEN_DOT || p->next.type == TOKEN_OPEN_SQUARE)
        return Qundef;

    const char *str = p->cur.val;
    long size = p->cur.val_end - str;
    VALUE result = Qundef;
    switch (size) {
        case 3:
            if (memcmp(str, "nil", size) == 0)
                result = Qnil;
            break;
        case 4:
            if (memcmp(str, "null", size) == 0) {
                result = Qnil;
            } else if (memcmp(str, "true", size) == 0) {
                result = Qtrue;
            }
            break;
        case 5:
            switch (*str) {
                case 'f':
                    if (memcmp(str, "false", size) == 0)
                        result = Qfalse;
                    break;
                case 'b':
                    if (memcmp(str, "blank", size) == 0)
                        result = empty_string;
                    break;
                case 'e':
                    if (memcmp(str, "empty", size) == 0)
                        result = empty_string;
                    break;
            }
            break;
    }
    if (result != Qundef)
        parser_consume_any(p);
    return result;
}

VALUE try_parse_constant_expression(parser_t *p)
{
    switch (p->cur.type) {
        case TOKEN_IDENTIFIER:
            return try_parse_literal(p);

        case TOKEN_NUMBER:
            return parse_number(p);

        case TOKEN_OPEN_ROUND:
            return try_parse_constant_range(p);

        case TOKEN_STRING:
        {
            lexer_token_t token = parser_consume_any(p);
            token.val++;
            token.val_end--;
            return token_to_rstr(token);
        }
    }
    return Qundef;
}

static void parse_and_compile_number(parser_t *p, vm_assembler_t *code)
{
    VALUE num = parse_number(p);
    if (RB_FIXNUM_P(num))
        vm_assembler_add_push_fixnum(code, num);
    else
        vm_assembler_add_push_const(code, num);
    return;
}

void parse_and_compile_expression(parser_t *p, vm_assembler_t *code)
{
    switch (p->cur.type) {
        case TOKEN_IDENTIFIER:
        {
            VALUE literal = try_parse_literal(p);
            if (literal != Qundef) {
                vm_assembler_add_push_literal(code, literal);
                return;
            }
            
             __attribute__ ((fallthrough));
        }
        case TOKEN_OPEN_SQUARE:
            parse_and_compile_variable_lookup(p, code);
            return;

        case TOKEN_NUMBER:
            parse_and_compile_number(p, code);
            return;

        case TOKEN_OPEN_ROUND:
            parse_and_compile_range(p, code);
            return;

        case TOKEN_STRING:
        {
            lexer_token_t token = parser_consume_any(p);
            token.val++;
            token.val_end--;
            VALUE str = token_to_rstr(token);
            vm_assembler_add_push_const(code, str);
            return;
        }
    }

    if (p->cur.type == TOKEN_EOS) {
        rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "[:%s] is not a valid expression", symbol_names[p->cur.type]);
    } else {
        rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "[:%s, \"%.*s\"] is not a valid expression",
                 symbol_names[p->cur.type], (int)(p->cur.val_end - p->cur.val), p->cur.val);
    }
}

void liquid_define_parser(void)
{
    id_to_i = rb_intern("to_i");
    idEvaluate = rb_intern("evaluate");

    empty_string = rb_utf8_str_new_literal("");
    rb_global_variable(&empty_string);
}

