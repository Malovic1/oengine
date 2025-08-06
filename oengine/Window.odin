package oengine

import "core:os"
import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import str "core:strings"
import "core:mem"

EDITOR_INSTANCE :: "oengine-editor"

window: struct {
    _width, _height: i32,
    _render_width, _render_height: i32,

    _title: string,

    _config_flags: rl.ConfigFlags,
    _trace_log_type: TraceLogType,
    _trace_log_level: rl.TraceLogLevel,

    _exit_key: Key,

    _target_fps: i32,
    _dbg_stats_pos: i32,

    _exe_path: string,

    mouse_position: Vec2, // mouse position relative to screen not world

    debug_stats: bool,

    target: rl.RenderTexture,
    instance_name: string,
    custom_update: proc(dt: f32),
}

w_create :: proc(name: string = "Game") {
    using window;

    _width = 800;
    _height = 600;
    _render_width = 800;
    _render_height = 600;

    _title = "oengine window";

    _config_flags = {rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.MSAA_4X_HINT};
    w_set_trace_log_type(.USE_OENGINE);
    dbg_log(str_add("Detected os: ", OSTypeStr[int(sys_os())]));
    dbg_logf("Set config flags: ");
    dbg_log(window._config_flags, .EMPTY);

    _exit_key = Key.KEY_NULL;

    _target_fps = 60;

    mouse_position = vec2_zero();

    debug_stats = false;

    rl.SetConfigFlags(_config_flags);
    rl.SetTraceLogLevel(_trace_log_level);
    rl.InitWindow(_width, _height, str.clone_to_cstring(_title));
    if (rl.IsWindowReady()) do dbg_log("Initalized window");
    else do dbg_log("Failed to initialize window", .ERROR);
    exit_key(_exit_key);
    dbg_log(str_add("Set exit key to: ", _exit_key));
    rl.SetTargetFPS(_target_fps);
    rl.InitAudioDevice();
    if (rl.IsAudioDeviceReady()) do dbg_log("Initalized audio device");
    else do dbg_log("Failed to initialize audio device", .ERROR);

    target = rl.LoadRenderTexture(_render_width, _render_height);

    if (target.texture.width <= 0 || target.texture.height <= 0) {
        dbg_log("Failed to load render target, width or height is <= 0", .ERROR);
        return;
    }

    if (rl.IsRenderTextureReady(target)) {
        dbg_log("Loaded render target");
    }

    gui_default_font = rl.LoadFont(str.clone_to_cstring(str_add(OE_FONTS_PATH, "default_font.ttf")));
    gui_font_size = f32(gui_default_font.baseSize);
    w_set_instance_name(name);

    console_init();

    checkered_image = load_texture(rl.LoadTextureFromImage(rl.GenImageChecked(4, 4, 1, 1, WHITE, BLACK)));

    rl.SetWindowIcon(rl.LoadImageFromTexture(get_tex_from_data(LOGO_WIDTH, LOGO_HEIGHT, raw_data(hex_to_rgb_img(logo[:])))));
    dbg_log("Set window icon");

    DEFAULT_MATERIAL = rl.LoadMaterialDefault();
    dbg_log("Loaded default material");
}

w_set_instance_name :: proc(name: string) {
    window.instance_name = name;
    dbg_log(str_add("Set instance name to: ", window.instance_name));
}

w_trace_log_type :: proc() -> TraceLogType {
    return window._trace_log_type;
}

w_set_trace_log_type :: proc(type: TraceLogType) {
    window._trace_log_type = type;

    if (window._trace_log_type == .USE_OENGINE) {
        dbg_log(str_add({"Set trace log type to: ", TRACE_NAMES[int(type)]}));
        w_set_trace_log_level(rl.TraceLogLevel.NONE);
        return;
    }

    w_set_trace_log_level(rl.TraceLogLevel.ALL);

    dbg_log(str_add({"Set trace log type to: ", DEBUG_TYPE_NAMES[int(type)]}));
}

delta_time :: proc() -> f32 {
    return rl.GetFrameTime();
}

w_render_aspect :: proc() -> f32 {
    return f32(w_render_width()) / f32(w_render_height());
}

w_render_width :: proc() -> i32 {
    return window._render_width;
}

w_set_render_width :: proc(w: i32) {
    window._render_width = w;
    w_reload_target();
    dbg_log(str_add("Set render width: ", window._render_width));
}

w_render_height :: proc() -> i32 {
    return window._render_height;
}

