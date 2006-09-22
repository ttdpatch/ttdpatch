
inline void free(void *ptr) {
  asm("call dfree" : : "D" (ptr));
}

inline void *malloc(size_t size) {
  void *ptr;
  asm("call dmalloc" : "=D" (ptr) : "c" (size));
  return ptr;
}
