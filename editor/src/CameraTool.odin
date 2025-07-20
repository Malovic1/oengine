package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"
import "../../oengine/fa"
import "core:math"
import "core:math/linalg"
import "core:strconv"

GRID_SPACING :: 25
GRID_COLOR :: oe.Color {255, 255, 255, 125}
RENDER_SCALAR :: 25
POINT_SIZE :: 5
ACTIVE_EMPTY :: -1

CameraMode :: enum {
    PERSPECTIVE = 0,
    ORTHO_XY,
    ORTHO_XZ,
    ORTHO_ZY
}

EditMode :: enum {
    XY,
    XZ,
    ZY,
}

ShapeMode :: enum {
    TRIANGLE,
    QUAD,
    CIRCLE,
    MAX,
}

shape_mode_size := [ShapeMode.MAX]i32{3, 4, 2};

CameraTool :: struct {
    camera_perspective: oe.Camera,
    mouse_locked: bool,
    camera_orthographic: rl.Camera2D,
    mode: CameraMode,
    edit_mode: bit_set[EditMode],
    edit_layer: [3]f32,
    active_axis: EditMode,
    points_to_add: [dynamic]oe.Vec3,
    shape_mode: ShapeMode,
    tile_edit: bool,
    tile_layer: f32,
    tile_size: oe.Vec3,

    _mouse_pos: oe.Vec2,
    _prev_mouse_pos: oe.Vec2,

    _active_id, _active_msc_id: i32,
}

ct_init :: proc() -> CameraTool {
    return CameraTool {
        camera_perspective = oe.cm_init({}),
        mouse_locked = false,
        camera_orthographic = rl.Camera2D {
            target = {},
            offset = {f32(oe.w_render_width()) * 0.5, f32(oe.w_render_height()) * 0.5},
            rotation = 0, zoom = 1,
        },
        mode = .PERSPECTIVE,
        _active_id = ACTIVE_EMPTY,
        _active_msc_id = ACTIVE_EMPTY,
        tile_size = {1, 1, 1},
        points_to_add = make([dynamic]oe.Vec3),
        shape_mode = .TRIANGLE,
    };
}

ct_update :: proc(using self: ^CameraTool) {
    if (mode == .PERSPECTIVE) {
        ct_update_perspective(self);
    } else {
        ct_update_ortho(self);
    }

    key := i32(oe.keycode_pressed());
    if (key >= 49 && key <= 52 && !oe.gui_mouse_over() && !oe.gui_text_active()) {
        if (!oe.key_down(.LEFT_SHIFT)) {
            mode = CameraMode(key - 49);
        }
    }

    update(self^);

    // fmt.println(_active_msc_id, _active_id);
}

ct_render :: proc(using self: ^CameraTool) {
    if (mode == .PERSPECTIVE) {
        rl.BeginMode3D(camera_perspective.rl_matrix);
        oe.draw_debug_axis(3);
        oe.draw_debug_axis(-3);

        UNACTIVE_ALPHA :: 0
        if (oe.key_down(.LEFT_SHIFT) && !tile_edit) {
            if (EditMode.XY in edit_mode) {
                rl.rlPushMatrix();
                rl.rlTranslatef(0, 0, edit_layer[EditMode.XY]);

                alpha: u8 = UNACTIVE_ALPHA;
                if (active_axis == .XY) { alpha = 255; }
                oe.draw_grid3D(oe.OCTREE_SIZE, 1, {150, 150, 150, alpha}, .XY);
                rl.rlPopMatrix();
            }
            if (EditMode.XZ in edit_mode) {
                rl.rlPushMatrix();
                rl.rlTranslatef(0, edit_layer[EditMode.XZ], 0);

                alpha: u8 = UNACTIVE_ALPHA;
                if (active_axis == .XZ) { alpha = 255; }
                oe.draw_grid3D(oe.OCTREE_SIZE, 1, {150, 150, 150, alpha}, .XZ);
                rl.rlPopMatrix();
            }
            if (EditMode.ZY in edit_mode) {
                rl.rlPushMatrix();
                rl.rlTranslatef(edit_layer[EditMode.ZY], 0, 0);

                alpha: u8 = UNACTIVE_ALPHA;
                if (active_axis == .ZY) { alpha = 255; }
                oe.draw_grid3D(oe.OCTREE_SIZE, 1, {150, 150, 150, alpha}, .ZY);
                rl.rlPopMatrix();
            }
        } else {
            rl.rlPushMatrix();
            rl.rlTranslatef(0, tile_layer, 0);
            oe.draw_grid3D(oe.OCTREE_SIZE, 1, {150, 150, 150, 255});
            rl.rlPopMatrix();
        }

        oe.ew_render();
        render(self^);
        render_tri(self);

        if (tile_edit) {
            ct_tile_edit(self);
        }

        if (oe.key_down(.LEFT_SHIFT)) {
            ct_msc_edit(self);
        }

        rl.EndMode3D();
    } else {
        rl.BeginMode2D(camera_orthographic);
        ct_render_ortho(self);
        rl.EndMode2D();
    }
}

