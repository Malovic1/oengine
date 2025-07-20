package oengine

import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import ecs "ecs"
import "core:encoding/json"
import od "object_data"
import "core:time"

Sprite :: struct {
    src: rl.Rectangle,
    up: Vec3,
    size, origin: Vec2,
    rotation: f32,
}

sprite_default :: proc(texture: Texture) -> Sprite {
    return Sprite {
        src = {0, 0, f32(texture.width), f32(texture.height)},
        up = vec3_y(),
        size = {1, 1},
        origin = {f32(texture.width) * 0.5, f32(texture.height) * 0.5},
        rotation = 0,
    };
}

ModelArmature :: struct {
    animations: [^]rl.ModelAnimation,
    anim_count: i32,
    frame_counter: f32,
    speed: f32,
}

ma_load :: proc(path: string, speed: f32 = 100) -> ModelArmature {
    res: ModelArmature;
    res.animations = rl.LoadModelAnimations(strings.clone_to_cstring(path), &res.anim_count);
    res.speed = speed;

    return res;
}

SimpleMesh :: struct {
    transform: Transform,
    offset: Transform,
    shape: ShapeType,
    
    tex: union {
        Model,
        CubeMap,
        Slope,
        Sprite,
    },

    is_lit: bool,
    use_fog: bool,
    texture: Texture,
    color: Color,
    starting_color: Color,
    shader: Shader,
    tiling: Vec2,
    is_sprite: bool, // billboard behaviour
    use_triplanar: bool,
    cached: bool, // internal loading stuff
    user_call: bool, // allows the user to specify when to render it using the render func
}

sm_init :: proc {
    sm_init_def,
    sm_init_tex,
    sm_init_cube,
    sm_init_model,
    sm_init_slope,
    sm_init_sprite,
}

@(private = "file")
sm_init_all :: proc(using sm: ^SimpleMesh, s_shape: ShapeType, s_color: Color) {
    transform = transform_default();
    offset = transform_default();
    shape = s_shape;

    if (int(shape) < 10) {
        tex = mesh_loaders[int(shape)]();
    }

    is_lit = true;
    use_fog = OE_FAE;
    texture = load_texture(rl.LoadTextureFromImage(rl.GenImageColor(16, 16, WHITE)));
    color = s_color;
    starting_color = color;
    cached = true;
}

sm_init_def :: proc(s_shape: ShapeType = .BOX, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, s_shape, s_color);

    return sm;
}

sm_init_tex :: proc(s_texture: Texture, s_shape: ShapeType = .BOX, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, s_shape, s_color);

    sm.texture = s_texture;
    sm.tex.(Model).materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = s_texture.data;

    return sm;
}

sm_init_cube :: proc(cube_map: CubeMap, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .CUBEMAP, s_color);
    sm.tex = cube_map;

    return sm;
}

sm_init_model :: proc(model: Model, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .MODEL, s_color);
    sm.tex = model;

    return sm;
}

sm_init_slope :: proc(slope: Slope, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .SLOPE, s_color);
    sm.tex = slope;

    return sm;
}

// temp fix, since the sm_init_tex can also take only a texture as parameter here 
// you have to pass .SPRITE or any int to distinguish it from sm_init_tex
sm_init_sprite :: proc(s_texture: Texture, #any_int i: i32, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .SPRITE, s_color);
    sm.texture = s_texture;
    sm.tex = sprite_default(s_texture);

    return sm;
}

sm_apply_anim :: proc(using self: ^SimpleMesh, ma: ^ModelArmature, id: i32) {
    ma.frame_counter += ma.speed * rl.GetFrameTime();
    fc := i32(math.floor(ma.frame_counter));
    rl.UpdateModelAnimation(tex.(Model), ma.animations[id], fc);

    if (fc >= ma.animations[id].frameCount) {
        ma.frame_counter = 0;
    }
}

sm_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, sm:= ecs.get_components(ent, Transform, SimpleMesh);
    if (is_nil(t, sm)) do return;
    if (!sm.user_call) { sm_custom_render(t, sm); }
}

