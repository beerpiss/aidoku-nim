import macros, strutils
include walloc

macro exportwasm*(p: untyped): untyped =
    expectKind p, nnkProcDef
    result = p
    result.addPragma(ident"exportc")
    let cgenDecl = "NIM_EXTERNC __attribute__ ((visibility (\"default\"))) $# $#$#"

    result.addPragma(newColonExpr(ident"codegenDecl", newLit(cgenDecl)))

macro importwasm*(qualifier: string, p: untyped): untyped =
    expectKind p, nnkProcDef

    let names = qualifier.strVal.split('.', 1)
    let module = names[0]
    let name = if names.len > 1: names[1] else: p.name.strVal

    result = p
    result.addPragma(ident"importc")

    let cgenDecl = "NIM_EXTERNC __attribute__((import_module(\"" & module &
            "\"))) __attribute__((import_name(\"" & name & "\"))) $# $#$#"

    result.addPragma(newColonExpr(ident"codegenDecl", newLit(cgenDecl)))

# ------------------------------------
# Shit we probably don't need for now
# ------------------------------------
proc exit(code: cint) {.exportc.} = discard
proc fwrite(p: pointer, size, nmemb: csize_t,
        stream: pointer): csize_t {.exportc.} = discard
proc fflush(stream: pointer): cint {.exportc.} = discard
proc fputc(c: cint, stream: pointer): cint {.exportc.} = discard
proc flockfile(f: pointer) {.exportc.} = discard
proc funlockfile(f: pointer) {.exportc.} = discard
proc ferror(f: pointer): cint {.exportc.} = discard

{.emit: """
int stdout = 0;
int stderr = 1;
static int dummyErrno = 0;

N_LIB_PRIVATE void* memcpy(void* a, const void* b, size_t s) {
  char* aa = (char*)a;
  char* bb = (char*)b;
  while(s) {
    --s;
    *aa = *bb;
    ++aa;
    ++bb;
  }
  return a;
}

N_LIB_PRIVATE void* memmove(void *dest, const void *src, size_t len) { /* Copied from https://code.woboq.org/gcc/libgcc/memmove.c.html */
  char *d = dest;
  const char *s = src;
  if (d < s)
    while (len--)
      *d++ = *s++;
  else {
    char *lasts = s + (len-1);
    char *lastd = d + (len-1);
    while (len--)
      *lastd-- = *lasts--;
  }
  return dest;
}

N_LIB_PRIVATE void* memchr(register const void* src_void, int c, size_t length) { /* Copied from https://code.woboq.org/gcc/libiberty/memchr.c.html */
  const unsigned char *src = (const unsigned char *)src_void;

  while (length-- > 0) {
    if (*src == c)
     return (void*)src;
    src++;
  }
  return NULL;
}

N_LIB_PRIVATE int memcmp(const void* a, const void* b, size_t s) {
  char* aa = (char*)a;
  char* bb = (char*)b;
  if (aa == bb) return 0;

  while(s) {
    --s;
    int ia = *aa;
    int ib = *bb;
    int r = ia - ib; // TODO: The result might be inverted. Verify against C standard.
    if (r) return r;
    *aa = *bb;
    ++aa;
    ++bb;
  }
  return 0;
}

N_LIB_PRIVATE void* memset(void* a, int b, size_t s) {
  char* aa = (char*)a;
  while(s) {
    --s;
    *aa = b;
    ++aa;
  }
  return a;
}

N_LIB_PRIVATE size_t strlen(const char* a) {
  const char* b = a;
  while (*b++);
  return b - a - 1;
}

N_LIB_PRIVATE char* strerror(int errnum) {
  return "strerror is not supported";
}

N_LIB_PRIVATE int* __errno_location() {
  return &dummyErrno;
}

// N_LIB_PRIVATE char* strstr(char *haystack, const char *needle) {
//   if (haystack == NULL || needle == NULL) {
//     return NULL;
//   }
// 
//   for ( ; *haystack; haystack++) {
//     // Is the needle at this point in the haystack?
//     const char *h, *n;
//     for (h = haystack, n = needle; *h && *n && (*h == *n); ++h, ++n) {
//       // Match is progressing
//     }
//     if (*n == '\0') {
//       // Found match!
//       return haystack;
//     }
//     // Didn't match here.  Try again further along haystack.
//   }
//   return NULL;
// }

N_LIB_PRIVATE double fmod(double x, double y) {
  return x - trunc(x / y) * y;
}

N_LIB_PRIVATE float fmodf(float x, float y) {
  return fmod(x, y);
}

""".}

import std/compilesettings
static:
    # Nim will pass -lm and -lrt to linker, so we provide stubs, by compiling empty c file into nimcache/lib*.a, and pointing
    # the linker to nimcache
    const nimcache = querySetting(nimcacheDir)
    {.passL: "-L" & nimcache.}

    var compilerPath = querySetting(ccompilerPath)

    if compilerPath == "":
        compilerPath = "clang"
    when defined(windows):
        discard staticExec("mkdir " & nimcache)
    else:
        discard staticExec("mkdir -p " & nimcache)
    discard staticExec(compilerPath & " -c --target=wasm32-unknown-unknown-wasm -o " &
            nimcache & "/libm.a -x c -", input = "\n")
    discard staticExec(compilerPath & " -c --target=wasm32-unknown-unknown-wasm -o " &
            nimcache & "/librt.a -x c -", input = "\n")

export importwasm, exportwasm
