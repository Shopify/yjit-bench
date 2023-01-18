#include <assert.h>
#include "liquid.h"
#include "tokenizer.h"
#include "stringutil.h"

VALUE cLiquidTokenizer;

static void tokenizer_mark(void *ptr)
{
    tokenizer_t *tokenizer = ptr;
    rb_gc_mark(tokenizer->source);
}

static void tokenizer_free(void *ptr)
{
    tokenizer_t *tokenizer = ptr;
    xfree(tokenizer);
}

static size_t tokenizer_memsize(const void *ptr)
{
    return ptr ? sizeof(tokenizer_t) : 0;
}

const rb_data_type_t tokenizer_data_type = {
    "liquid_tokenizer",
    { tokenizer_mark, tokenizer_free, tokenizer_memsize, },
#if defined(RUBY_TYPED_FREE_IMMEDIATELY)
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

static VALUE tokenizer_allocate(VALUE klass)
{
    VALUE obj;
    tokenizer_t *tokenizer;

    obj = TypedData_Make_Struct(klass, tokenizer_t, &tokenizer_data_type, tokenizer);
    tokenizer->source = Qnil;
    tokenizer->bug_compatible_whitespace_trimming = false;
    tokenizer->raw_tag_body = NULL;
    tokenizer->raw_tag_body_len = 0;
    return obj;
}

static VALUE tokenizer_initialize_method(VALUE self, VALUE source, VALUE start_line_number, VALUE for_liquid_tag)
{
    tokenizer_t *tokenizer;

    Check_Type(source, T_STRING);
    check_utf8_encoding(source, "source");

#define MAX_SOURCE_CODE_BYTES ((1 << 24) - 1)
    if (RSTRING_LEN(source) > MAX_SOURCE_CODE_BYTES) {
        rb_enc_raise(utf8_encoding, rb_eArgError, "Source too large, max %d bytes", MAX_SOURCE_CODE_BYTES);
    }
#undef MAX_SOURCE_CODE_BYTES

    Tokenizer_Get_Struct(self, tokenizer);
    source = rb_str_dup_frozen(source);
    tokenizer->source = source;
    tokenizer->cursor = RSTRING_PTR(source);
    tokenizer->cursor_end = tokenizer->cursor + RSTRING_LEN(source);
    tokenizer->lstrip_flag = false;
    // tokenizer->line_number keeps track of the current line number or it is 0
    // to indicate that line numbers aren't being calculated
    tokenizer->line_number = FIX2UINT(start_line_number);
    tokenizer->for_liquid_tag = RTEST(for_liquid_tag);
    return Qnil;
}

// Internal function to setup an existing tokenizer from C for a liquid tag.
// This overwrites the passed in tokenizer, so a copy of the struct should
// be used to reset the tokenizer after parsing the liquid tag.
void tokenizer_setup_for_liquid_tag(tokenizer_t *tokenizer, const char *cursor, const char *cursor_end, int line_number)
{
    tokenizer->cursor = cursor;
    tokenizer->cursor_end = cursor_end;
    tokenizer->lstrip_flag = false;
    tokenizer->line_number = line_number;
    tokenizer->for_liquid_tag = true;
}

// Tokenizes contents of {% liquid ... %}
static void tokenizer_next_for_liquid_tag(tokenizer_t *tokenizer, token_t *token)
{
    const char *end = tokenizer->cursor_end;
    const char *start = tokenizer->cursor;
    const char *start_trimmed = read_while(start, end, is_non_newline_space);

    token->str_full = start;
    token->str_trimmed = start_trimmed;

    const char *end_full = read_while(start_trimmed, end, not_newline);
    if (end_full < end) {
        tokenizer->cursor = end_full + 1;
        if (tokenizer->line_number)
            tokenizer->line_number++;
    } else {
        tokenizer->cursor = end_full;
    }

    const char *end_trimmed = read_while_reverse(start_trimmed, end_full, rb_isspace);

    token->len_trimmed = end_trimmed - start_trimmed;
    token->len_full = end_full - token->str_full;

    if (token->len_trimmed == 0) {
        token->type = TOKEN_BLANK_LIQUID_TAG_LINE;
    } else {
        token->type = TOKEN_TAG;
    }
}

// Tokenizes contents of a full Liquid template
static void tokenizer_next_for_template(tokenizer_t *tokenizer, token_t *token)
{
    const char *cursor = tokenizer->cursor;
    const char *last = tokenizer->cursor_end - 1;

    token->str_full = cursor;
    token->type = TOKEN_RAW;

    while (cursor < last) {
        if (*cursor++ != '{')
            continue;

        char c = *cursor++;
        if (c != '%' && c != '{')
            continue;
        if (cursor <= last && *cursor == '-') {
            cursor++;
            token->rstrip = 1;
        }
        if (cursor - tokenizer->cursor > (ptrdiff_t)(2 + token->rstrip)) {
            token->type = TOKEN_RAW;
            cursor -= 2 + token->rstrip;
            token->lstrip = tokenizer->lstrip_flag;
            tokenizer->lstrip_flag = false;
            goto found;
        }
        tokenizer->lstrip_flag = false;
        token->type = TOKEN_INVALID;
        token->lstrip = token->rstrip;
        token->rstrip = 0;
        if (c == '%') {
            while (cursor < last) {
                if (*cursor++ != '%')
                    continue;
                c = *cursor++;
                while (c == '%' && cursor <= last)
                    c = *cursor++;
                if (c != '}')
                    continue;
                token->type = TOKEN_TAG;
                if(cursor[-3] == '-')
                    token->rstrip = tokenizer->lstrip_flag = true;
                goto found;
            }
            // unterminated tag
            cursor = tokenizer->cursor + 2;
            tokenizer->lstrip_flag = false;
            goto found;
        } else {
            while (cursor < last) {
                if (*cursor++ != '}')
                    continue;
                if (*cursor++ != '}') {
                    // variable incomplete end, used to end raw tags
                    cursor--;
                    goto found;
                }
                token->type = TOKEN_VARIABLE;
                if(cursor[-3] == '-')
                    token->rstrip = tokenizer->lstrip_flag = true;
                goto found;
            }
            // unterminated variable
            cursor = tokenizer->cursor + 2;
            tokenizer->lstrip_flag = false;
            goto found;
        }
    }
    cursor = last + 1;
    token->lstrip = tokenizer->lstrip_flag;
    tokenizer->lstrip_flag = false;
found:
    token->len_full = cursor - token->str_full;

    token->str_trimmed = token->str_full;
    token->len_trimmed = token->len_full;

    if (token->type == TOKEN_VARIABLE || token->type == TOKEN_TAG) {
        token->str_trimmed += 2 + token->lstrip;
        token->len_trimmed -= 2 + token->lstrip + 2;
        if (token->rstrip && token->len_trimmed)
            token->len_trimmed--;
    }

    assert(token->len_trimmed >= 0);

    tokenizer->cursor += token->len_full;

    if (tokenizer->line_number) {
        tokenizer->line_number += count_newlines(token->str_full, token->str_full + token->len_full);
    }
}

void tokenizer_next(tokenizer_t *tokenizer, token_t *token)
{
    memset(token, 0, sizeof(*token));

    if (tokenizer->cursor >= tokenizer->cursor_end) {
        return;
    }
    if (tokenizer->for_liquid_tag) {
        tokenizer_next_for_liquid_tag(tokenizer, token);
    } else {
        tokenizer_next_for_template(tokenizer, token);
    }
}

static VALUE tokenizer_shift_method(VALUE self)
{
    tokenizer_t *tokenizer;
    Tokenizer_Get_Struct(self, tokenizer);

    token_t token;
    tokenizer_next(tokenizer, &token);
    if (!token.type)
        return Qnil;

    // When sent back to Ruby, tokens are the raw string including whitespace
    // and tag delimiters. It should be possible to reconstruct the exact
    // template from the tokens.
    return rb_enc_str_new(token.str_full, token.len_full, utf8_encoding);
}

static VALUE tokenizer_shift_trimmed_method(VALUE self)
{
    tokenizer_t *tokenizer;
    Tokenizer_Get_Struct(self, tokenizer);

    token_t token;
    tokenizer_next(tokenizer, &token);
    if (!token.type)
        return Qnil;

    // This method doesn't include whitespace and tag delimiters. It allows for
    // testing the output of tokenizer_next as used by rb_block_parse.
    return rb_enc_str_new(token.str_trimmed, token.len_trimmed, utf8_encoding);
}

static VALUE tokenizer_line_number_method(VALUE self)
{
    tokenizer_t *tokenizer;
    Tokenizer_Get_Struct(self, tokenizer);

    if (tokenizer->line_number == 0)
        return Qnil;

    return UINT2NUM(tokenizer->line_number);
}

static VALUE tokenizer_for_liquid_tag_method(VALUE self)
{
    tokenizer_t *tokenizer;
    Tokenizer_Get_Struct(self, tokenizer);

    return tokenizer->for_liquid_tag ? Qtrue : Qfalse;
}


// Temporary to test rollout of the fix for this bug
static VALUE tokenizer_bug_compatible_whitespace_trimming(VALUE self) {
    tokenizer_t *tokenizer;
    Tokenizer_Get_Struct(self, tokenizer);

    tokenizer->bug_compatible_whitespace_trimming = true;
    return Qnil;
}

void liquid_define_tokenizer(void)
{
    cLiquidTokenizer = rb_define_class_under(mLiquidC, "Tokenizer", rb_cObject);
    rb_global_variable(&cLiquidTokenizer);

    rb_define_alloc_func(cLiquidTokenizer, tokenizer_allocate);
    rb_define_method(cLiquidTokenizer, "initialize", tokenizer_initialize_method, 3);
    rb_define_method(cLiquidTokenizer, "line_number", tokenizer_line_number_method, 0);
    rb_define_method(cLiquidTokenizer, "for_liquid_tag", tokenizer_for_liquid_tag_method, 0);
    rb_define_method(cLiquidTokenizer, "bug_compatible_whitespace_trimming!", tokenizer_bug_compatible_whitespace_trimming, 0);

    // For testing the internal token representation.
    rb_define_private_method(cLiquidTokenizer, "shift", tokenizer_shift_method, 0);
    rb_define_private_method(cLiquidTokenizer, "shift_trimmed", tokenizer_shift_trimmed_method, 0);
}