@(private = "file")
ct_msc_edit :: proc(using self: ^CameraTool) {
    if (len(points_to_add) == int(shape_mode_size[shape_mode])) {
        msc := msc_check(new_instance);

        #partial switch shape_mode {
            case .TRIANGLE:
                points := [3]oe.Vec3{points_to_add[0], points_to_add[1], points_to_add[2]};
                oe.msc_append_tri(
                    msc, points[0], points[1], points[2], 
                    normal = oe.surface_normal(points));
            case .QUAD:
                points := [4]oe.Vec3{points_to_add[0], points_to_add[1], points_to_add[2], points_to_add[3]};
                oe.msc_append_quad(msc, points[0], points[1], points[2], points[3]);
            case .CIRCLE:
                oe.msc_append_circle(msc, points_to_add[0], points_to_add[1]);
        }

        clear(&points_to_add);
    }

    if (oe.key_pressed(.EQUAL)) {
        if (.XY in edit_mode) {
            edit_layer[EditMode.XY] += 0.5;
        }
        if (.XZ in edit_mode) {
            edit_layer[EditMode.XZ] += 0.5;
        }
        if (.ZY in edit_mode) {
            edit_layer[EditMode.ZY] += 0.5;
        }
    }
    if (oe.key_pressed(.MINUS)) {
        if (.XY in edit_mode) {
            edit_layer[EditMode.XY] -= 0.5;
        }
        if (.XZ in edit_mode) {
            edit_layer[EditMode.XZ] -= 0.5;
        }
        if (.ZY in edit_mode) {
            edit_layer[EditMode.ZY] -= 0.5;
        }
    }

    if (oe.key_pressed(.ENTER)) {
        if (.XY in edit_mode) {
            edit_layer[EditMode.XY] = 0;
        }
        if (.XZ in edit_mode) {
            edit_layer[EditMode.XZ] = 0;
        }
        if (.ZY in edit_mode) {
            edit_layer[EditMode.ZY] = 0;
        }
    }

    mouse_ray := oe.get_mouse_rc(camera_perspective);

    plane_xy := oe.Transform {
        {0, 0, edit_layer[EditMode.XY]}, {}, {oe.OCTREE_SIZE, oe.OCTREE_SIZE, 0.25}
    };
    plane_xz := oe.Transform {
        {0, edit_layer[EditMode.XZ], 0}, {}, {oe.OCTREE_SIZE, 0.25, oe.OCTREE_SIZE}
    };
    plane_zy := oe.Transform {
        {edit_layer[EditMode.ZY], 0, 0}, {}, {0.25, oe.OCTREE_SIZE, oe.OCTREE_SIZE}
    };

    coll_xy, point_xy := oe.rc_is_colliding(mouse_ray, plane_xy, .BOX);
    coll_xz, point_xz := oe.rc_is_colliding(mouse_ray, plane_xz, .BOX);
    coll_zy, point_zy := oe.rc_is_colliding(mouse_ray, plane_zy, .BOX);

    collision: bool;
    closest: oe.Vec3;
    axis: EditMode;
    closest_dist := oe.F32_MAX;
    if (.XY in edit_mode && coll_xy) {
        dist := oe.vec3_dist(point_xy, camera_perspective.position);
        if (dist < closest_dist) {
            closest_dist = dist;
            closest = point_xy;
            collision = true;
            axis = .XY;
        }
    }
    if (.XZ in edit_mode && coll_xz) {
        dist := oe.vec3_dist(point_xz, camera_perspective.position);
        if (dist < closest_dist) {
            closest_dist = dist;
            closest = point_xz;
            collision = true;
            axis = .XZ;
        }
    }
    if (.ZY in edit_mode && coll_zy) {
        dist := oe.vec3_dist(point_zy, camera_perspective.position);
        if (dist < closest_dist) {
            closest_dist = dist;
            closest = point_zy;
            collision = true;
            axis = .ZY;
        }
    }

    snapped: oe.Vec3;
    if (axis == .XY) {
        snapped = oe.Vec3 {
            math.round(closest.x),
            math.round(closest.y),
            edit_layer[axis],
        };
    }
    if (axis == .XZ) {
        snapped = oe.Vec3 {
            math.round(closest.x),
            edit_layer[axis],
            math.round(closest.z),
        };
    }
    if (axis == .ZY) {
        snapped = oe.Vec3 {
            edit_layer[axis],
            math.round(closest.y),
            math.round(closest.z),
        };
    }

    active_axis = axis;
    position := snapped;

    for pt in points_to_add {
        rl.DrawSphere(pt, 0.1, oe.BLUE);

        if (pt.x == position.x) {
            rl.DrawLine3D(pt, position, oe.WHITE);
        }
        if (pt.y == position.z) {
            rl.DrawLine3D(pt, position, oe.WHITE);
        }
        if (pt.z == position.z) {
            rl.DrawLine3D(pt, position, oe.WHITE);
        }
    }

    rl.DrawSphere(position, 0.1, oe.RED);

    if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over() && !oe.gui_text_active()) {
        append(&points_to_add, position);
    }
}

