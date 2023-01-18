#ifndef LIQUID_RESOURCE_LIMITS
#define LIQUID_RESOURCE_LIMITS

typedef struct resource_limits {
    long render_length_limit;
    long render_score_limit;
    long assign_score_limit;
    bool reached_limit;
    long last_capture_length;
    long render_score;
    long assign_score;
} resource_limits_t;

extern VALUE cLiquidResourceLimits;
extern const rb_data_type_t resource_limits_data_type;
#define ResourceLimits_Get_Struct(obj, sval) TypedData_Get_Struct(obj, resource_limits_t, &resource_limits_data_type, sval)

void liquid_define_resource_limits(void);
void resource_limits_raise_limits_reached(resource_limits_t *resource_limit);
void resource_limits_increment_render_score(resource_limits_t *resource_limits, long amount);
void resource_limits_increment_write_score(resource_limits_t *resource_limits, VALUE output);

#endif
