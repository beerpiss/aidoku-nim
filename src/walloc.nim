{.compile: "src/walloc.c".}
proc malloc(size: csize_t): pointer {.importc: "malloc".}
proc free(p: pointer): void {.importc: "free".}

proc calloc(nmemb, size: csize_t): pointer {.exportc.} =
  if nmemb == 0 or size == 0:
    return nil
  var sz = nmemb * size
  let p = malloc(sz)
  while sz > 0:
    sz -= 1
    cast[ptr int](cast[uint](p) + sz)[] = 0
  return p

# TODO: Fix this to only reallocate if needed
proc realloc(p: pointer, size: csize_t): pointer {.exportc.} =
  let p2 = malloc(size)
  copyMem(p2, p, size)
  free(p)
  return p2
