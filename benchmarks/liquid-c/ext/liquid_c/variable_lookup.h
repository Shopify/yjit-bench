#if !defined(LIQUID_VARIABLE_LOOKUP_H)
#define LIQUID_VARIABLE_LOOKUP_H

void liquid_define_variable_lookup(void);
VALUE variable_lookup_key(VALUE context, VALUE object, VALUE key, bool is_command);

#endif

