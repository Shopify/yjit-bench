#if !defined(LIQUID_LEXER_H)
#define LIQUID_LEXER_H

enum lexer_token_type {
    TOKEN_NONE,
    TOKEN_COMPARISON,
    TOKEN_STRING,
    TOKEN_NUMBER,
    TOKEN_IDENTIFIER,
    TOKEN_DOTDOT,
    TOKEN_EOS,

    TOKEN_PIPE = '|',
    TOKEN_DOT = '.',
    TOKEN_COLON = ':',
    TOKEN_COMMA = ',',
    TOKEN_OPEN_SQUARE = '[',
    TOKEN_CLOSE_SQUARE = ']',
    TOKEN_OPEN_ROUND = '(',
    TOKEN_CLOSE_ROUND = ')',
    TOKEN_QUESTION = '?',
    TOKEN_DASH = '-',

    TOKEN_END = 256
};

#define TOKEN_FLOAT_NUMBER 0x4

typedef struct lexer_token {
    unsigned char type, flags;
    const char *val, *val_end;
} lexer_token_t;

extern const char *symbol_names[TOKEN_END];

const char *lex_one(const char *str, const char *end, lexer_token_t *token);

inline static VALUE token_to_rstr(lexer_token_t token) {
    return rb_enc_str_new(token.val, token.val_end - token.val, utf8_encoding);
}

inline static VALUE token_check_for_symbol(lexer_token_t token) {
    return rb_check_symbol_cstr(token.val, token.val_end - token.val, utf8_encoding);
}

inline static VALUE token_to_rstr_leveraging_existing_symbol(lexer_token_t token) {
    VALUE sym = token_check_for_symbol(token);
    if (RB_LIKELY(sym != Qnil))
        return rb_sym2str(sym);
    return token_to_rstr(token);
}

inline static VALUE token_to_rsym(lexer_token_t token) {
    VALUE sym = token_check_for_symbol(token);
    if (RB_LIKELY(sym != Qnil))
        return sym;
    return rb_str_intern(token_to_rstr(token));
}

#endif