sm_custom_render :: proc(t: ^Transform, sm: ^SimpleMesh) {
    using sm;

    transform = t^;

    if (ecs_world.FAE && use_fog) {
        color = mix_color(world_fog.color, starting_color, world_fog.visibility); 
    }

    target := transform;

    if (sys_os() == .Linux && shape == .CYLINDER) {
        target.position.y = transform.position.y - 0.5;
    }

    if (is_sprite) {
        target.rotation.y = -look_at_vec2(
            target.position.xz, world().camera.position.xz) - 90;
    }

    #partial switch v in tex {
        case Model:
            sm_set_shader(sm, ecs_world.ray_ctx.shader);

            use_tiling := tiling != {};
            if (use_tiling) {
                ray_set_tiling(tiling); 
            }

            if (use_triplanar) {
                ray_enable_triplanar();
            }

            draw_model(v, target, color, is_lit, offset);

            if (use_triplanar) {
                ray_disable_triplanar();
            }

            if (use_tiling) {
                ray_reset_tiling();
            }
        case CubeMap:
            draw_cube_map(v, target, color);
        case Slope:
            draw_slope(
                v, target.position,
                target.rotation, target.scale,
                texture, color,
            );
        case Sprite:
            rl.DrawBillboardPro(
                ecs_world.camera.rl_matrix, texture,
                v.src, target.position, v.up,
                v.size, v.origin, v.rotation,
                color,
            );
    }

}

sm_toggle_lit :: proc(using self: ^SimpleMesh) {
    is_lit = !is_lit;
}

sm_tex :: proc(using self: ^SimpleMesh, $T: typeid) -> T {
    return tex.(T);
}

sm_tex_is :: proc(using self: ^SimpleMesh, $T: typeid) -> bool {
    #partial switch v in tex {
        case T:
            return true;
    } 

    return false;
}

sm_texture :: proc(using self: ^SimpleMesh) -> Texture {
    #partial switch v in tex {
        case Model:
            return load_texture(v.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture);
    }

    return texture;
}

sm_set_texture :: proc(using self: ^SimpleMesh, s_texture: Texture) {
    texture = s_texture; 

    #partial switch v in tex {
        case Model:
            v.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture.data;
    }
}

sm_set_tiling :: proc {
    sm_set_tiling_def,
    sm_set_tiling_cube,
}

sm_set_tiling_def :: proc(using self: ^SimpleMesh, tx: i32) {
    sm_set_texture(self, tile_texture(texture, tx));
}

sm_set_tiling_cube :: proc(using self: ^SimpleMesh, tx: i32, side: CubeMapSide) {
    if (!sm_tex_is(self, CubeMap)) do return;

    res := sm_tex(self, CubeMap);

    if (side == .ALL) {
        for i in 0..<6 {
            res[i] = tile_texture(sm_tex(self, CubeMap)[i], tx);
        }
    } else {         
        res[side] = tile_texture(sm_tex(self, CubeMap)[side], tx);
    }

    tex = res;
}

sm_set_shader :: proc(using self: ^SimpleMesh, s_shader: Shader) {
    if (!shader_defined(s_shader)) {
        dbg_log("Shader undefined", .WARNING);
        return;
    }

    shader = s_shader;

    if (sys_os() == .Darwin) {
        dbg_log("Mac doesn't support shaders on models for now");
        return;
    }

    if (sm_tex_is(self, Model)) {
        m := sm_tex(self, Model);
        for i in 0..<m.materialCount {
            m.materials[i].shader = shader.data;
        }
    }
}

