package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math/linalg"
import "core:math"

main :: proc() {
    rl.InitWindow(800, 600, "texture mapping");
    rl.SetTargetFPS(60);

    texture := rl.LoadTexture("albedo.png");
    points: [3]rl.Vector3;
    uvs: [3]rl.Vector2;
    point_count: i32;

    rl.rlDisableBackfaceCulling();
    for (!rl.WindowShouldClose()) {
        if (rl.IsMouseButtonPressed(.LEFT) && point_count < len(points)) {
            points[point_count].xy = rl.GetMousePosition();
            point_count += 1;

            if (point_count == 3) {
                uvs[0], uvs[1], uvs[2] = triangle_uvs(points[0], points[1], points[2]);
            }
        }

        if (rl.IsMouseButtonDown(.MIDDLE)) {
            delta := rl.GetMouseDelta();
            delta_uv := rl.Vector2{
                delta.x / f32(rl.GetScreenWidth()),
                delta.y / f32(rl.GetScreenHeight()),
            };
            for &uv in uvs {
                uv += delta_uv;
            }
        }

        mouse_pos := rl.GetMousePosition();
        @static dragging: bool;
        @static point_id: int;

        if (len(points) == 3) {
            for i in 0..<len(points) {
                point := points[i];
                if (rl.CheckCollisionPointCircle(mouse_pos, point.xy, 10)) {
                    if (rl.IsMouseButtonPressed(.LEFT)) {
                        dragging = true;
                        point_id = i;
                    }
                }
            }

            if (dragging) {
                points[point_id].xy = mouse_pos;
                if (rl.IsMouseButtonReleased(.LEFT)) {
                    dragging = false;
                }
            }
        }

        zoom_factor: f32 = 1.0;

        zoom_delta := -rl.GetMouseWheelMove(); // Scroll up/down

        if zoom_delta != 0.0 {
            mouse := rl.GetMousePosition();
            mouse_uv := rl.Vector2{
                mouse.x / f32(rl.GetScreenWidth()),
                1.0 - (mouse.y / f32(rl.GetScreenHeight())),
            };

            scale := 1.0 + zoom_delta * 0.1; // 10% zoom per scroll tick
            zoom_factor *= scale;

            for &uv in uvs {
                uv = mouse_uv + (uv - mouse_uv) * scale;
            }
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        for point in points {
            rl.DrawCircleV(point.xy, 10, rl.MAROON);
        }

        if (point_count == 3) {
            rl.rlBegin(rl.RL_TRIANGLES);
            rl.rlSetTexture(texture.id);
            rl.rlColor4ub(255, 255, 255, 255);

            rl.rlTexCoord2f(uvs[0].x, uvs[0].y); rl.rlVertex2f(points[0].x, points[0].y);
            rl.rlTexCoord2f(uvs[1].x, uvs[1].y); rl.rlVertex2f(points[1].x, points[1].y);
            rl.rlTexCoord2f(uvs[2].x, uvs[2].y); rl.rlVertex2f(points[2].x, points[2].y);

            rl.rlSetTexture(0);
            rl.rlEnd();
        } 

        rl.EndDrawing();
    }

    rl.CloseWindow();
}

triangle_uvs :: proc(v1, v2, v3: rl.Vector3, #any_int rotation_steps: i32 = 0) -> (rl.Vector2, rl.Vector2, rl.Vector2) {
    edge1 := v2 - v1;
    edge2 := v3 - v1;
    normal := linalg.cross(edge1, edge2);

    abs_normal := rl.Vector3 {
        math.abs(normal.x),
        math.abs(normal.y),
        math.abs(normal.z)
    };

    cp1, cp2, cp3: rl.Vector2;

    if (abs_normal.z >= abs_normal.x && abs_normal.z >= abs_normal.y) {
        // XY
        cp1 = v1.xy;
        cp2 = v2.xy;
        cp3 = v3.xy;
    } else if (abs_normal.x >= abs_normal.y && abs_normal.x >= abs_normal.z) {
        // YZ 
        cp1 = v1.zy;
        cp2 = v2.zy;
        cp3 = v3.zy;
    } else {
        // XZ 
        cp1 = v1.xz;
        cp2 = v2.xz;
        cp3 = v3.xz;
    }

    min_x := math.min(cp1.x, math.min(cp2.x, cp3.x));
    max_x := math.max(cp1.x, math.max(cp2.x, cp3.x));
    min_y := math.min(cp1.y, math.min(cp2.y, cp3.y));
    max_y := math.max(cp1.y, math.max(cp2.y, cp3.y));

    delta_x := max_x - min_x;
    delta_y := max_y - min_y;

    if (delta_x == 0) do delta_x = 1; 
    if (delta_y == 0) do delta_y = 1;

    uv1 := rl.Vector2 {
        (cp1.x - min_x) / delta_x,
        (cp1.y - min_y) / delta_y
    };

    uv2 := rl.Vector2 {
        (cp2.x - min_x) / delta_x,
        (cp2.y - min_y) / delta_y
    };

    uv3 := rl.Vector2 {
        (cp3.x - min_x) / delta_x,
        (cp3.y - min_y) / delta_y
    };

    rotate_uv := proc(uv: rl.Vector2, steps: i32) -> rl.Vector2 {
        s := steps % 4;
        if s == 1 {
            return {1.0 - uv.y, uv.x};
        } else if s == 2 {
            return {1.0 - uv.x, 1.0 - uv.y};
        } else if s == 3 {
            return {uv.y, 1.0 - uv.x};
        }
        return uv;
    };

    uv1 = rotate_uv(uv1, rotation_steps);
    uv2 = rotate_uv(uv2, rotation_steps);
    uv3 = rotate_uv(uv3, rotation_steps);

    return uv1, uv2, uv3;
}
