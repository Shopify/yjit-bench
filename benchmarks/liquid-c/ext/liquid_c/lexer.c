#include "liquid.h"
#include "lexer.h"
#include "usage.h"
#include <stdio.h>

const char *symbol_names[TOKEN_END] = {
    [TOKEN_NONE] = "none",
    [TOKEN_COMPARISON] = "comparison",
    [TOKEN_STRING] = "string",
    [TOKEN_NUMBER] = "number",
    [TOKEN_IDENTIFIER] = "id",
    [TOKEN_DOTDOT] = "dotdot",
    [TOKEN_EOS] = "end_of_string",
    [TOKEN_PIPE] = "pipe",
    [TOKEN_DOT] = "dot",
    [TOKEN_COLON] = "colon",
    [TOKEN_COMMA] = "comma",
    [TOKEN_OPEN_SQUARE] = "open_square",
    [TOKEN_CLOSE_SQUARE] = "close_square",
    [TOKEN_OPEN_ROUND] = "open_round",
    [TOKEN_CLOSE_ROUND] = "close_round",
    [TOKEN_QUESTION] = "question",
    [TOKEN_DASH] = "dash"
};

inline static int is_identifier(char c)
{
    return ISALNUM(c) || c == '_' || c == '-';
}

inline static int is_special(char c)
{
    switch (c) {
        case '|': case '.': case ':': case ',':
        case '[': case ']': case '(': case ')':
        case '?': case '-':
            return 1;
    }
    return 0;
}

// Returns a pointer to the character after the end of the match.
inline static const char *prefix_end(const char *cur, const char *end, const char *pattern)
{
    size_t pattern_len = strlen(pattern);

    if (pattern_len > (size_t)(end - cur)) return NULL;
    if (memcmp(cur, pattern, pattern_len) != 0) return NULL;

    return cur + pattern_len;
}

inline static const char *scan_past(const char *cur, const char *end, char target)
{
    const char *match = memchr(cur + 1, target, end - cur - 1);
    return match ? match + 1 : NULL;
}

#define RETURN_TOKEN(t, n) { \
    const char *tok_end = str + (n); \
    token->type = (t); \
    token->val = str; \
    return (token->val_end = tok_end); \
}

// Reads one token from start, and fills it into the token argument.
// Returns the start of the next token if any, otherwise the end of the string.
const char *lex_one(const char *start, const char *end, lexer_token_t *token)
{
    // str references the start of the token, after whitespace is skipped.
    // cur references the currently processing character during iterative lexing.
    const char *str = start, *cur;

    while (str < end && ISSPACE(*str)) ++str;

    token->val = token->val_end = NULL;
    token->flags = 0;

    if (str >= end) return str;

    char c = *str;  // First character of the token.
    char cn = '\0'; // Second character if available, for lookahead.
    if (str + 1 < end) cn = str[1];

    switch (c) {
        case '<':
            RETURN_TOKEN(TOKEN_COMPARISON, cn == '>' || cn == '=' ? 2 : 1);
        case '>':
            RETURN_TOKEN(TOKEN_COMPARISON, cn == '=' ? 2 : 1);
        case '=':
        case '!':
            if (cn == '=') RETURN_TOKEN(TOKEN_COMPARISON, 2);
            break;
        case '.':
            if (cn == '.') RETURN_TOKEN(TOKEN_DOTDOT, 2);
            break;
    }

    if ((cur = prefix_end(str, end, "contains")))
        RETURN_TOKEN(TOKEN_COMPARISON, cur - str);

    if (c == '\'' || c == '"') {
        cur = scan_past(str, end, c);

        if (cur) {
            // Quote was properly terminated.
            RETURN_TOKEN(TOKEN_STRING, cur - str);
        }
    }

    // Instrument for bug: https://github.com/Shopify/liquid-c/pull/120
    if (c == '-' && str + 1 < end && str[1] == '.') {
        usage_increment("liquid_c_negative_float_without_integer");
    }

    if (ISDIGIT(c) || c == '-') {
        int has_dot = 0;
        cur = str;
        while (++cur < end) {
            if (!has_dot && *cur == '.') {
                has_dot = 1;
            } else if (!ISDIGIT(*cur)) {
                break;
            }
        }
        cur--; // Point to last digit (or dot).

        if (*cur == '.') {
            cur--; // Ignore any trailing dot.
            has_dot = 0;
        }
        if (*cur != '-') {
            if (has_dot) token->flags |= TOKEN_FLOAT_NUMBER;
            RETURN_TOKEN(TOKEN_NUMBER, cur + 1 - str);
        }
    }

    if (ISALPHA(c) || c == '_') {
        cur = str;
        while (++cur < end && is_identifier(*cur)) {}
        if (cur < end && *cur == '?') cur++;
        RETURN_TOKEN(TOKEN_IDENTIFIER, cur - str);
    }

    if (is_special(c)) RETURN_TOKEN(c, 1);

    rb_enc_raise(utf8_encoding, cLiquidSyntaxError, "Unexpected character %c", c);
    return NULL;
}

#undef RETURN_TOKEN

