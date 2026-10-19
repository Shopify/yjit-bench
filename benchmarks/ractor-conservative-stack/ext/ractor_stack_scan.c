#include <ruby.h>
#include <limits.h>
#include <stdint.h>
#include <string.h>

#define MAX_FRAME_SLOTS 16384
#define SLOT_KINDS 8
#define MAX_OWNED_STRING_LEN 1024
#define MAX_DEPTH (LONG_MAX / MAX_FRAME_SLOTS - 1)

static ID id_descend;
static VALUE eCorruptionError;

struct descend_args {
    VALUE walker;
    VALUE depth;
};

static VALUE
descend_protected(VALUE ptr)
{
    struct descend_args *args = (struct descend_args *)ptr;
    return rb_funcall(args->walker, id_descend, 1, args->depth);
}

static long
owned_string_len(long slot)
{
    if (slot % (SLOT_KINDS * 16) == 0) return MAX_OWNED_STRING_LEN;
    if (slot % (SLOT_KINDS * 2) == 0) return 96;
    return 16;
}

static void
owned_pattern(char *buf, long len, uintptr_t nonce, long depth, long slot)
{
    uint64_t x = (uint64_t)nonce ^ ((uint64_t)depth << 32) ^ (uint64_t)slot;
    for (long i = 0; i < len; i++) {
        x = x * 6364136223846793005ULL + 1442695040888963407ULL;
        buf[i] = (char)('a' + (char)((x >> 59) % 26));
    }
}

static void
verify_owned_string(VALUE str, uintptr_t nonce, long depth, long slot)
{
    char expected[MAX_OWNED_STRING_LEN];
    long len = owned_string_len(slot);

    if (!RB_TYPE_P(str, T_STRING) || RSTRING_LEN(str) != len) {
        rb_raise(eCorruptionError, "string held only by a C stack slot was collected (depth %ld, slot %ld)", depth, slot);
    }
    owned_pattern(expected, len, nonce, depth, slot);
    if (memcmp(RSTRING_PTR(str), expected, (size_t)len) != 0) {
        rb_raise(eCorruptionError, "string held only by a C stack slot was overwritten (depth %ld, slot %ld)", depth, slot);
    }
}

static long
owned_array_tag(uintptr_t nonce, long depth)
{
    return depth ^ (long)(nonce >> 3);
}

static void
verify_owned_array(VALUE ary, uintptr_t nonce, long depth, long slot)
{
    if (!RB_TYPE_P(ary, T_ARRAY) || RARRAY_LEN(ary) != 3 ||
            RARRAY_AREF(ary, 0) != LONG2FIX(slot) || RARRAY_AREF(ary, 2) != LONG2FIX(owned_array_tag(nonce, depth))) {
        rb_raise(eCorruptionError, "array held only by a C stack slot was collected or overwritten (depth %ld, slot %ld)", depth, slot);
    }
}

/*
 * One native frame of the descent. The volatile arrays keep every slot in
 * memory, so a GC deeper in the call chain must find the owned strings and
 * arrays by scanning this frame conservatively.
 */