w_set_render_height :: proc(h: i32) {
    window._render_height = h;
    w_reload_target();
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_set_resolution :: proc(w, h: i32) {
    window._render_width = w;
    window._render_height = h;

    w_reload_target();
    dbg_log(str_add("Set render width: ", window._render_width));
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_width :: proc() -> i32 {
    return window._width;
}

w_set_width :: proc(w: i32) {
    window._width = w;
    w_reload_window();
    dbg_log(str_add("Set render width: ", window._render_width));
}

w_height :: proc() -> i32 {
    return window._height;
}

w_set_height :: proc(h: i32) {
    window._height = h;
    w_reload_window();
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_set_size :: proc(w, h: i32) {
    window._width = w;
    window._height = h;

    w_reload_window();
    dbg_log(str_add("Set render width: ", window._render_width));
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_config_flags :: proc() -> rl.ConfigFlags {
    return window._config_flags;
}

w_set_config_flags :: proc(flags: rl.ConfigFlags) {
    window._config_flags = flags;
    rl.SetConfigFlags(window._config_flags);
    dbg_logf("Set config flags: ");
    dbg_log(window._config_flags, .EMPTY);
}

w_trace_log_level :: proc() -> rl.TraceLogLevel {
    return window._trace_log_level;
}

w_set_trace_log_level :: proc(level: rl.TraceLogLevel) {
    window._trace_log_level = level;
    rl.SetTraceLogLevel(window._trace_log_level);
    dbg_logf("Set trace log level to: ");
    dbg_log(window._trace_log_level, .EMPTY);
}

w_title :: proc() -> string {
    return window._title;
}

w_set_title :: proc(t: string) {
    window._title = t;
    rl.SetWindowTitle(str.clone_to_cstring(window._title));
    dbg_log(str_add({"Set title to: ", window._title}));
}

w_exit_key :: proc() -> Key {
    return window._exit_key;
}

w_set_exit_key :: proc(key: Key) {
    window._exit_key = key;
    exit_key(window._exit_key);
    dbg_log(str_add("Set exit key to: ", window._exit_key));
}

w_target_fps :: proc() -> i32 {
    return window._target_fps;
}

w_set_target_fps :: proc(fps: i32) {
    window._target_fps = fps;
    rl.SetTargetFPS(window._target_fps);
    dbg_log(str_add("Set target fps to: ", window._target_fps));
}

w_tick :: proc() -> bool {
    using window;

    if (rl.IsWindowResized()) {
        _width = rl.GetScreenWidth();
        _height = rl.GetScreenHeight();
    }
    
    mouse_position.x = f32(rl.GetMouseX()) * (f32(_render_width) / f32(_width));
    mouse_position.y = f32(rl.GetMouseY()) * (f32(_render_height) / f32(_height));

    gui_cursor_timer += rl.GetFrameTime() * 2;

    console_update();

    return !rl.WindowShouldClose();
}

w_begin_render :: proc() {
    rl.BeginTextureMode(window.target);
}

DBG_INFO_STAT_COUNT :: 9
DBG_INFO_POS_COUNT :: 5

w_end_render :: proc() {
    using window;
 
    console_render();

    if (debug_stats) {
        OFFSET :: 20

        text_height := rl.MeasureTextEx(rl.GetFontDefault(), "A", 16.0, 0.5).y;

        dbg_stat_pos := [DBG_INFO_POS_COUNT]Vec2i {
            Vec2i {10, 10},
            Vec2i {
                10, 
                window._render_height / 2 - OFFSET * i32(math.round_f32(DBG_INFO_STAT_COUNT * 0.5)) - i32(text_height) - 10
            },
            Vec2i {10, window._render_height - OFFSET * DBG_INFO_STAT_COUNT - i32(text_height) - 10},
            Vec2i {
                window._render_width / 2 - OFFSET * i32(math.round_f32(DBG_INFO_STAT_COUNT * 0.5)) - 10,
                window._render_height - OFFSET * DBG_INFO_STAT_COUNT - i32(text_height) - 10,
            },
            Vec2i {
                window._render_width / 2 - OFFSET * i32(math.round_f32(DBG_INFO_STAT_COUNT * 0.5)) - 10,
                10
            },
        };

        top_left := dbg_stat_pos[_dbg_stats_pos];

        current_allocator := context.temp_allocator;
        text_info := [?]string {
            str_add("fps: ", rl.GetFPS(), allocator = current_allocator),
            str_add("dt: ", rl.GetFrameTime(), "%v%.5f", allocator = current_allocator),
            str_add("time: ", rl.GetTime(), "%v%.5f", allocator = current_allocator),
            str_add("ents: ", ecs_world.ecs_ctx.entities.len, allocator = current_allocator),
            str_add("sys_updts: ", ecs_world.ecs_ctx._update_systems.len, allocator = current_allocator),
            str_add("sys_rndrs: ", ecs_world.ecs_ctx._render_systems.len, allocator = current_allocator),
            str_add("rbs: ", ecs_world.physics.bodies.len, allocator = current_allocator),
            str_add("tris: ", tri_count, allocator = current_allocator),
            str_add("decals: ", len(ecs_world.decals), allocator = current_allocator),
            str_add("lights: ", ecs_world.ray_ctx.light_count, allocator = current_allocator),
        };

        for i in 0..<len(text_info) {
            c_str := str.clone_to_cstring(text_info[i], allocator = current_allocator);
            rl.DrawText(
                c_str, top_left.x, top_left.y + OFFSET * i32(i), 16, YELLOW
            );
        }
    }

    rl.EndTextureMode();
    
    rl.BeginDrawing();
    
    rl.DrawTexturePro(target.texture, {0, 0, f32(target.texture.width), f32(-target.texture.height)}, 
        {0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}, vec2_zero(), 0, rl.WHITE);
    
    rl.EndDrawing();
}

w_close :: proc() {
    delete(gui.windows);

    dbg_log(" ");
    dbg_log("Closing...");

    ew_deinit();

    rl.CloseAudioDevice();
    dbg_log("Closed audio device");

    rl.CloseWindow();
    dbg_log("Closed window");

    free_all(context.temp_allocator);
    free_all(context.allocator);
    dbg_log("Freed all allocators");
}

w_pos :: proc() -> Vec2 {
    if (sys_os() == .Windows) do return rl.GetWindowPosition();

    return vec2_zero();
}

@(private = "file")
prev_w_pos := w_pos();

w_transform_changed :: proc() -> bool {
    if (w_pos() != prev_w_pos) {
        prev_w_pos = w_pos();
        return true;
    }

    return rl.IsWindowResized();
}

@(private)
w_reload_target :: proc() {
    window.target = rl.LoadRenderTexture(window._render_width, window._render_height);
    dev_console._rec = {0, -f32(w_render_height() / 2), f32(w_render_width()), f32(w_render_height() / 2)};
}

@(private = "file")
w_reload_window :: proc() {
    rl.SetWindowSize(window._width, window._height);
}

engine_run :: proc(
    width: i32 = 800, height: i32 = 600,
    render_width: i32 = 800, render_height: i32 = 600,
    title: string = "oengine",
    config_flags: rl.ConfigFlags = {.WINDOW_RESIZABLE, .MSAA_4X_HINT},
    trace_log_type: TraceLogType = .USE_OENGINE,
    trace_log_level: rl.TraceLogLevel = .NONE,
    exit_key: Key = .KEY_NULL,
    fps: i32 = 60,
    debug_stats: bool = false,
    instance_name: string = "Game",
    init: proc() = nil,
    update: proc() = nil,
    fixed_update: proc(dt: f32) = nil,
    render: proc() = proc() { rl.ClearBackground(BLACK); },
    render_ui: proc() = nil,
    deinit: proc() = nil,
    shader: Shader = {},
    use_shader: bool = false,
    track_leaks: bool = false,
    leak_key: Key = Key.F4,
) {
    w_create(instance_name);
    w_set_size(width, height);
    w_set_resolution(render_width, render_height);
    w_set_title(title);
    w_set_config_flags(config_flags);
    w_set_trace_log_type(trace_log_type);
    w_set_trace_log_level(trace_log_level);
    w_set_exit_key(exit_key);
    w_set_target_fps(fps);
    window.debug_stats = debug_stats;
    window.custom_update = fixed_update;

    if (init != nil) { init(); }

    track_allocator: mem.Tracking_Allocator;

    if (track_leaks) {
        def_allocator := context.allocator;
        track_allocator: mem.Tracking_Allocator;
        mem.tracking_allocator_init(&track_allocator, def_allocator);
        context.allocator = mem.tracking_allocator(&track_allocator);
    }

    reset_track_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
        err := false;

        for _, value in a.allocation_map {
            fmt.printf("%v: allocated %v bytes\n", value.location, value.size);
            err = true;
        }

        mem.tracking_allocator_clear(a);
        return err;
    }

    for (w_tick()) {
        free_all(context.temp_allocator);
        mem.tracking_allocator_clear(&track_allocator);
        if (update != nil) { update(); }

        if (use_shader) { rl.BeginShaderMode(shader); }
        w_begin_render();
        if (render != nil) { render(); }
        w_end_render();
        if (use_shader) { rl.EndShaderMode(); }

        if (render_ui != nil) { render_ui(); }

        if (track_leaks) {
            if (key_pressed(leak_key)) { 
                reset_track_allocator(&track_allocator); 
            }
        }
    }

    if (deinit != nil) { deinit(); }
    w_close();
}
