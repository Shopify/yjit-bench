#if !defined(LIQUID_BLOCK_H)
#define LIQUID_BLOCK_H

#include "document_body.h"
#include "vm_assembler_pool.h"

typedef struct block_body {
    bool compiled;
    VALUE obj;

    union {
        struct {
            document_body_entry_t document_body_entry;
            VALUE nodelist;
        } compiled;
        struct {
            VALUE parse_context;
            vm_assembler_pool_t *vm_assembler_pool;
            bool blank;
            unsigned int render_score;
            vm_assembler_t *code;
        } intermediate;
    } as;
} block_body_t;

void liquid_define_block_body(void);

static inline uint8_t *block_body_instructions_ptr(block_body_header_t *body)
{
    return ((uint8_t *)body) + body->instructions_offset;
}

#endif