static VALUE
native_frame(VALUE self, VALUE walker, VALUE vdepth, VALUE pool, VALUE vslots, VALUE vscalars)
{
    long depth = NUM2LONG(vdepth);
    long nslots = NUM2LONG(vslots);
    long nscalars = NUM2LONG(vscalars);
    long pool_len;
    VALUE result;

    Check_Type(pool, T_ARRAY);
    pool_len = RARRAY_LEN(pool);
    if (pool_len == 0) rb_raise(rb_eArgError, "pool must not be empty");
    if (depth < 0 || depth > MAX_DEPTH) rb_raise(rb_eArgError, "depth must be in 0..%ld", (long)MAX_DEPTH);
    if (nslots < SLOT_KINDS || nslots > MAX_FRAME_SLOTS || nslots % SLOT_KINDS != 0) {
        rb_raise(rb_eArgError, "frame slots must be a multiple of %d in %d..%d", SLOT_KINDS, SLOT_KINDS, MAX_FRAME_SLOTS);
    }
    if (nscalars < 0 || nscalars > MAX_FRAME_SLOTS) {
        rb_raise(rb_eArgError, "frame scalars must be in 0..%d", MAX_FRAME_SLOTS);
    }

    volatile VALUE slots[nslots];
    volatile uintptr_t scalars[nscalars + 1];
    char pattern[MAX_OWNED_STRING_LEN];
    /*
     * The frame address makes the expected string bytes and array tag specific
     * to this native frame, so an object allocated into a missed root's freed slot is
     * unlikely to pass verification. Depth and slot alone repeat in every
     * Ractor that runs the same descent.
     */
    uintptr_t nonce = (uintptr_t)&slots[0];

    for (long i = 0; i < nslots; i++) slots[i] = Qnil;

    /*
     * Only kinds 0 (owned string) and 4 (owned array) are roots: nothing else
     * references them, and they are verified after the call returns. The other
     * kinds, and the scalars below, are the words a real C frame also holds:
     * immediates, integers, stack addresses and interior pointers. The
     * conservative scan must reject or harmlessly mark each of them, and they
     * take different paths through it.
     */
    for (long i = 0; i < nslots; i++) {
        VALUE pooled = RARRAY_AREF(pool, (depth * nslots + i) % pool_len);

        switch (i % SLOT_KINDS) {
          case 0: {
            long len = owned_string_len(i);
            owned_pattern(pattern, len, nonce, depth, i);
            slots[i] = rb_str_new(pattern, len);
            break;
          }
          case 1:
          case 5:
            slots[i] = pooled;
            break;
          case 2:
            slots[i] = pooled + sizeof(VALUE);
            break;
          case 3:
            slots[i] = (VALUE)RSTRING_PTR(slots[i - 3]);
            break;
          case 4:
            slots[i] = rb_ary_new_from_args(3, LONG2FIX(i), pooled, LONG2FIX(owned_array_tag(nonce, depth)));
            break;
          case 6:
            slots[i] = (i & SLOT_KINDS) ? LONG2FIX(i) : ID2SYM(id_descend);
            break;
          default:
            slots[i] = (VALUE)&slots[i - 7];
            break;
        }
    }

    for (long j = 0; j < nscalars; j++) {
        switch (j % 4) {
          case 0:
            scalars[j] = (uintptr_t)(j * (depth + 1));
            break;
          case 1: {
            double d = (double)j / (double)(depth + 1);
            uint64_t bits;
            memcpy(&bits, &d, sizeof(bits));
            scalars[j] = (uintptr_t)bits;
            break;
          }
          case 2:
            scalars[j] = (uintptr_t)RSTRING_PTR(slots[(j % (nslots / SLOT_KINDS)) * SLOT_KINDS]);
            break;
          default:
            scalars[j] = (uintptr_t)&scalars[j];
            break;
        }
    }
    scalars[nscalars] = (uintptr_t)pattern;

    VALUE next = LONG2NUM(depth - 1);

    /*
     * Enter the next level three ways, so the scanned stack also holds
     * rb_protect's jmp_buf (saved registers that may hold VALUEs) and the VM
     * frames of a block call, as real extensions produce.
     */
    switch (depth % 3) {
      case 0:
        result = rb_funcall(walker, id_descend, 1, next);
        break;
      case 1: {
        struct descend_args args = { walker, next };
        int state = 0;
        result = rb_protect(descend_protected, (VALUE)&args, &state);
        if (state) rb_jump_tag(state);
        break;
      }
      default:
        result = rb_block_given_p() ? rb_yield(next) : rb_funcall(walker, id_descend, 1, next);
        break;
    }

    for (long i = 0; i < nslots; i += SLOT_KINDS) {
        verify_owned_string(slots[i], nonce, depth, i);
        verify_owned_array(slots[i + 4], nonce, depth, i + 4);
    }

    return result;
}

void
Init_ractor_stack_scan(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
    rb_ext_ractor_safe(true);
#endif
    VALUE mod = rb_define_module("RactorStackScan");
    eCorruptionError = rb_define_class_under(mod, "CorruptionError", rb_eRuntimeError);
    id_descend = rb_intern("descend");
    rb_define_const(mod, "MAX_FRAME_SLOTS", INT2FIX(MAX_FRAME_SLOTS));
    rb_define_const(mod, "MAX_DEPTH", LONG2NUM(MAX_DEPTH));
    rb_define_const(mod, "SLOT_KINDS", INT2FIX(SLOT_KINDS));
    rb_define_const(mod, "MAX_OWNED_STRING_LEN", INT2FIX(MAX_OWNED_STRING_LEN));
    rb_define_const(mod, "WORD_SIZE", INT2FIX(sizeof(VALUE)));
    rb_define_module_function(mod, "native_frame", native_frame, 5);
}
