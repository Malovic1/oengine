package oengine

import "core:fmt"
import strs "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

GuiTextBox :: struct {
    text: string,
    active: bool,
    pos: int,
}

@(private)
gui_text_box_render :: proc(using self: ^GuiTextBox, x, y, w, h: f32, decorated: bool = true, standalone: bool = false, except: []char = {}, tint := WHITE) -> string {
    w_active := gui_active();
    if (!standalone) { 
        if (w_active != nil && !w_active.active) do return text;
    }
    
    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = w_active.x;
        ry = w_active.y;
    }

    rec := rl.Rectangle {
        x = rx + x,
        y = ry + y,
        width = w,
        height = h,
    };

    if (rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_pressed(Mouse.LEFT)) {
        active = !active;
    }

    text_scale := (rec.height - gui_bezel_size * 2) / gui_font_size;

    if (text_scale * gui_font_size > rec.width - gui_bezel_size * 2) {
        text_scale = (rec.width - gui_bezel_size * 2) / gui_font_size;
    }

    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;
    text_x := rec.x + 5;

    if (decorated) do gui_inverse_rec(rec.x, rec.y, rec.width, rec.height);
    else do rl.DrawRectangleLinesEx(rec, 1, tint);

    rl.BeginScissorMode(i32(rec.x), i32(rec.y), i32(rec.width), i32(rec.height));
   
    if (len(text) > 0) {
        text_len := rl.MeasureTextEx(
            gui_default_font, 
            to_cstr(text),
            gui_font_size * text_scale, 2
        ).x;

        symbol := []u8{text[(len(text) - 1) % len(text)]};

        char_len := rl.MeasureTextEx(
            gui_default_font, to_cstr(string(symbol)),
            gui_font_size, 2
        ).x;

        if (text_len > rec.width) {
            text_x -= text_len - rec.width + char_len + 5;
        }
    }

    rl.DrawTextEx(
        gui_default_font, 
        to_cstr(text), 
        {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, WHITE
    );

    if (active) {
        if (len(text) > 0) {
            char_len: f32;
            text_len := rl.MeasureTextEx(
                gui_default_font, 
                to_cstr(text),
                gui_font_size * text_scale, 2
            ).x;

            if (text_len != 0) {
                partial_text := text[:len(text) - pos];
                partial_width := rl.MeasureTextEx(
                    gui_default_font,
                    to_cstr(partial_text),
                    gui_font_size * text_scale,
                    2
                ).x;
                cur_x := text_x + partial_width;

                if (i32(gui_cursor_timer) % 2 == 0) {
                    rl.DrawTextEx(
                        gui_default_font, 
                        to_cstr(gui_cursor), 
                        {cur_x, text_y}, 
                        gui_font_size * text_scale, gui_text_spacing, WHITE
                    );
                }
            }
        } else {            
            if (i32(gui_cursor_timer) % 2 == 0) {
                rl.DrawTextEx(
                    gui_default_font, 
                    to_cstr(gui_cursor), 
                    {text_x, text_y}, 
                    gui_font_size * text_scale, gui_text_spacing, WHITE
                );
            }
        }
    }

    rl.EndScissorMode();

    MOVE_TIMER_MAX :: 0.75
    @static auto_move_timer: f32 = MOVE_TIMER_MAX;
    @static auto_move := false;

    if (active) {
        if (key_down(.LEFT_CONTROL) || key_down(.LEFT_SUPER)) {
            if (key_pressed(.V)) { 
                left := text[:len(text) - pos];
                copied := string(rl.GetClipboardText());
                right := text[len(text) - pos:];

                text = str_add({left, copied, right});
            }
            if (key_pressed(.C)) {
                rl.SetClipboardText(to_cstr(text));
            }
        }

        if (auto_move_timer <= 0) {
            auto_move = true;
        }

        if (!auto_move) {
            if (key_pressed(.RIGHT)) {
                if (pos > 0) do pos -= 1;
            }

            if (key_pressed(.LEFT)) {
                if (pos <= len(text) - 1) do pos += 1;
            }

            if (key_pressed(.BACKSPACE)) {
                if (len(text) > 0) {
                    if (pos != len(text)) {
                        text = str_add(text[:len(text) - pos - 1], text[len(text) - pos:]);
                    }
                }
            } else {
                key := []char{char_pressed()};
                if (key[0] >= 32 && key[0] <= 125 && !contains_ptr(&key[0], raw_data(except), len(except), char)) {
                    left := text[:len(text) - pos];
                    char_key := utf8.runes_to_string(key);
                    right := text[len(text) - pos:];

                    text = str_add({left, char_key, right});
                }
            }

            if (key_down(.RIGHT) || key_down(.LEFT) || key_down(.BACKSPACE)) {
                auto_move_timer -= delta_time();
            }

            if (key_up(.RIGHT) && key_up(.LEFT) && key_up(.BACKSPACE)) {
                auto_move_timer = MOVE_TIMER_MAX;
            }
        } else {
            if (key_down(.RIGHT)) {
                if (pos > 0) { pos -= int(100 * delta_time()); }
            } 

            if (key_down(.LEFT)) {
                if (pos <= len(text) - 1) { pos += int(100 * delta_time()); }
            }

            if (key_down(.BACKSPACE)) {
                if (len(text) > 0) {
                    if (pos != len(text)) {
                        text = str_add(text[:len(text) - pos - 1], text[len(text) - pos:]);
                    }
                }
            } else {
                key := []char{char_pressed()};
                if (key[0] >= 32 && key[0] <= 125 && !contains_ptr(&key[0], raw_data(except), len(except), char)) {
                    text = str_add(text, utf8.runes_to_string(key));
                }
            }

            if (key_released(.RIGHT) || key_released(.LEFT) || key_released(.BACKSPACE)) {
                auto_move_timer = MOVE_TIMER_MAX;
                auto_move = false;
            }
        }


        if (key_pressed(.HOME)) {
            pos = len(text);
        }

        if (key_pressed(.END)) {
            pos = 0;
        }

        

        if (!rl.CheckCollisionPointRec(window.mouse_position, rec) &&
            mouse_pressed(.LEFT)) { active = false; }

        if (key_pressed(.ESCAPE)) do active = false;
    }

    return text;
}

gui_text_box :: proc(tag: string, x, y, w, h: f32, decorated: bool = true, standalone: bool = false, except: []char = {}, text := "", tint := WHITE) -> string {
    if (!gui_text_box_exists(tag)) {
        instance := new(GuiTextBox);
        instance.text = text;
        instance.active = false;

        gui.text_boxes[tag] = instance;
    }

    inst := gui.text_boxes[tag];
    return gui_text_box_render(inst, x, y, w, h, decorated, standalone, except, tint);
}
