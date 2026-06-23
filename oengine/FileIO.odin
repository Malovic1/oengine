package oengine

import "core:fmt"
import "core:os"
import "core:unicode"
import "core:unicode/tools"
import "core:unicode/utf8"
import "core:unicode/utf16"
import strs "core:strings"


/* simple example

file := oe.file_handle("../assets/test.od");
oe.file_write(file, "WRITTEN THIS:0");

data := oe.file_to_string_arr("../assets/test.od");

for line in data {
    fmt.println(line);
}

*/

File :: struct {
    handle: os.Handle,
    size: u32,
}

file_to_string_arr :: proc(path: string) -> []string {
    data, ok := os.read_entire_file(path);
    if (!ok) {
        dbg_log(str_add({"Failed to read file ", path}), .WARNING);
        return {};
    }
    defer delete(data);

    str_data, ok2 := strs.split_lines(strs.clone(string(data)));
    return str_data;
}

FileMode :: enum {
    READ_DONLY      = 0x00000,
    WRITE_RONLY     = 0x00001,
    READ_AND_WRITE  = 0x00002,
    CREATE          = 0x00040,
    EXCL            = 0x00080,
    NOCTTY          = 0x00100,
    TRUNC           = 0x00200,
    NONBLOCK        = 0x00800,
    APPEND          = 0x00400,
    SYNC            = 0x01000,
    ASYNC           = 0x02000,
    CLOEXEC         = 0x80000,
}

file_handle :: proc(path: string, mode: FileMode = .READ_AND_WRITE | .CREATE) -> File {
    handle, ok := os.open(path, int(mode), 0o666);
    if (ok != 0) {
        dbg_log(str_add({"Failed to open file ", path}), .WARNING);
        return {};
    }
    
    return File {
        handle = handle,
        size = u32(len(file_to_string_arr(path))),
    };
}

create_dir :: proc(path: string) {
    os.make_directory(path);
}

file_name :: proc(path: string) -> string {
    return strs.clone_from_cstring(rl_GetFileName(strs.clone_to_cstring(path)));
}

get_files :: proc(path: string) -> [dynamic]string {
    list := rl_LoadDirectoryFiles(strs.clone_to_cstring(path));
    
    res := make([dynamic]string);
    for i in 0..<int(list.count) {
        append(&res, strs.clone_from_cstring(list.paths[i]));
    }

    return res;
}

file_write :: proc(file: File, text: string) {
    n, err := os.write_string(file.handle, str_add({"\n", strs.clone(text)}));

    if (err != 0) {
        dbg_log(str_add("Failed to write to file: ", err), .WARNING);
    }
}

file_close :: proc(file: File) {
    err := os.close(file.handle);

    if (err != 0) {
        dbg_log(str_add("Failed to close file: ", err), .WARNING);
    }
}