@(private = "file")
ct_tile_edit :: proc(using self: ^CameraTool) {
    mouse_ray := oe.get_mouse_rc(camera_perspective);
    plane := oe.Transform {
        {0, tile_layer, 0}, {}, {oe.OCTREE_SIZE, 0.25, oe.OCTREE_SIZE}
    };
    coll, point := oe.rc_is_colliding(mouse_ray, plane, .BOX);
    snapped := oe.Vec3 {
        math.floor(point.x),
        tile_layer,
        math.floor(point.z),
    };

    position := snapped + tile_size * 0.5;

    rl.DrawCubeWiresV(position, tile_size, oe.GREEN);

    if (!oe.gui_mouse_over() && !oe.gui_text_active()) {
        if (oe.mouse_pressed(.LEFT)) {
            id_parse := oe.gui.text_boxes["IDTextBox"].text;
            parsed, ok := strconv.parse_int(id_parse);
            id := u32(parsed);
            tag := "csg_box";
            reg_tag := oe.str_add("data_id_", tag);
            if (oe.asset_manager.registry[reg_tag] != nil) {
                reg_tag = oe.str_add(reg_tag, oe.rand_digits(4));
            }

            comps := fa.fixed_array(oe.ComponentMarshall, 16);
            fa.append(
                &comps, oe.ComponentMarshall{oe.CSG_RB, "RigidBody"}
            );
            fa.append(
                &comps, oe.ComponentMarshall{oe.CSG_SM, "SimpleMesh"}
            );

            oe.reg_asset(
                reg_tag, 
                oe.DataID {
                    reg_tag, 
                    tag, 
                    id, 
                    oe.Transform{
                        position, {}, tile_size
                    },
                    fa.fixed_array(i32, 16),
                    comps,
                }
            );
            oe.dbg_log(
                oe.str_add(
                    {"Added data id of tag: ", 
                    tag, " and id: ", oe.str_add("", id)}
                )
            );

            if (editor_data.csg_textures[tile_size] == {}) {
                tiling := i32(linalg.max(tile_size));
                img := rl.GenImageChecked(
                    2 * tiling, 2 * tiling, 
                    1, 1, 
                    oe.BLACK, oe.PINK
                );

                editor_data.csg_textures[tile_size] = oe.load_texture(
                    rl.LoadTextureFromImage(img)
                );

                rl.UnloadImage(img);
            }
        }
    }
}

