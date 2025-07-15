package oengine

import rl "vendor:raylib"
import strs "core:strings"
import "core:fmt"

/*
gui example

oe.gui_begin("test window");
rect := oe.gui_rect(oe.gui_window("test window"));

tr := oe.gui_grid(0, 0, 30, rect.width * 0.5);
oe.gui_text("Hello world!", 20, tr.x, tr.y);

tir := oe.gui_grid(1, 0, 30, rect.width * 0.5);
@static tick: bool;
tick = oe.gui_tick(tick, tir.x, tir.y, 20, 20, text = "Demo");

tir2 := oe.gui_grid(2, 0, 30, rect.width * 0.5);
@static tick2: bool;
tick2 = oe.gui_tick(tick2, tir2.x, tir2.y, 20, 20, text = "Another demo");

br := oe.gui_grid(3, 0, 30, rect.width * 0.5);
@static counter: i32;
if (oe.gui_button("Button", br.x, br.y, br.width, br.height)) {
    counter += 1;
}

tr2 := oe.gui_grid(3, 1, 30, rect.width * 0.5);
oe.gui_text(oe.str_add("counter = ", counter), 20, tr2.x, tr2.y);

oe.gui_end();

*/

gui_main_color := Color {99, 141, 160, 255};
gui_accent_color := Color {63, 105, 135, 255};
gui_darker_color := Color {41, 59, 68, 255};
gui_lighter_color := Color {119, 169, 191, 255};
gui_slider_color := rl.WHITE;

gui_font_size: f32 = 16;
gui_bezel_size: f32 = 2.5;
gui_text_spacing: f32 = 2;
gui_top_bar_height: f32 = 30;
gui_exit_scale: f32 = 25;

gui_default_font: rl.Font;

gui_cursor := "|";
@private gui_cursor_timer: f32;

gui: struct {
    windows: map[string]^GuiWindow,
    text_boxes: map[string]^GuiTextBox,
    _active: string,
    _active_window_id: u32,
}

GuiRect :: Rect

gui_grid :: proc(
    row, column: i32,
    row_height: f32 = 30, column_width: f32 = 150,
    padding: f32 = 5
) -> GuiRect {
    return {
        x = f32(column) * column_width + padding,
        y = f32(row) * row_height + padding,
        width = column_width - padding,
        height = row_height - padding,
    };
}

gui_window_exists :: proc(title: string) -> bool {
    return gui.windows[title] != nil;
}

gui_text_box_exists :: proc(tag: string) -> bool {
    return gui.text_boxes[tag] != nil;
}

gui_active :: proc() -> ^GuiWindow {
    return gui.windows[gui._active];
}

gui_window :: proc(title: string) -> ^GuiWindow {
    return gui.windows[title];
}

gui_rect :: proc(w: ^GuiWindow) -> GuiRect {
    return {
        w.x, w.y, w.width, w.height
    };
}

gui_set_window_active :: proc(title: string) {
    gui.windows[title].active = true;
}

gui_toggle_window :: proc(title: string) {
    gui.windows[title].active = !gui.windows[title].active;
}

gui_set_window_unactive :: proc(title: string) {
    gui.windows[title].active = false;
}

gui_mouse_over :: proc() -> bool {
    for t, w in gui.windows {
        if (w._mouse_over) do return true;
    }

    return false;
}

gui_text_active :: proc() -> bool {
    for k, t in gui.text_boxes {
        if (t.active) do return true;
    }

    return false;
}

gui_text :: proc(text: string, size: f32, x: f32 = 10, y: f32 = 10, standalone: bool = false, color := rl.WHITE) {
    active := gui_active();
    if (active != nil && !active.active && !standalone) do return;

    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = active.x;
        ry = active.y;
    }

    text := to_cstr(text);
    rl.DrawTextEx(
        gui_default_font, 
        text, 
        Vec2 {rx + x, ry + y}, 
        size, gui_text_spacing, color
    );
    // delete(text);
}

