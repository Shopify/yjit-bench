#if !defined(LIQUID_UTIL_H)
#define LIQUID_UTIL_H

inline static const char *read_while(const char *start, const char *end, int (func)(int))
{
    while (start < end && func((unsigned char) *start)) start++;
    return start;
}

inline static const char *read_while_reverse(const char *start, const char *end, int (func)(int))
{
    end--;
    while (start <= end && func((unsigned char) *end)) end--;
    end++;
    return end;
}

inline static int count_newlines(const char *start, const char *end)
{
    int count = 0;
    while (start < end) {
        if (*start == '\n') count++;
        start++;
    }
    return count;
}

inline static int is_non_newline_space(int c)
{
    return rb_isspace(c) && c != '\n';
}

inline static int not_newline(int c)
{
    return c != '\n';
}

inline static bool is_word_char(char c)
{
    return ISALNUM(c) || c == '_';
}

#endif

