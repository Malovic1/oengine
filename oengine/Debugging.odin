package oengine

import "core:fmt"


DEBUG_COLORS := [3]ConsoleColor {
    green,
    yellow,
    red,
}

DEBUG_TYPE_NAMES := [4]string {
    "EMPTY", 
    "INFO",
    "WARNING",
    "ERROR",
}

DebugType :: enum {
    EMPTY, 
    INFO,
    WARNING,
    ERROR,
}

dbg_log :: proc {
    dbg_log_any,
    dbg_log_str,
}

dbg_logf :: proc(text: any, type: DebugType = .INFO) -> int {
    if (!dbg_use_oe()) do return 0;

    id := int(type);
    dbg_type := DEBUG_TYPE_NAMES[id];

    if (int(type) > 0) do fmt.printf(str_add({"[", DEBUG_COLORS[id - 1](dbg_type), "] "}));
    return fmt.printf("%v", text);
}

dbg_log_any :: proc(text: any, type: DebugType = .INFO) -> int {
    if (!dbg_use_oe()) do return 0;

    id := int(type);
    dbg_type := DEBUG_TYPE_NAMES[id];

    if (int(type) > 0) do fmt.printf(str_add({"[", DEBUG_COLORS[id - 1](dbg_type), "] "}));
    return fmt.println(text);
}

dbg_log_str :: proc(text: string, type: DebugType = .INFO) -> int {
    if (!dbg_use_oe()) do return 0;

    id := int(type);
    dbg_type := DEBUG_TYPE_NAMES[id];
    res := str_add({"[", DEBUG_COLORS[id - 1](dbg_type), "] ", text});
    return fmt.println(res);
}

dbg_use_oe :: proc() -> bool {
    return w_trace_log_type() == .USE_OENGINE || w_trace_log_type() == .USE_ALL;
}