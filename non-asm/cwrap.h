
inline void free(void *ptr) {
  asm volatile ("call dfree" : "=D" (ptr) : "D" (ptr) : "eax", "ebx", "esi");
}

inline void *malloc(size_t size) {
  void *ptr;
  asm("call dmalloc" : "=D" (ptr), "=c" (size) : "c" (size));
  return ptr;
}