GuiTextPositioning :: enum i32 {
    CENTER,
    LEFT,
    RIGHT,
}

text_pos_renders := [?]proc(string, rl.Rectangle) {
    text_center_pos,
    text_left_pos,
    text_right_pos,
};

text_center_pos :: proc(text: string, rec: rl.Rectangle) {
    ctext := to_cstr(text);
    text_scale := (rec.width - gui_bezel_size * 2) / f32(rl.MeasureText(ctext, i32(gui_font_size)));

    if (text_scale * gui_font_size > rec.height - gui_bezel_size * 2) {
        text_scale = (rec.height - gui_bezel_size * 2) / gui_font_size;
    }

    text_x := rec.x + (rec.width - f32(rl.MeasureText(ctext, i32(gui_font_size * text_scale)))) / 2;
    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;

    rl.DrawTextEx(
        gui_default_font, 
        ctext, 
        Vec2 {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, rl.WHITE
    );
}

text_left_pos :: proc(text: string, rec: rl.Rectangle) {
    ctext := to_cstr(text);
    text_scale := (rec.height - gui_bezel_size * 2) / gui_font_size;

    if (text_scale * gui_font_size > rec.width - gui_bezel_size * 2.0) {
        text_scale = (rec.width - gui_bezel_size * 2.0) / gui_font_size;
    }

    text_x := rec.x + gui_bezel_size;
    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;

    rl.DrawTextEx(
        gui_default_font, 
        ctext, 
        Vec2 {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, rl.WHITE
    );
}

text_right_pos :: proc(text: string, rec: rl.Rectangle) {
    ctext := to_cstr(text);
    text_scale := (rec.height - gui_bezel_size * 2) / gui_font_size;

    if (text_scale * gui_font_size > rec.width - gui_bezel_size * 2.0) {
        text_scale = (rec.width - gui_bezel_size * 2.0) / gui_font_size;
    }

    text_x := rec.x + rec.width - gui_bezel_size * 2 - f32(rl.MeasureText(ctext, i32(gui_font_size * text_scale)));
    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;

    rl.DrawTextEx(
        gui_default_font, 
        ctext, 
        Vec2 {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, rl.WHITE
    );
}

gui_button :: proc(text: string, x: f32 = 10, y: f32 = 10, w: f32 = 50, h: f32 = 25, 
    text_pos: GuiTextPositioning = .CENTER, standalone: bool = false, decorated: bool = true,
    texture: Texture = {path = "empty"}) -> bool {
    active := gui_active();
    if (active != nil && !active.active && !standalone) do return false;

    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = active.x;
        ry = active.y;
    }

    rec := rl.Rectangle {
        x = rx + x,
        y = ry + y,
        width = w,
        height = h,
    };

    pressed := rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_released(.LEFT);
    held := rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_down(.LEFT);

    if (texture.path == "empty") {
        if (decorated) {
            rl.DrawRectangle(i32(rec.x - gui_bezel_size), i32(rec.y - gui_bezel_size), i32(rec.width + gui_bezel_size * 2),
                    i32(rec.height + gui_bezel_size * 2), gui_darker_color);
            rl.DrawRectangle(i32(rec.x - gui_bezel_size), i32(rec.y - gui_bezel_size), i32(rec.width + gui_bezel_size), 
                    i32(rec.height + gui_bezel_size), gui_lighter_color);

            if (!held) do rl.DrawRectangleRec(rec, gui_main_color);
            else do rl.DrawRectangleRec(rec, gui_accent_color);
        } else {
            rl.DrawRectangleLinesEx(rec, 1, WHITE);
        }

        text_pos_renders[text_pos](text, rec);
    } else {
        rl.DrawTexturePro(
            texture, {0, 0, f32(texture.width), f32(texture.height)},
            rec, {0, 0}, 0, WHITE
        );
    }

    return pressed;
}

gui_plain_rec :: proc(x, y, width, height: f32) {
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size * 2),
        i32(height + gui_bezel_size * 2), gui_darker_color);
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size), i32(height + gui_bezel_size),
        gui_lighter_color);
    rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), gui_main_color);
}

