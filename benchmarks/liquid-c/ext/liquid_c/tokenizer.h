#if !defined(LIQUID_TOKENIZER_H)
#define LIQUID_TOKENIZER_H

enum token_type {
    TOKENIZER_TOKEN_NONE = 0,
    TOKEN_INVALID,
    TOKEN_RAW,
    TOKEN_TAG,
    TOKEN_VARIABLE,
    TOKEN_BLANK_LIQUID_TAG_LINE
};

typedef struct token {
    enum token_type type;

    // str_trimmed contains no tag delimiters
    const char *str_trimmed, *str_full;
    long len_trimmed, len_full;

    bool lstrip, rstrip;
} token_t;

typedef struct tokenizer {
    VALUE source;
    const char *cursor, *cursor_end;
    unsigned int line_number;
    bool lstrip_flag;
    bool for_liquid_tag;

    // Temporary to test rollout of the fix for this bug
    bool bug_compatible_whitespace_trimming;

    char *raw_tag_body;
    unsigned int raw_tag_body_len;
} tokenizer_t;

extern VALUE cLiquidTokenizer;
extern const rb_data_type_t tokenizer_data_type;
#define Tokenizer_Get_Struct(obj, sval) TypedData_Get_Struct(obj, tokenizer_t, &tokenizer_data_type, sval)

void liquid_define_tokenizer(void);
void tokenizer_next(tokenizer_t *tokenizer, token_t *token);

void tokenizer_setup_for_liquid_tag(tokenizer_t *tokenizer, const char *cursor, const char *cursor_end, int line_number);

#endif