@(private = "file")
ct_render_ortho :: proc(using self: ^CameraTool) {
    oe.draw_grid2D(100, GRID_SPACING, GRID_COLOR);

    // cross
    rl.rlPushMatrix();
    rl.rlTranslatef(camera_orthographic.target.x, camera_orthographic.target.y, 0);
    rl.rlScalef(1, -1, 1);
    rl.DrawLineV({-5, 0}, {5, 0}, oe.PINK);
    rl.DrawLineV({0, -5}, {0, 5}, oe.PINK);
    rl.rlPopMatrix();

    dids := oe.get_reg_data_ids();
    for i in 0..<len(dids) {
        did_render_ortho(self, &dids[i]);
    }

    for msc_id in 0..<oe.ecs_world.physics.mscs.len {
        msc := oe.ecs_world.physics.mscs.data[msc_id];
        for i in 0..<len(msc.tris) {
            tri_render_ortho(self, msc.tris[i], i, msc_id);
        }
    }

    if (_active_id == ACTIVE_EMPTY || _active_msc_id == ACTIVE_EMPTY) do return;

    if (oe.key_pressed(.T)) {
        oe.gui_toggle_window("Texture tool");
    }

    if (oe.key_pressed(.DELETE)) {
        ordered_remove(&oe.ecs_world.physics.mscs.data[_active_msc_id].tris, int(_active_id));
        _active_id = ACTIVE_EMPTY;
        _active_msc_id = ACTIVE_EMPTY;
        return;
    }

    active_3d := oe.ecs_world.physics.mscs.data[_active_msc_id].tris[_active_id].pts;
    active := msc_tri_to_ortho_tri(active_3d, mode);

    rl.rlPushMatrix();
    rl.rlScalef(1, -1, 1);
    rl.DrawTriangle(
        active[0] * RENDER_SCALAR, 
        active[1] * RENDER_SCALAR, 
        active[2] * RENDER_SCALAR, GRID_COLOR
    );
    rl.rlPopMatrix();
}

@(private = "file")
did_render_ortho :: proc(using self: ^CameraTool, did: ^oe.DataID) {
    rl.rlPushMatrix();
    rl.rlScalef(RENDER_SCALAR, -RENDER_SCALAR, 1);

    #partial switch mode {
        case .ORTHO_XY:
            rl.DrawRectangleLinesEx({
                did.transform.position.x - did.transform.scale.x, 
                did.transform.position.y - did.transform.scale.y,
                did.transform.scale.x, did.transform.scale.y,
            }, 0.05, rl.YELLOW);
        case .ORTHO_XZ:
            rl.DrawRectangleLinesEx({
                (did.transform.position.x - did.transform.scale.x), 
                (did.transform.position.z - did.transform.scale.z),
                did.transform.scale.x, did.transform.scale.z,
            }, 0.05, rl.YELLOW);
        case .ORTHO_ZY:
            rl.DrawRectangleLinesEx({
                (did.transform.position.z - did.transform.scale.z), 
                (did.transform.position.y - did.transform.scale.y),
                did.transform.scale.z, did.transform.scale.y,
            }, 0.05, rl.YELLOW);
    }
    
    rl.rlPopMatrix();
}

