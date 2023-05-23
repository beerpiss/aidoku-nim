proc print(message: cstring, len: csize_t) {.importc: "print",
        codegenDecl: "__attribute__((import_module(\"env\"))) __attribute__((import_name(\"print\"))) $# $#$#".}

{.push stackTrace: off, profiler: off.}

# I would like to properly call Aidoku's `env.abort`, but that requires allocation
# which is considered a side effect so this will sadly have to suffice.
proc rawoutput(s: string) = print(("[ERROR] " & s).cstring, csize_t(s.len + 8))

{.push used.}
proc panic(s: string) =
    rawoutput(s)
    asm """
        unreachable
    """
{.pop.}

{.pop.}
