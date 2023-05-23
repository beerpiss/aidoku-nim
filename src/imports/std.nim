import ../wasm

type 
    Rid = cint

    Kind {.pure.} = enum
        Null, Int, Float, String, Bool, Array, Object, Date, Node, Unknown


proc copy(rid: Rid): Rid {.importwasm: "std".}
proc destroy(rid: Rid): void {.importwasm: "std".}
proc value_kind(rid: Rid): Kind {.importwasm: "std.typeof".}
proc print_internal(s: cstring, sz: csize_t): void {.importwasm: "env.print".}

proc create_null(): Rid {.importwasm: "std".}
proc create_array(): Rid {.importwasm: "std".}
proc create_object(): Rid {.importwasm: "std".}
proc create_string(s: cstring, len: csize_t): Rid {.importwasm: "std".}
proc create_bool(b: bool): Rid {.importwasm: "std".}
proc create_float(f: cdouble): Rid {.importwasm: "std".}
proc create_int(i: clong): Rid {.importwasm: "std".}
proc create_date(value: cdouble): Rid {.importwasm: "std".}

proc read_int(rid: Rid): cint {.importwasm: "std".}
proc read_float(rid: Rid): cdouble {.importwasm: "std".}
proc read_bool(rid: Rid): bool {.importwasm: "std".}

type
    ValueRef = ref object of RootObj
        id: Rid
        alive: bool

proc newValueRef(id: Rid): ValueRef = 
    result = ValueRef(id: id, alive: true)
proc kind(v: ValueRef): Kind = 
    result = value_kind(v.id)
proc isNil(v: ValueRef): bool = 
    result = v.kind == Kind.Null
proc print(s: string) = print_internal(s, csize_t(s.len))

proc readInt(v: ValueRef): int32 = 
    let valueKind = v.kind
    if valueKind == Kind.Int or valueKind == Kind.Float or valueKind == Kind.Bool or valueKind == Kind.String:
        result = read_int(v.id)
    else:
        raise newException(ValueError, "Value is not an integer, or cannot be converted to one")

proc readFloat(v: ValueRef): float64 = 
    let valueKind = v.kind
    if valueKind == Kind.Int or valueKind == Kind.Float or valueKind == Kind.String:
        result = read_float(v.id)
    else:
        raise newException(ValueError, "Value is not a float, or cannot be converted to one")

proc readBool(v: ValueRef): bool =
    let valueKind = v.kind
    if valueKind == Kind.Bool or valueKind == Kind.Int:
        result = read_bool(v.id)
    else:
        raise newException(ValueError, "Value is not a bool, or cannot be converted to one")


export Rid, newValueRef, kind, isNil, readInt, readFloat, readBool, print

