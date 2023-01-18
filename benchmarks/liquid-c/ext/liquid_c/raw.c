#include "liquid.h"
#include "raw.h"
#include "stringutil.h"
#include "tokenizer.h"

static VALUE id_block_name, id_raise_tag_never_closed, id_block_delimiter, id_ivar_body;
static VALUE cLiquidRaw;

struct full_token_possibly_invalid_t {
    long body_len;
    const char *delimiter_start;
    long delimiter_len;
};

static bool match_full_token_possibly_invalid(token_t *token, struct full_token_possibly_invalid_t *match)
{
    const char *str = token->str_full;
    long len = token->len_full;

    match->body_len = 0;
    match->delimiter_start = NULL;
    match->delimiter_len = 0;

    if (len < 5) return false; // Must be at least 5 characters: \{%\w%\}
    if (str[len - 1] != '}' || str[len - 2] != '%') return false;

    const char *curr_delimiter_start;
    long curr_delimiter_len = 0;

    for (long i = len - 3; i >= 0; i--) {
        char c = str[i];

        if (is_word_char(c)) {
            curr_delimiter_start = str + i;
            curr_delimiter_len++;
        } else {
            if (curr_delimiter_len > 0) {
                match->delimiter_start = curr_delimiter_start;
                match->delimiter_len = curr_delimiter_len;
            }
            curr_delimiter_start = NULL;
            curr_delimiter_len = 0;
        }

        if (c == '%' && match->delimiter_len > 0 &&
                i - 1 >= 0 && str[i - 1] == '{') {
            match->body_len = i - 1;
            return true;
        }
    }

    return false;
}

static VALUE raw_parse_method(VALUE self, VALUE tokens)
{
    tokenizer_t *tokenizer;
    Tokenizer_Get_Struct(tokens, tokenizer);

    token_t token;
    struct full_token_possibly_invalid_t match;

    VALUE block_delimiter = rb_funcall(self, id_block_delimiter, 0);
    Check_Type(block_delimiter, T_STRING);
    char *block_delimiter_str = RSTRING_PTR(block_delimiter);
    long block_delimiter_len = RSTRING_LEN(block_delimiter);

    const char *body = NULL;
    long body_len = 0;

    while (true) {
        tokenizer_next(tokenizer, &token);

        if (!token.type) break;

        if (body == NULL) {
            body = token.str_full;
        }

        if (match_full_token_possibly_invalid(&token, &match)
                && match.delimiter_len == block_delimiter_len
                && memcmp(match.delimiter_start, block_delimiter_str, block_delimiter_len) == 0) {
            body_len += match.body_len;
            VALUE body_str = rb_enc_str_new(body, body_len, utf8_encoding);
            rb_ivar_set(self, id_ivar_body, body_str);
            if (RBASIC_CLASS(self) == cLiquidRaw) {
                tokenizer->raw_tag_body = RSTRING_PTR(body_str);
                tokenizer->raw_tag_body_len = (unsigned int)body_len;
            }
            return Qnil;
        }

        body_len += token.len_full;
    }

    rb_funcall(self, id_raise_tag_never_closed, 1, rb_funcall(self, id_block_name, 0));
    return Qnil;
}

void liquid_define_raw(void)
{
    id_block_name = rb_intern("block_name");
    id_raise_tag_never_closed = rb_intern("raise_tag_never_closed");
    id_block_delimiter = rb_intern("block_delimiter");
    id_ivar_body = rb_intern("@body");

    cLiquidRaw = rb_const_get(mLiquid, rb_intern("Raw"));

    rb_define_method(cLiquidRaw, "c_parse", raw_parse_method, 1);
}