@(private = "file")
tri_render_ortho :: proc(using self: ^CameraTool, tri: ^oe.TriangleCollider, #any_int id, msc_id: i32) {
    rl.rlPushMatrix();
    rl.rlScalef(RENDER_SCALAR, -RENDER_SCALAR, 1);

    tri.pts = update_tri_ortho(self, tri.pts, id, msc_id);

    #partial switch mode {
        case .ORTHO_XY:
            t := tri.pts;
            rl.DrawLineV(t[0].xy, t[1].xy, rl.YELLOW);
            rl.DrawLineV(t[0].xy, t[2].xy, rl.YELLOW);
            rl.DrawLineV(t[1].xy, t[2].xy, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].xy, i, id, msc_id);
                tri.pts[i] = {res.x, res.y, tri.pts[i].z};
            }
        case .ORTHO_XZ:
            t := tri.pts;
            rl.DrawLineV(t[0].xz, t[1].xz, rl.YELLOW);
            rl.DrawLineV(t[0].xz, t[2].xz, rl.YELLOW);
            rl.DrawLineV(t[1].xz, t[2].xz, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].xz, i, id, msc_id);
                tri.pts[i] = {res.x, tri.pts[i].y, res.y};
            }
        case .ORTHO_ZY:
            t := tri.pts;
            rl.DrawLineV(t[0].zy, t[1].zy, rl.YELLOW);
            rl.DrawLineV(t[0].zy, t[2].zy, rl.YELLOW);
            rl.DrawLineV(t[1].zy, t[2].zy, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].zy, i, id, msc_id);
                tri.pts[i] = {tri.pts[i].x, res.y, res.x};
            }
    }

    rl.rlPopMatrix();
}

@(private = "file")
msc_tri_to_ortho_tri :: proc(pts: [3]oe.Vec3, mode: CameraMode) -> [3]oe.Vec2 {
    #partial switch mode {
        case .ORTHO_XY:
            return { pts[0].xy, pts[1].xy, pts[2].xy };
        case .ORTHO_XZ:
            return { pts[0].xz, pts[1].xz, pts[2].xz };
        case .ORTHO_ZY:
            return { pts[0].zy, pts[1].zy, pts[2].zy };
    }

    return { pts[0].xy, pts[1].xy, pts[2].xy };
}

@(private = "file")
ortho_tri_to_msc_tri :: proc(pts: [3]oe.Vec2, pts_3d: [3]oe.Vec3, mode: CameraMode) -> [3]oe.Vec3 {
    #partial switch mode {
        case .ORTHO_XY:
            return { 
                {pts[0].x, pts[0].y, pts_3d[0].z}, 
                {pts[1].x, pts[1].y, pts_3d[1].z}, 
                {pts[2].x, pts[2].y, pts_3d[2].z}, 
            };
        case .ORTHO_XZ:
            return { 
                {pts[0].x, pts_3d[0].y, pts[0].y}, 
                {pts[1].x, pts_3d[1].y, pts[1].y}, 
                {pts[2].x, pts_3d[2].y, pts[2].y}, 
            };
        case .ORTHO_ZY:
            return { 
                {pts_3d[0].x, pts[0].y, pts[0].x}, 
                {pts_3d[1].x, pts[1].y, pts[1].x}, 
                {pts_3d[2].x, pts[2].y, pts[2].x}, 
            };
    }

    return { 
        {pts[0].x, pts[0].y, pts_3d[0].z}, 
        {pts[1].x, pts[1].y, pts_3d[1].z}, 
        {pts[2].x, pts[2].y, pts_3d[2].z}, 
    };
}

