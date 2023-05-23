import ../wasm

proc print_internal(s: cstring, sz: csize_t): void {.importwasm: "env.print".}

proc print(s: string) = print_internal(s, csize_t(s.len))

export print
