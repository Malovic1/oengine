package oengine


import strs "core:strings"
import "core:fmt"
import "fa"

DC_TEXTBOX_SIZE :: 30

MAX_OTP_LINES :: 512
MAX_COMMANDS :: 32

dev_console: struct {
    _rec: rl_Rectangle,
    active: bool,
    _toggle_key: Key,
    command: string,
    output: fa.FixedArray(string, MAX_OTP_LINES),
    commands: fa.FixedMap(string, ConsoleCommand, MAX_COMMANDS),
    prev_input: string,
    offset: f32,
}

console_init :: proc() {
    using dev_console;
    _toggle_key = .GRAVE;
    output = fa.fixed_array(string, MAX_OTP_LINES);
    commands = fa.fixed_map(string, ConsoleCommand, MAX_COMMANDS);
    _rec = {0, -f32(w_render_height() / 2), f32(w_render_width()), f32(w_render_height() / 2)};

    console_register(new_command("listcmds", "List all available commands", list_cmds));
    console_register(new_command("help", "List all available commands", list_cmds));
    console_register(new_command("print", "Print text to console", print_command));
    console_register(new_command("dbg_info", "Shows debug information", debug_info));
    console_register(new_command("dbg_pos", "Sets debug info position", dbg_info_pos));
    console_register(new_command("dbg_clr", "Toggles debug colors", toggle_debug));
    console_register(new_command("set_fps", "Sets the target fps", set_fps));
    console_register(new_command("exit", "Exits the app", exit_cmd));
    console_register(new_command("clear", "Clears the console", clear_cmd));
    console_register(new_command("get_ent", "Get entity", ent_eval));
    console_register(new_command("list_ents", "Lists all entities", list_ents));
    console_register(new_command("cam_pos", "Gets main camera pos", get_cam_pos));
    console_register(new_command("add_car", "Adds a dummy car that tests joints", add_car_cmd));
}

console_register :: proc(s_command: ConsoleCommand) {
    using dev_console;    
    fa.map_set(&commands, s_command.name, s_command);
}

console_exec :: proc(command: string) {
    using dev_console;
    
    parts := strs.split(command, " ");
    name := strs.to_lower(parts[0]);
    args := len(parts) > 1 ? parts[1:] : {};

    v := fa.map_value(commands, name);
    if (v.action != nil) {
        v.action(args);
    } else {
        console_print(str_add({"Command: ", name, " doesn't exist"}));
    }

    prev_input = gui.text_boxes["CommandTextBox"].text;
    gui.text_boxes["CommandTextBox"].text = "";
}

console_print :: proc(str: string) {
    using dev_console;

    // id := 0;
    // res: string;
    // for i in 0..<len(str) {
    //     c := str[i];
    //     ci: u8;
    //     if (i != len(str) - 1) do ci = str[i + 1];
    //
    //     res = str_add(res, str[id:i]);
    //
    //     if (c == '\\' && ci == 'n') {
    //         append(&output, strs.clone(res));
    //         id = i + 2;
    //     }
    // }

    fa.append(&output, strs.clone(str));
}

console_update :: proc() {
    using dev_console;

    @static frame_counter: f32;
    @static animating: bool;

    if (key_pressed(_toggle_key)) {
        active = !active;

        if (active) {
            animating = true;
            _rec.y = -f32(w_render_height() / 2);
        }

        if (gui.text_boxes["CommandTextBox"] != nil) {
            gui.text_boxes["CommandTextBox"].active = active;
        } else {
            gui_text_box(
                "CommandTextBox", 0, 
                _rec.y + _rec.height - DC_TEXTBOX_SIZE, 
                _rec.width - DC_TEXTBOX_SIZE, DC_TEXTBOX_SIZE, decorated = false, standalone = true,
                except = []char{'`'}
            );
            gui.text_boxes["CommandTextBox"].active = active;
        }
    }

    if (animating) {
        frame_counter += rl_GetFrameTime();
        _rec.y = rl_EaseLinearNone(frame_counter, 0, f32(w_render_height() / 2), 0.1) - f32(w_render_height() / 2);

        if (frame_counter >= 0.1) {
            frame_counter = 0;
            animating = false;
        }

        // fmt.println(_rec.y, frame_counter);
    }

    if (active) {
        if (key_pressed(.ENTER)) {
            if (command != STR_EMPTY) {
                console_exec(command);
            }
        }

        if (key_pressed(.UP)) {
            gui.text_boxes["CommandTextBox"].text = prev_input;
        }
    }
}

console_render :: proc() {
    using dev_console;

    if (active) {
        rl_DrawRectangleRec(_rec, {125, 125, 125, 125});

        rl_BeginScissorMode(
            i32(_rec.x), i32(_rec.y), i32(_rec.width), i32(_rec.height - 40)
        );

        for i in 0..<output.len {
            line := output.data[i];
            y := (10 + f32(i) * 20) - offset;

            if (y + 18 >= _rec.height - 40) {
                offset += 18;
            }

            gui_text(line, 18, 10, y, standalone = true);
        }

        rl_EndScissorMode();

        command = gui_text_box(
            "CommandTextBox", 0, 
            _rec.y + _rec.height - DC_TEXTBOX_SIZE, 
            _rec.width - DC_TEXTBOX_SIZE, DC_TEXTBOX_SIZE, decorated = false, standalone = true,
            except = []char{'`'}
        );

        if (gui_button(
            ">", _rec.width - DC_TEXTBOX_SIZE, _rec.y + _rec.height - DC_TEXTBOX_SIZE, 
            DC_TEXTBOX_SIZE, DC_TEXTBOX_SIZE, standalone = true, decorated = false)) {
            if (command != STR_EMPTY) { 
                console_exec(command);
            }
        }
    }
}