sm_parse :: proc(asset: od.Object) -> rawptr {
    shape := ShapeType(od.target_type(asset["shape"], i32));

    is_lit := true;
    if (od_contains(asset, "is_lit")) {
        is_lit = asset["is_lit"].(bool);
    }

    use_fog: bool;
    if (od_contains(asset, "use_fog")) {
        use_fog = asset["use_fog"].(bool);
    }

    texture: Texture;
    if (od_contains(asset, "texture")) {
        texture_tag := asset["texture"].(string);
        texture = get_asset_var(texture_tag, Texture);
    }

    if (od_contains(asset, "tiling")) {
        tiling := od.target_type(asset["tiling"], i32);
        texture = tile_texture(texture, tiling);
    }

    cached := true;
    if (od_contains(asset, "cached")) {
        cached = asset["cached"].(bool);
    }

    offset := transform_default();
    if (od_contains(asset, "offset")) {
        offset_data := asset["offset"].(od.Object);
        
        if (od_contains(offset_data, "position")) { 
            offset.position = od_vec3(offset_data["position"].(od.Object));
        }
        if (od_contains(offset_data, "rotation")) { 
            offset.rotation = od_vec3(offset_data["rotation"].(od.Object));
        }
        if (od_contains(offset_data, "scale")) { 
            offset.scale = od_vec3(offset_data["scale"].(od.Object));
        }
    }

    color := od_color(asset["color"].(od.Object));

    if (shape == .MODEL) {
        model_tag := asset["model"].(string);
        model := model_clone(get_asset_var(model_tag, Model));

        sm := sm_init(model, color);
        sm.is_lit = is_lit;
        sm.use_fog = use_fog;
        sm.cached = cached;

        return new_clone(sm);
    } else if (shape == .CUBEMAP) {
        cubemap_tag: string;
        cubemap: CubeMap;
        if (od_contains(asset, "cubemap")) {
            cubemap_tag = asset["cubemap"].(string);
            cubemap = get_asset_var(cubemap_tag, CubeMap);
        }

        sm := sm_init(cubemap, color);
        sm.is_lit = is_lit;
        sm.use_fog = use_fog;
        sm.texture = texture;
        sm.cached = cached;

        return new_clone(sm);
    } else if (shape == .HEIGHTMAP) {
        heightmap_tex: Texture;
        if (od_contains(asset, "heightmap")) {
            heightmap_tag := asset["heightmap"].(string);
            heightmap_tex = get_asset_var(heightmap_tag, Texture);
        }

        img := load_image(rl.LoadImageFromTexture(heightmap_tex));
        heightmap := load_model(rl.LoadModelFromMesh(rl.GenMeshHeightmap(img.data, {1, 1, 1})));
        heightmap.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = heightmap_tex;

        sm := sm_init(heightmap);
        sm.shape = .HEIGHTMAP;
        rl.UnloadImage(img.data);

        return new_clone(sm);
    }

    sm: SimpleMesh;
    if (texture == {}) {
        sm = sm_init(shape, color);
    } else {
        sm = sm_init(texture, shape, color);
    }
    sm.is_lit = is_lit;
    sm.use_fog = use_fog;
    sm.cached = cached;

    return new_clone(sm);
}

sm_loader :: proc(ent: AEntity, tag: string) {
    comp := get_component_data(tag, SimpleMesh);
    clone := comp^;
    ent_tr := get_component(ent, Transform);

    if (!clone.cached) {
        if (int(clone.shape) < 10) {
            clone.tex = mesh_loaders[int(clone.shape)]();
            sm_set_texture(&clone, clone.texture);
        }

        if (clone.shape == .MODEL) {
            clone.tex = model_clone(comp.tex.(Model));
        }

        if (clone.shape == .HEIGHTMAP) {
            clone.tex = model_clone(comp.tex.(Model));
        }
    }

    if (clone.shape == .HEIGHTMAP) {
        clone.offset.position = -ent_tr.scale * 0.5;
    }

    if (tag == CSG_SM) {
        if (clone.shape == .CUBEMAP) {
            get_tile_count :: proc(s: f32) -> i32 {
                if (s >= 1) { return i32(s); }
                else if (s > 0) { return i32(1.0 / s + 0.5); }

                return 1;
            }

            scale := linalg.abs(ent_tr.scale);

            tiling := Vec3i {
                get_tile_count(scale.x),
                get_tile_count(scale.y),
                get_tile_count(scale.z),
            };

            tiled := CubeMap {
                tile_texture_xy(clone.texture, tiling.x, tiling.y),
                tile_texture_xy(clone.texture, tiling.x, tiling.y),
                tile_texture_xy(clone.texture, tiling.z, tiling.y),
                tile_texture_xy(clone.texture, tiling.z, tiling.y),
                tile_texture_xy(clone.texture, tiling.x, tiling.z),
                tile_texture_xy(clone.texture, tiling.x, tiling.z),
            };

            clone.tex = tiled;
        }
        if (clone.shape == .BOX) {
            clone.use_triplanar = true;
        }
    }

    add_component(ent, clone);
}