@(private = "file")
render_tri :: proc(using self: ^CameraTool) {
    ray := oe.get_mouse_rc(camera_perspective);

    collision: bool;
    for msc_id in 0..<oe.ecs_world.physics.mscs.len {
        msc := oe.ecs_world.physics.mscs.data[msc_id];
        if (collision) { continue; }

        coll, arr := oe.rc_colliding_tris(ray, msc);
        collision = coll;
        if (collision) {
            info := arr[0];
            t := msc.tris[info.id];
            if (!oe.gui_mouse_over()) {
                clr := GRID_COLOR;
                if (t.color.r >= GRID_COLOR.r &&
                    t.color.g >= GRID_COLOR.g &&
                    t.color.b >= GRID_COLOR.b) {
                    clr.rgb = t.color.rgb - GRID_COLOR.rgb;
                }

                rl.DrawTriangle3D(t.pts[0], t.pts[1], t.pts[2], clr);
            }

            if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) {
                _active_id = i32(info.id);
                _active_msc_id = i32(msc_id);
            }
        } else {
            if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) {
                _active_id = ACTIVE_EMPTY;
                _active_msc_id = ACTIVE_EMPTY;
            }
        }
        delete(arr);
    }

    if (_active_id != ACTIVE_EMPTY && _active_msc_id != ACTIVE_EMPTY) {
        if (oe.key_pressed(.T)) {
            oe.gui_toggle_window("Texture tool");
        }
        msc := oe.ecs_world.physics.mscs.data[_active_msc_id];
        t := msc.tris[_active_id];

        clr := GRID_COLOR;
        if (t.color.r >= GRID_COLOR.r &&
            t.color.g >= GRID_COLOR.g &&
            t.color.b >= GRID_COLOR.b) {
            clr.rgb = t.color.rgb - GRID_COLOR.rgb;
        }

        rl.DrawTriangle3D(t.pts[0], t.pts[1], t.pts[2], clr);

        if (oe.key_pressed(.DELETE)) {
            ordered_remove(&msc.tris, auto_cast _active_id);
            oe.tri_count -= 1;
            _active_id = ACTIVE_EMPTY;
            _active_msc_id = ACTIVE_EMPTY;
            oe.reload_mesh_tris(msc);
        }
    }
}

@(private = "file")
update_tri_ortho :: proc(using self: ^CameraTool, pts: [3]oe.Vec3, #any_int id, msc_id: i32) -> [3]oe.Vec3 {
    res := pts * RENDER_SCALAR;

    @static _moving: bool;
    @static _moving_id: i32;
    @static _moving_msc_id: i32;
    @static _offsets: [3]oe.Vec2;

    mp := rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    mp.y = -mp.y;
    tri := msc_tri_to_ortho_tri(res, mode);
    if (rl.CheckCollisionPointTriangle(mp, tri[0], tri[1], tri[2])) {
        rl.DrawTriangle(
            tri[0] / RENDER_SCALAR, 
            tri[1] / RENDER_SCALAR, 
            tri[2] / RENDER_SCALAR, GRID_COLOR
        );

        if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) {
            _moving = true;
            _moving_id = id;
            _active_id = id;
            _moving_msc_id = msc_id;
            _active_msc_id = msc_id;

            snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
            snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

            _offsets = {
                {snapped_x - tri[0].x, snapped_y - tri[0].y},
                {snapped_x - tri[1].x, snapped_y - tri[1].y},
                {snapped_x - tri[2].x, snapped_y - tri[2].y},
            };
        }
    } else {
        if (!oe.gui_mouse_over() &&
            oe.mouse_pressed(.LEFT) &&
            _active_id == id && 
            _active_msc_id == msc_id) { 
            _active_id = ACTIVE_EMPTY;
            _active_msc_id = ACTIVE_EMPTY;
        }
    }

    if (_moving && _moving_id == id && _moving_msc_id == msc_id) {
        if (oe.mouse_released(.LEFT)) do _moving = false;

        for i in 0..<3 {
            snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
            snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

            tri[i] = {snapped_x - _offsets[i].x, snapped_y - _offsets[i].y};
        }
    }

    res = ortho_tri_to_msc_tri(tri, res, mode); 

    return res / RENDER_SCALAR;
}

