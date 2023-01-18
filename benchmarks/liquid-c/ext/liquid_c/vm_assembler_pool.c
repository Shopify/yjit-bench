#include "vm_assembler_pool.h"
#include "parse_context.h"

static VALUE cLiquidCVMAssemblerPool;

static void vm_assembler_pool_mark(void *ptr)
{
    vm_assembler_pool_t *pool = ptr;

    rb_gc_mark(pool->self);
}

static void vm_assembler_pool_free(void *ptr)
{
    vm_assembler_pool_t *pool = ptr;

    vm_assembler_element_t *element = pool->freelist;
    while (element) {
        vm_assembler_free(&element->vm_assembler);
        vm_assembler_element_t *next = element->next;
        xfree(element);
        element = next;
    }

    xfree(pool);
}

static size_t vm_assembler_pool_memsize(const void *ptr)
{
    const vm_assembler_pool_t *pool = ptr;

    size_t elements_size = 0;
    vm_assembler_element_t *element = pool->freelist;
    while (element) {
        elements_size += sizeof(vm_assembler_element_t) + vm_assembler_alloc_memsize(&element->vm_assembler);
        element = element->next;
    }

    return sizeof(vm_assembler_pool_t) + elements_size;
}

const rb_data_type_t vm_assembler_pool_data_type = {
    "liquid_vm_assembler_pool",
    { vm_assembler_pool_mark, vm_assembler_pool_free, vm_assembler_pool_memsize, },
    NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE vm_assembler_pool_new(void)
{
    vm_assembler_pool_t *pool;
    VALUE obj = TypedData_Make_Struct(cLiquidCVMAssemblerPool, vm_assembler_pool_t, &vm_assembler_pool_data_type, pool);

    pool->self = obj;
    pool->freelist = NULL;

    return obj;
}

vm_assembler_t *vm_assembler_pool_alloc_assembler(vm_assembler_pool_t *pool)
{
    vm_assembler_element_t *element;
    if (!pool->freelist) {
        element = xmalloc(sizeof(vm_assembler_element_t));
        element->next = NULL;
        vm_assembler_init(&element->vm_assembler);
    } else {
        element = pool->freelist;
        pool->freelist = element->next;
    }

    return &element->vm_assembler;
}

static vm_assembler_element_t *get_element_from_assembler(vm_assembler_t *assembler)
{
    return (vm_assembler_element_t *)((char *)assembler - offsetof(vm_assembler_element_t, vm_assembler));
}

void vm_assembler_pool_free_assembler(vm_assembler_t *assembler)
{
    vm_assembler_element_t *element = get_element_from_assembler(assembler);
    vm_assembler_free(&element->vm_assembler);
    xfree(element);
}

void vm_assembler_pool_recycle_assembler(vm_assembler_pool_t *pool, vm_assembler_t *assembler)
{
    vm_assembler_element_t *element = get_element_from_assembler(assembler);
    vm_assembler_reset(&element->vm_assembler);
    element->next = pool->freelist;
    pool->freelist = element;
}

void liquid_define_vm_assembler_pool(void)
{
    cLiquidCVMAssemblerPool = rb_define_class_under(mLiquidC, "VMAssemblerPool", rb_cObject);
    rb_global_variable(&cLiquidCVMAssemblerPool);
    rb_undef_alloc_func(cLiquidCVMAssemblerPool);
}
