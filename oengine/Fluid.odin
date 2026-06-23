package oengine

import strs "core:strings"
import "core:fmt"

import ecs "ecs"
import "core:encoding/json"
import od "object_data"

Fluid :: struct {
    transform: Transform,
    texture: Texture,
    color: Color,
    _shader: Shader,
    mesh: Model,
    
    freq_x:  f32,
    freq_y:  f32,
    amp_x:   f32,
    amp_y:   f32,
    speed_x: f32,
    speed_y: f32,
    tex_size_x: f32,
    tex_size_y: f32,

    set: proc(self: ^Fluid, name: string, val: f32),
    user_call: bool, // allows the user to specify when to render it using the render func
    render_pos: bool,
}

@(private = "file")
f_init_all :: proc(using f: ^Fluid, s_texture: Texture) {
    transform = transform_default();

    texture = s_texture;
    color = WHITE;

    _shader = load_shader(rl_LoadShaderFromMemory(WAVE_VERT, WAVE_FRAG));

    mesh = load_model(rl_LoadModelFromMesh(rl_GenMeshPlane(1, 1, 1, 1)));
    mesh.materials[0].maps[rl_MaterialMapIndex.ALBEDO].texture = texture;
    set_model_shader(&mesh, _shader);

    freqXLoc   := shader_location(_shader, "freqX");
    freqYLoc   := shader_location(_shader, "freqY");
    ampXLoc    := shader_location(_shader, "ampX");
    ampYLoc    := shader_location(_shader, "ampY");
    speedXLoc  := shader_location(_shader, "speedX");
    speedYLoc  := shader_location(_shader, "speedY");

    freq_x = 1;
    freq_y = 1;
    amp_x = 0.08;
    amp_y = 0.08;
    speed_x = 2.5;
    speed_y = 2.5;
    size := Vec2 {f32(texture.width), f32(texture.height)};

    rl_SetShaderValue(_shader, shader_location(_shader, "size"), &size, .VEC2);
    rl_SetShaderValue(_shader, freqXLoc, &freq_x, rl_ShaderUniformDataType.FLOAT);
    rl_SetShaderValue(_shader, freqYLoc, &freq_y, rl_ShaderUniformDataType.FLOAT);
    rl_SetShaderValue(_shader, ampXLoc, &amp_x, rl_ShaderUniformDataType.FLOAT);
    rl_SetShaderValue(_shader, ampYLoc, &amp_x, rl_ShaderUniformDataType.FLOAT);
    rl_SetShaderValue(_shader, speedXLoc, &speed_x, rl_ShaderUniformDataType.FLOAT);
    rl_SetShaderValue(_shader, speedYLoc, &speed_y, rl_ShaderUniformDataType.FLOAT);

    set = f_set;
}

f_init :: proc(s_texture: Texture) -> Fluid {
    f: Fluid;

    f_init_all(&f, s_texture);

    return f;
}

f_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    f, t := ecs.get_components(ent, Fluid, Transform);
    if (is_nil(f, t)) do return;
    if (!f.user_call) { f_custom_render(t, f); }
}

f_custom_render :: proc(t: ^Transform, f: ^Fluid) {
    using f;

    transform = t^;

    pos := world().camera.position;
    rl_SetShaderValue(_shader, shader_location(_shader, "viewPos"), &pos, .VEC3);

    seconds := f32(rl_GetTime());
    rl_SetShaderValue(_shader, shader_location(_shader, "seconds"), &seconds, .FLOAT);

    color_loc := shader_location(_shader, "fogColor");
    clr := world().ray_ctx.fog_color;
    color_f := Vec4 {
        f32(clr.r) / 255,
        f32(clr.g) / 255,
        f32(clr.b) / 255,
        f32(clr.a) / 255,
    };
    rl_SetShaderValue(_shader, color_loc, &color_f, .VEC4);

    density_loc := shader_location(_shader, "fogDensity");
    density_v := world().ray_ctx.fog_density;
    rl_SetShaderValue(_shader, density_loc, &density_v, .FLOAT);

    _render_pos := transform.position;
    _render_pos.y = transform.position.y + transform.scale.y * 0.5;

    if (render_pos) { 
        tr := transform;
        tr.position = _render_pos;
        draw_model(mesh, tr, color);
    } else {
        draw_model(mesh, transform, color);
    }

    // rl_BeginShaderMode(_shader);
    //
    // draw_textured_plane(
    //     texture, 
    //     render_pos, 
    //     transform.scale.xz, 
    //     transform.rotation.y,
    //     color
    // );
    //
    // rl_EndShaderMode();
}

f_set :: proc(using self: ^Fluid, name: string, val: f32) {
    value := val;

    rl_SetShaderValue(
        _shader, 
        shader_location(_shader, strs.clone_to_cstring(name)),
        &value, .FLOAT
    );
}

f_set_size :: proc(using self: ^Fluid, size: Vec2) {
    value := size;

    rl_SetShaderValue(
        _shader, 
        shader_location(_shader, "size"),
        &value, .VEC2
    );
}

f_parse :: proc(asset: od.Object) -> rawptr {
    texture_tag := asset["texture"].(string);
    texture := get_asset_var(texture_tag, Texture);

    color := od_color(asset["color"].(od.Object));

    f := f_init(texture);
    f.color = color;
    return new_clone(f);
}

f_loader :: proc(ent: AEntity, tag: string) {
    comp := get_component_data(tag, Fluid);
    add_component(ent, comp^);
}
