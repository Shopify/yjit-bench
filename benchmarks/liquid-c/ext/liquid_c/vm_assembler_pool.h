#ifndef LIQUID_VM_ASSEMBLER_POOL_H
#define LIQUID_VM_ASSEMBLER_POOL_H

#include "liquid.h"
#include "vm_assembler.h"

typedef struct vm_assembler_element {
    struct vm_assembler_element *next;
    vm_assembler_t vm_assembler;
} vm_assembler_element_t;

typedef struct vm_assembler_pool {
    VALUE self;
    vm_assembler_element_t *freelist;
} vm_assembler_pool_t;

extern const rb_data_type_t vm_assembler_pool_data_type;
#define VMAssemblerPool_Get_Struct(obj, sval) TypedData_Get_Struct(obj, vm_assembler_pool_t, &vm_assembler_pool_data_type, sval)

void liquid_define_vm_assembler_pool(void);
VALUE vm_assembler_pool_new(void);
vm_assembler_t *vm_assembler_pool_alloc_assembler(vm_assembler_pool_t *pool);
void vm_assembler_pool_free_assembler(vm_assembler_t *assembler);
void vm_assembler_pool_recycle_assembler(vm_assembler_pool_t *pool, vm_assembler_t *assembler);

#endif
