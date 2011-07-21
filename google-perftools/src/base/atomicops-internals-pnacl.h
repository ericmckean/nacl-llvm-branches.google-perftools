// Copyright 2011 Google Inc. All Rights Reserved.
// Author: dschuff@google.com (Derek Schuff)


#ifndef BASE_ATOMICOPS_INTERNALS_PNACL_H_
#define BASE_ATOMICOPS_INTERNALS_PNACL_H_

typedef int32_t Atomic32;

namespace base {
namespace subtle {

extern "C" Atomic32 llvm_atomic_swap(volatile Atomic32 *ptr, Atomic32 new_value)
  asm("llvm.atomic.swap.i32.p0i32");

// __sync_synchronize is a full barrier might be more conservative than we need
// depending on the usage in base, and the platform. if we want to relax it
// we could maybe use llvm.memory.barrier
// TODO(dschuff) rumor has it that __sync_synchronize expands to a no-op on
//  ARM. check this.
inline void MemoryBarrier() {
  __sync_synchronize();
}

inline Atomic32 Acquire_Load(volatile const Atomic32* ptr) {
  Atomic32 value = *ptr;
  MemoryBarrier();
  return value;
}

inline void Acquire_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
  MemoryBarrier();
}

inline Atomic32 Release_Load(volatile const Atomic32* ptr) {
  MemoryBarrier();
  return *ptr;
}

inline void Release_Store(volatile Atomic32* ptr, Atomic32 value) {
  MemoryBarrier();
  *ptr = value;
}

inline Atomic32 NoBarrier_Load(volatile const Atomic32* ptr) {
  return *ptr;
}

inline Atomic32 NoBarrier_AtomicExchange(volatile Atomic32* ptr,
                                         Atomic32 new_value) {
  return llvm_atomic_swap(ptr, new_value);
}

inline Atomic32 NoBarrier_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  return __sync_val_compare_and_swap(ptr, old_value, new_value);
}

inline Atomic32 Acquire_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  Atomic32 ret = NoBarrier_CompareAndSwap(ptr, old_value, new_value);
  MemoryBarrier();
  return ret;
}

inline Atomic32 Release_CompareAndSwap(volatile Atomic32* ptr,
                                       Atomic32 old_value,
                                       Atomic32 new_value) {
  MemoryBarrier();
  return NoBarrier_CompareAndSwap(ptr, old_value, new_value);
}

inline Atomic32 NoBarrier_AtomicIncrement(volatile Atomic32* ptr,
                                          Atomic32 increment) {
  return __sync_add_and_fetch(ptr, increment);
}

inline Atomic32 Barrier_AtomicIncrement(volatile Atomic32* ptr,
                                        Atomic32 increment) {
  Atomic32 temp = __sync_add_and_fetch(ptr, increment);
  MemoryBarrier();
  return temp;
}

inline void NoBarrier_Store(volatile Atomic32* ptr, Atomic32 value) {
  *ptr = value;
}


}
}

#endif  // BASE_ATOMICOPS_INTERNALS_PNACL_H_
