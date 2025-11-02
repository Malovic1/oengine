package main

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import mu "vendor:microui"
import oe "../../oengine"
import "core:mem"

main :: proc() {
    oe.OE_DEBUG = true;
    oe.PHYS_DEBUG = true;

    monitor := rl.GetCurrentMonitor();
    oe.w_create(oe.EDITOR_INSTANCE);
    rl.MaximizeWindow();
    oe.w_set_resolution(rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor));
    oe.w_set_title("oengine-editor");
    oe.w_set_target_fps(60);

    mu_ctx := init_scope();

    oe.ew_init(oe.vec3_y() * 50);

    camera := oe.cm_init({});
    mouse_locked := false;
    oe.ecs_world.camera = &camera;

    for (oe.w_tick()) {
        free_all(context.temp_allocator);
        oe.ew_update();

        if (oe.key_pressed(.ESCAPE)) {
            mouse_locked = !mouse_locked;
        }

        oe.cm_set_fps(&camera, 0.1, mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);
        oe.cm_update(&camera);

        // render
        oe.w_begin_render();
        rl.ClearBackground({50, 50, 50, 255});

        rl.BeginMode3D(camera.rl_matrix);
        rl.DrawGrid(10, 1);
        rl.EndMode3D();

        begin();

        if (mu.begin_window(mu_ctx, "Test", {10, 10, 100, 50})) {
            defer mu.end_window(mu_ctx);
            mu.label(mu_ctx, "hello world");
        }

        end();

        oe.w_end_render();

    }

    oe.w_close();
}
