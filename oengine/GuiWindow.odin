package oengine

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import strs "core:strings"

GuiWindow :: struct {
    id: u32,
    title: string,
    using rec: rl.Rectangle,
    dw, dh: f32,

    top_bar: rl.Rectangle,

    active, resizing, moving, can_exit: bool,

    _mouse_over: bool,
}

@(private)
gw_render :: proc(using self: ^GuiWindow) {
    if (!active) do return;

    exit := gui_interactive_rec(
        .EMPTY, 
        top_bar.x + top_bar.width - gui_exit_scale, 
        top_bar.y, 
        gui_exit_scale, 
        gui_exit_scale,
        mouse_pressed(.LEFT),
        false,
    ) && can_exit;

    if (mouse_down(.LEFT) && rl.CheckCollisionPointRec(window.mouse_position, top_bar) && !exit) {
        if (gui._active_window_id == 0 || gui._active_window_id == id) {
            moving = true;
        }
    }

    _mouse_over = rl.CheckCollisionPointRec(window.mouse_position, top_bar) ||
                rl.CheckCollisionPointRec(window.mouse_position, rec);

    if (moving) {
        gui._active_window_id = id;
        if (mouse_released(.LEFT)) {
            moving = false;
            gui._active_window_id = 0;
        }

        top_bar.x = window.mouse_position.x - top_bar.width * 0.5;
        top_bar.y = window.mouse_position.y - top_bar.height * 0.5;
    }

    x = top_bar.x;
    y = top_bar.y + top_bar.height;
    gui_plain_rec(top_bar.x, top_bar.y, top_bar.width, top_bar.height);
    gui_plain_rec(x, y, width, height);

    active = !gui_interactive_rec(
        .EXIT, 
        top_bar.x + top_bar.width - gui_exit_scale, 
        top_bar.y, gui_exit_scale, gui_exit_scale, mouse_pressed(.LEFT), false);

    if (gui_interactive_rec(
        .RESIZE,
        width - gui_exit_scale, height - gui_exit_scale,
        gui_exit_scale, gui_exit_scale,
        mouse_down(.LEFT), true)) {
        resizing = true;
    }

    if (resizing) {
        if (mouse_released(.LEFT)) do resizing = false;

        width = window.mouse_position.x - x + 7.5;
        height = window.mouse_position.y - y + 7.5;
        width = math.clamp(width, dw, 1000);
        height = math.clamp(height, dh, 1000);
    }

    top_bar.width = width;

    // title
    rl.DrawTextEx(
        gui_default_font, 
        to_cstr(title), 
        Vec2 {top_bar.x + 5, top_bar.y}, 
        24, gui_text_spacing, rl.WHITE
    );

    rl.BeginScissorMode(
        i32(x), i32(y), i32(width), i32(height)
    );
}

gui_begin :: proc(
    title: string, 
    x: f32 = 10, y: f32 = 10, w: f32 = 300, h: f32 = 200, 
    can_exit: bool = true, active: bool = true
) {
    if (!gui_window_exists(title)) {
        instance := new(GuiWindow);
        instance.id = u32(len(gui.windows)) + 1;
        instance.title = title;
        instance.x = x;
        instance.y = y;
        instance.width = w;
        instance.height = h;
        instance.dw = w;
        instance.dh = h;
        instance.active = active;
        instance.resizing = false;
        instance.moving = false;
        instance.can_exit = can_exit;

        instance.top_bar = rl.Rectangle {
            instance.x, instance.y, instance.width, gui_top_bar_height
        };

        gui.windows[title] = instance;
    }

    inst := gui_window(title);

    gui._active = inst.title;

    gw_render(inst);
}

gui_end :: proc() {
    rl.EndScissorMode();
    gui._active = "";
}
