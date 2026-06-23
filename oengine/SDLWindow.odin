package oengine

import "core:fmt"
import "core:time"
import strs "core:strings"

import sdl "vendor:sdl2"
import "vendor:sdl2/ttf"
import "core:math"
import "core:thread"

sdl_create_window :: proc(#any_int w, h: i32, title: string) -> ^sdl.Window {
    if (sdl.WasInit(sdl.INIT_VIDEO | sdl.INIT_EVENTS) == {}) do sdl.Init(sdl.INIT_VIDEO | sdl.INIT_EVENTS);

    window := sdl.CreateWindow(
        strs.clone_to_cstring(title), 
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, w, h,
        nil
    );
    if (window == nil) {
        dbg_log(str_add("Failed to create sdl window: ", string(sdl.GetError())), DebugType.ERROR);
        return nil;
    }

    return window;
}

sdl_create_renderer :: proc(window: ^sdl.Window) -> ^sdl.Renderer {
    renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED);
    if (renderer == nil) {
        dbg_log(str_add("Failed to create sdl renderer: ", string(sdl.GetError())), DebugType.ERROR);
        return nil;
    }

    return renderer;
}

sdl_quit :: proc(running: ^bool) {
    running^ = false;
    sdl.VideoQuit();
    sdl.Quit();
}

sdl_window :: proc(window: ^sdl.Window, renderer: ^sdl.Renderer, update: proc(), render: proc(^sdl.Renderer, ^bool)) {
    running := true;

    loop: for (running) {
        if (update != nil) do update();

        event: sdl.Event;
        for (sdl.PollEvent(&event)) {
            #partial switch event.type {
                case .KEYDOWN:
                    #partial switch event.key.keysym.sym {
                        case .ESCAPE:
                            sdl_quit(&running);
                            break loop;
                }
                case .QUIT:
                    sdl_quit(&running);
                    break loop;
            }
        }

        if (render != nil) { render(renderer, &running); }
        else {
            sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255);
            sdl.RenderClear(renderer);
        }

        sdl.RenderPresent(renderer);
    }

    sdl.DestroyWindow(window);
    sdl.DestroyRenderer(renderer);
    sdl_quit(&running);
}

sdl_color :: proc(color: Color) -> sdl.Color {
    return sdl.Color {color.r, color.g, color.b, color.a};
}

sdl_rect :: proc(renderer: ^sdl.Renderer, rec: rl_Rectangle, color: Color) {
    rect := new(sdl.Rect);
    rect.x = i32(rec.x); rect.y = i32(rec.y); rect.w = i32(rec.width); rect.h = i32(rec.height);
    sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    sdl.RenderFillRect(renderer, rect);
}

sdl_draw_text :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, text: string, #any_int x, y, size: i32, color: Color) {
    text_surface := ttf.RenderText_Solid(font, strs.clone_to_cstring(text), sdl_color(color));
    defer sdl.FreeSurface(text_surface);
    text_tex := sdl.CreateTextureFromSurface(renderer, text_surface);
    defer sdl.DestroyTexture(text_tex);

    render_quad := sdl.Rect {x, y, text_surface.w * size, text_surface.h * size};
    sdl.RenderCopy(renderer, text_tex, nil, &render_quad);
}

sdL_text_center_pos :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, text: string, rec: rl_Rectangle) {
    ctext := strs.clone_to_cstring(text);
    width: i32;
    height: i32;
    ttf.SizeUTF8(font, ctext, &width, &height);
    text_scale := (rec.width - gui_bezel_size * 2) / f32(width);

    if (text_scale * gui_font_size > rec.height - gui_bezel_size * 2) {
        text_scale = (rec.height - gui_bezel_size * 2) / gui_font_size;
    }

    text_x := rec.x + (rec.width - f32(width)) / 2;
    text_y := rec.y + (rec.height - f32(height)) / 2;

    sdl_draw_text(
        renderer,
        font,
        text,
        i32(text_x), i32(text_y),
        math.round(text_scale),
        WHITE
    );
}

sdl_button :: proc(renderer: ^sdl.Renderer, text: string, font: ^ttf.Font, x, y, w, h: f32) -> bool {
    rec := rl_Rectangle {
        x = x,
        y = y,
        width = w,
        height = h,
    };

    mp := sdl_mouse_pos();
    pressed := rl_CheckCollisionPointRec(mp, rec) && sdl_mouse_released(sdl.BUTTON_LMASK);
    held := rl_CheckCollisionPointRec(mp, rec) && sdl_mouse_down(sdl.BUTTON_LMASK);

    sdl_rect(renderer, {rec.x - gui_bezel_size, rec.y - gui_bezel_size, rec.width + gui_bezel_size * 2, rec.height + gui_bezel_size * 2}, gui_darker_color);
    sdl_rect(renderer, {rec.x - gui_bezel_size, rec.y - gui_bezel_size, rec.width + gui_bezel_size, 
            rec.height + gui_bezel_size}, gui_lighter_color);

    if (!held) do sdl_rect(renderer, rec, gui_main_color);
    else do sdl_rect(renderer, rec, gui_accent_color);

    // sdl_draw_text(renderer, font, text, i32(rec.x), i32(rec.y), 1, WHITE);
    sdL_text_center_pos(renderer, font, text, rec);

    return pressed;

}

sdl_key_down :: proc(key: sdl.Scancode) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    return bool(kb_state[key]);
}

sdl_key_pressed :: proc(key: sdl.Scancode) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    @static prev_state: [sdl.NUM_SCANCODES]u8;
    curr_state := kb_state[key];

    if (curr_state == sdl.PRESSED && prev_state[key] == sdl.RELEASED) {
        prev_state[key] = curr_state;
        return true;
    }

    prev_state[key] = curr_state;
    return false;
}

sdl_mouse_down :: proc(#any_int button: u32) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    return bool(m_state & button);
}

sdl_mouse_pressed :: proc(#any_int button: u32) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    @static prev_state: [sdl.BUTTON_X2MASK + 1]u32;
    curr_state := m_state & button;

    if (curr_state == 1 && prev_state[button] == 0) {
        prev_state[button] = curr_state;
        return true;
    }

    prev_state[button] = curr_state;
    return false;
}

sdl_mouse_released :: proc(#any_int button: u32) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    @static prev_state: [sdl.BUTTON_X2MASK + 1]u32;
    curr_state := m_state & button;

    if (curr_state == 0 && prev_state[button] == 1) {
        prev_state[button] = curr_state;
        return true;
    }

    prev_state[button] = curr_state;
    return false;
}

sdl_mouse_pos :: proc() -> Vec2 {
    x, y: i32;
    sdl.GetMouseState(&x, &y);
    return Vec2 {f32(x), f32(y)};
}