gui_inverse_rec :: proc(x, y, width, height: f32) {
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size * 2),
        i32(height + gui_bezel_size * 2), gui_lighter_color);
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size), i32(height + gui_bezel_size),
        gui_darker_color);
    rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), gui_main_color);
}

gui_interactive_rec :: proc(icon: GuiIcon, x, y, w, h: f32, press_mode: bool, w_move: bool) -> bool {
    rec := rl.Rectangle {x, y, w, h};

    if (w_move) {
        active := gui_active();
        rec.x = x + active.x;
        rec.y = y + active.y;
    }

    pressed := rl.CheckCollisionPointRec(window.mouse_position, rec) && press_mode;

    gui_icon(icon, i32(rec.x), i32(rec.y), i32(rec.width), i32(rec.height));

    return pressed;
}

GuiIcon :: enum {
    EMPTY,
    EXIT,
    FILE,
    RESIZE,
    TICK,
}

GuiIconRenders := [?]proc(x, y, w, h: i32) {
    proc(x, y, w, h: i32) {}, // empty
    exit_icon,
    file_icon,
    resize_icon,
    tick_icon,
}

@(private = "file")
exit_icon :: proc(x, y, w, h: i32) {
    rl.DrawLine(x, y, x + w, y + h, rl.WHITE);
    rl.DrawLine(x, y + h, x + w, y, rl.WHITE);
}

@(private = "file")
file_icon :: proc(x, y, w, h: i32) {
    rl.DrawLine(x, y + h, x + w, y + h, rl.WHITE);
    rl.DrawLine(x + w, y + h, x + w, y, rl.WHITE);
    rl.DrawLine(x, y, x + w, y, rl.WHITE);
    rl.DrawLine(x, y, x, y + h, rl.WHITE);
}

@(private = "file")
resize_icon :: proc(x, y, w, h: i32) {
    rl.DrawLine(x, y + h, x + w, y, rl.WHITE);
    rl.DrawLine(x + w/2, y + h, x + w, y + h/2, rl.WHITE);
}

@(private = "file")
tick_icon :: proc(x, y, w, h: i32) {
    fx := f32(x);
    fy := f32(y);
    fw := f32(w);
    fh := f32(h);

    rl.DrawLineEx(
        {fx, fy + fh * 0.5},
        {fx + fw * 0.3, fy + fh},
        3,
        WHITE
    );

    rl.DrawLineEx(
        {fx + fw * 0.3, fy + fh},
        {fx + fw, fy},
        3,
        WHITE
    );
}

gui_icon :: proc(icon: GuiIcon, x, y, w, h: i32) {
    GuiIconRenders[i32(icon)](x, y, w, h);
}

gui_tick :: proc(
    tick: bool, 
    x, y, w, h: f32,
    text: string = STR_EMPTY,
    text_size: f32 = 20,
    standalone: bool = false,
    decorated: bool = true) -> bool {
    active := gui_active();
    if (active != nil && !active.active && !standalone) do return false;

    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = active.x;
        ry = active.y;
    }

    rp := Vec2 {x + rx, y + ry};

    if (decorated) {
        gui_inverse_rec(rp.x, rp.y, w, h);
    } else {
        rl.DrawRectangleLinesEx({rp.x, rp.y, w, h}, 1, WHITE);
    }

    res := tick

    rec := rl.Rectangle {rp.x, rp.y, w, h};
    if (rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_pressed(.LEFT)) {
        res = !res;
    }

    if (tick) do gui_icon(.TICK, i32(rp.x), i32(rp.y), i32(w), i32(h));

    gui_text(text, text_size, rp.x + w + 10, rp.y, standalone = true);

    return res;
}