@(private = "file")
update_point_ortho :: proc(using self: ^CameraTool, pt: oe.Vec2, #any_int vertex_id, id, msc_id: i32) -> oe.Vec2 {
    res := pt * RENDER_SCALAR;
    res.y *= -1;

    @static _moving: bool;
    @static _moving_id: i32;
    @static _moving_msc_id: i32;
    @static _moving_vertex_id: i32;

    rl.DrawCircleV(res, POINT_SIZE, oe.BLUE);

    mp := rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    if (rl.CheckCollisionPointCircle(mp, res, POINT_SIZE)) {
        if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) {    
            _moving = true;
            _moving_id = id;
            _moving_vertex_id = vertex_id;
            _moving_msc_id = msc_id;
        }

        rl.DrawCircleV(res, POINT_SIZE, oe.GREEN);
    }

    if (_moving && _moving_vertex_id == vertex_id && _moving_id == id && _moving_msc_id == msc_id) {
        if (oe.mouse_released(.LEFT))  {
            _moving = false; 
        }

        snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
        snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

        res = {snapped_x, snapped_y};
    }

    res.y *= -1;
    return res / RENDER_SCALAR;
}

@(private = "file")
ct_update_perspective :: proc(using self: ^CameraTool) {
    if (oe.key_pressed(oe.Key.ESCAPE)) {
        mouse_locked = !mouse_locked;
    }

    if (oe.key_down(.LEFT_SHIFT)) {
        if (oe.key_pressed(.T)) {
            tile_edit = !tile_edit;
        }
    }

    if (!oe.gui_mouse_over() && !oe.gui_text_active() && tile_edit) {
        if (oe.key_down(.LEFT_SHIFT)) {
            if (oe.key_pressed(.ENTER)) {
                tile_layer = 0;
            }
        }

        if (oe.key_down(.LEFT_SHIFT)) {
            if (oe.key_pressed(.EQUAL)) {
                tile_layer += 0.5;
            }
            if (oe.key_pressed(.MINUS)) {
                tile_layer -= 0.5;
            }

            if (oe.key_pressed(.LEFT)) {
                tile_size.x -= 0.5;
            }
            if (oe.key_pressed(.RIGHT)) {
                tile_size.x += 0.5;
            }
            if (oe.key_pressed(.UP)) {
                tile_size.z -= 0.5;
            }
            if (oe.key_pressed(.DOWN)) {
                tile_size.z += 0.5;
            }
            if (oe.key_pressed(.COMMA)) {
                tile_size.y -= 0.5;
            }
            if (oe.key_pressed(.PERIOD)) {
                tile_size.y += 0.5;
            }
        }
    }

    oe.cm_set_fps(&camera_perspective, 0.1, mouse_locked);
    oe.cm_set_fps_controls(&camera_perspective, 10, mouse_locked, true);
    oe.cm_default_fps_matrix(&camera_perspective);
    oe.cm_update(&camera_perspective);
}

@(private = "file")
ct_update_ortho :: proc(using self: ^CameraTool) {
    _mouse_pos = rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    _prev_mouse_pos = _mouse_pos;

    new_zoom := camera_orthographic.zoom + rl.GetMouseWheelMoveV().y * 0.01;
    if (new_zoom <= 0) do new_zoom = 0.01;

    zoom_factor := new_zoom / camera_orthographic.zoom;
    // zoom to mouse
    // camera_orthographic.offset -= (_mouse_pos - camera_orthographic.target) * (zoom_factor - 1);
    camera_orthographic.zoom = new_zoom;

    if (oe.key_pressed(.SPACE)) {
        camera_orthographic.target = {};
    }

    if (oe.mouse_down(.MIDDLE)) {
        delta := rl.GetMouseDelta();
        delta = delta * (-1 / camera_orthographic.zoom);

        camera_orthographic.target += delta;
    }
}
