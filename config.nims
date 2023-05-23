--d:release
--d:wasm
--d:useMalloc
--d:nimAllocPagesViaMalloc
--d:noSignalHandler
--d:nimPreviewFloatRoundtrip # Avoid using sprintf as it's not available in wasm

--os:linux
--cpu:i386
# --gc:orc
--mm:orc

--cc:clang
--nomain
--opt:size

--stackTrace:off

--exceptions:goto
--app:lib

--o:test.wasm

let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

switch("passC", "-m32")
switch("passL", "-m32")

switch("passC", "-I/usr/include") # Wouldn't compile without this :(
switch("passC", "-flto") # Important for code size!
switch("passC", "-O3") # Important for code size!

# gc-sections seems to not have any effect
var linkerOptions = "-nostdlib -Wl,--no-entry -Wl,--export-dynamic"

switch("clang.options.linker", linkerOptions)
switch("clang.cpp.options.linker", linkerOptions)
