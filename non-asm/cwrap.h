
inline void free(void *ptr) {
  asm volatile ("call dfree" : "+D" (ptr) : : "eax", "ebx", "esi");
}

inline void *malloc(size_t size) {
  void *ptr;
  asm("call dmalloc" : "=D" (ptr), "+c" (size));
  return ptr;
}

// defragment dynamic memory
void memcompact() asm("dmemcompact");

