package object_data

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:reflect"
import "core:encoding/json"

types := [?]string {
    "i32",
    "f32",
    "string",
    "bool",
    "object",
};

Object :: map[string]ODType

json_to_od :: proc(object: json.Object) -> Object {
    res: Object;

    for k, v in object {
        #partial switch var in v {
            case json.Integer:
                res[k] = i32(var);
            case json.Float:
                res[k] = f32(var);
            case json.String:
                res[k] = var;
            case json.Boolean:
                res[k] = var;
            case json.Object:
                res[k] = json_to_od(var);
            case json.Array:
                res[k] = json_array_to_od(var);
        }
    }
    
    return res;
}

json_array_to_od :: proc(array: json.Array) -> Object {
    res: Object;

    i := 0;
    for value in array {
        key := str_add("v", i);

        #partial switch var in value {
            case json.Integer:
                res[key] = i32(var);
            case json.Float:
                res[key] = f32(var);
            case json.String:
                res[key] = var;
            case json.Boolean:
                res[key] = var;
            case json.Object:
                res[key] = json_to_od(var);
            case json.Array:
                res[key] = json_array_to_od(var);
        }

        i += 1;
    }

    return res;
}

target_type :: proc(obj: ODType, $T: typeid) -> T {
    #partial switch var in obj {
        case i32:
            return T(var);
        case f32:
            return T(var);
    }

    return T(0);
}

I32 :: i32
F32 :: f32
STRING :: string
BOOL :: bool

ODType :: union {
    i32,
    f32,
    string,
    bool,
    Object,
}

ObjectPair :: struct {
    obj: ^Object,
    name: string,
}

parse :: proc(data: string) -> Object {
    result: Object = make(Object);

    object_stack := make([dynamic]ObjectPair);
    append(&object_stack, ObjectPair{&result, "root"});

    _data, ok := strings.remove_all(data, "\r");
    lines := strings.split(_data, "\n");
    line_number := 0;
    for line in lines {
        if (line == "") { line_number += 1; continue; }

        if (strings.has_prefix(strings.trim_space(line), "object ")) {
            split := strings.split(strings.trim_space(line), " ");
            obj_name := split[1];
            _new := new(Object);

            append(&object_stack, ObjectPair{_new, obj_name});
            line_number += 1;
            continue;
        }

        if (strings.trim_space(line) == "}") {
            child := object_stack[len(object_stack) - 1];
            parent := object_stack[len(object_stack) - 2];

            parent.obj^[child.name] = child.obj^;

            pop(&object_stack);
            line_number += 1;
            continue;
        }

        line := strings.trim_space(line);
        if (line == "") { line_number += 1; continue; }
        split := split_line(line);

        type := split[0];
        field_name := split[1];
        value := split[3];

        if (type == "i32") {
            val, _ := strconv.parse_int(value);
            object_stack[len(object_stack) - 1].obj[field_name] = i32(val);
        }
        if (type == "f32") {
            val, _ := strconv.parse_f32(value);
            object_stack[len(object_stack) - 1].obj[field_name] = val;
        }
        if (type == "string") {
            val, _ := strings.remove_all(value, "\"");
            object_stack[len(object_stack) - 1].obj[field_name] = val;
        }
        if (type == "bool") {
            val, _ := strconv.parse_bool(value);
            object_stack[len(object_stack) - 1].obj[field_name] = val;
        }

        line_number += 1;
    }

    delete(object_stack);

    return result;
}

// i32 f32 string and bool are default values
// other is considered a struct or a union
marshal :: proc(data: any, type: typeid, name: string, indent: string = "") -> string {
    if (type == i32) {
        left := strings.concatenate({indent, "i32 ", name, " = "});
        return str_add(left, data); 
    } else if (type == f32) {
        left := strings.concatenate({indent, "f32 ", name, " = "});
        return str_add(left, data); 
    } else if (type == string) {
        left := strings.concatenate({indent, "string ", name, " = ", "\""});
        return strings.concatenate({str_add(left, data), "\""}); 
    } else if (type == bool) {
        left := strings.concatenate({indent, "bool ", name, " = "});
        return str_add(left, data); 
    }

    result := strings.concatenate({indent, "object ", name, " {\n"});
    _types := reflect.struct_field_types(type);
    names := reflect.struct_field_names(type);
    values := make([]string, len(names));
    for i in 0..<len(values) {
        values[i] = str_add(
            "", 
            reflect.struct_field_value_by_name(data, names[i])
        );
    }

    for i in 0..<len(values) {
        value := reflect.struct_field_value_by_name(data, names[i]);
        result = strings.concatenate(
            {result, 
            marshal(value, value.id, names[i], 
            strings.concatenate({indent, "    "})), "\n"}
        );
    }

    result = strings.concatenate({result, indent, "}"});
    return result;
}

split_line :: proc(line: string) -> []string {
    in_string := false;
    length := 1;
    for i in 0..<len(line) {
        c := rune(line[i]);
        if (c == '\"') { 
            in_string = !in_string;
            continue;
        }

        if (c == ' ' && !in_string) {
            length += 1;
        }
    }

    assert(!in_string, "[ERROR] quotes not closed on string definition");

    res := make([]string, length);
    res_i := 0;
    prev_i := -1;
    for i in 0..<len(line) {
        c := rune(line[i]);
        if (c == '\"') { 
            in_string = !in_string;
            continue;
        }

        if (c == ' ' && !in_string) {
            res[res_i] = line[prev_i + 1:i];
            res_i += 1;
            prev_i = i;
        }
    }

    res[res_i] = line[prev_i + 1:];

    return res;
}

str_add :: proc(buf: string, elem: $E, _fmt: string = "%v%.2f") -> string {
    type := typeid_of(type_of(elem));
    if (type == f32 || type == f64) {
        // return fmt.aprintf(fmt.aprint("%v", _fmt, sep = ""), buf, elem);
        return str_printf(_fmt, buf, elem);
    }

    // return fmt.aprintf("%v%v", buf, elem);
    return str_printf("%v%v", buf, elem);
}

str_printf :: proc(
    frmt: string, 
    args: ..any, 
    allocator := context.allocator, 
    newline := false) -> string {
	strb: strings.Builder;
    defer strings.builder_destroy(&strb);
	strings.builder_init(&strb, allocator);

    fmt.sbprintf(&strb, frmt, ..args, newline=newline);

    return strings.clone(strings.to_string(strb));
}

str_print :: proc(
    args: ..any, 
    sep := " ", 
    allocator := context.allocator) -> string {
	strb: strings.Builder;
	strings.builder_init(&strb, allocator);

	res := strings.clone(fmt.sbprint(&strb, ..args, sep=sep));

    strings.builder_destroy(&strb);

    return res;
}
