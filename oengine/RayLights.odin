package oengine

import rl "vendor:raylib"
import "fa"
import "core:math"
import "core:math/linalg"

TextureLight :: struct {
    target: rl.RenderTexture,
    light: ^Light,
}

RAY_MAX_LIGHTS :: 15

RayContext :: struct {
    light_count: i32,
    shader: Shader,
    shadowmaps: [RAY_MAX_LIGHTS]TextureLight,
    fog_density: f32,
    fog_color: Color,
}

RayLight :: struct {
    id:             i32,
    type:           RayLightType,
    enabled:        bool,
    position:       [3]f32,
    target:         [3]f32,
    vp:             rl.Matrix,
    color:          rl.Color,
    cast_shadows:   bool,
    range:          f32,
    intensity:      f32,
    attenuation:    f32,
    enabledLoc:     i32,
    typeLoc:        i32,
    positionLoc:    i32,
    targetLoc:      i32,
    colorLoc:       i32,
    attenuationLoc: i32,
    inner_loc:      i32,
    outer_loc:      i32,
    intensity_loc:  i32,
    range_loc:      i32,
    vp_loc:         i32,
    cs_loc:         i32,
}

RayLightType :: enum i32 {
    Directional,
    Point,
    Spot,
}

ray_create_light :: proc(
    #any_int id: i32, 
    type: RayLightType, 
    position, 
    target: [3]f32, 
    color: rl.Color, 
    shader: rl.Shader, 
    intensity: f32 = 1,
    range: f32 = 20.0) -> (light: RayLight) {
    if id < RAY_MAX_LIGHTS {
        light.id = id;
        light.enabled = true
        light.type = type
        light.position = position
        light.target = target
        light.color = color
        light.intensity = intensity;
        light.range = range;

        light.enabledLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].enabled", id)))
        light.typeLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].type", id)))
        light.positionLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].position", id)))
        light.targetLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].target", id)))
        light.colorLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].color", id)))
        light.inner_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].inner_cutoff", id)));
        light.outer_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].outer_cutoff", id)));
        light.intensity_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].intensity", id)));
        light.range_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].range", id)));
        light.vp_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lightVPs[%i]", id)));
        light.cs_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lightCastShadows[%i]", id)));

        update_light_values(shader, light)
    }

    return
}

ray_light_cutoffs :: proc(shader: rl.Shader, light: RayLight, inner, outer: f32) {
    inner_cos := math.cos(inner * Deg2Rad);
    outer_cos := math.cos(outer * Deg2Rad);

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.inner_loc), &inner_cos, .FLOAT);
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.outer_loc), &outer_cos, .FLOAT);
}

update_light_count :: proc(shader: rl.Shader, count: i32) {
    loc := rl.GetShaderLocation(shader, "light_count");

    count := count;
    rl.SetShaderValue(shader, loc, &count, .INT);
}

ray_fog_color :: proc(shader: rl.Shader, color: Color) {
    color_loc := shader_location(shader, "fogColor");

    color_f := Vec4 {
        f32(color.r) / 255,
        f32(color.g) / 255,
        f32(color.b) / 255,
        f32(color.a) / 255,
    };

    ecs_world.ray_ctx.fog_color = color;
    rl.SetShaderValue(shader, color_loc, &color_f, .VEC4);
}

ray_fog_density :: proc(shader: rl.Shader, density: f32) {
    density_loc := shader_location(shader, "fogDensity");
    density_v := density;

    ecs_world.ray_ctx.fog_density = density;
    rl.SetShaderValue(shader, density_loc, &density_v, .FLOAT);
}

ray_ambient :: proc(shader: rl.Shader, ambient: Color) {
    ambient_loc := rl.GetShaderLocation(shader, "ambient");
    ambient_val := Vec4 {
        f32(ambient.r) / 255,
        f32(ambient.g) / 255,
        f32(ambient.b) / 255,
        f32(ambient.a) / 255,
    };
    rl.SetShaderValue(shader, ambient_loc, &ambient_val, .VEC4);
}

ray_view_loc :: proc(shader: rl.Shader) {
    shader.locs[rl.ShaderLocationIndex.VECTOR_VIEW] = i32(rl.GetShaderLocation(shader, "viewPos"));
}

ray_set_view :: proc(shader: rl.Shader, camera: Camera) {
    position := camera.position;

    rl.SetShaderValue(
        shader, 
        rl.ShaderLocationIndex(shader.locs[rl.ShaderLocationIndex.VECTOR_VIEW]), 
        &position, 
        .VEC3
    );
}

update_light_values :: proc(shader: rl.Shader, light: RayLight) {
    light := light

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.enabledLoc), &light.enabled, .INT)
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.typeLoc), &light.type, .INT)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.positionLoc), &light.position, .VEC3)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.targetLoc), &light.target, .VEC3)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.intensity_loc), &light.intensity, .FLOAT);

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.range_loc), &light.range, .FLOAT);

    color := [4]f32{ f32(light.color.r)/255, f32(light.color.g)/255, f32(light.color.b)/255, f32(light.color.a)/255 }
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.colorLoc), &color, .VEC4)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.cs_loc), &light.cast_shadows, .INT);

    if (light.cast_shadows) {
        rl.SetShaderValueMatrix(
            shader, 
            rl.ShaderLocationIndex(light.vp_loc),
            light.vp,
        );
    }
}

setup_shadows :: proc(fovy: f32 = 270) {
    shadow_shader := load_shader(
        rl.LoadShaderFromMemory(DEFAULT_VERT, SHADOWMAP_FRAG));

    for i in 0..<fa.range(world().physics.mscs) {
        msc := ecs_world.physics.mscs.data[i];
        for &mesh in msc.meshes {
            mesh.material.shader = shadow_shader;
        }
    }

    for i in 0..<fa.range(ecs_world.ecs_ctx.entities) {
        entity := ecs_world.ecs_ctx.entities.data[i];
        if (has_component(entity, SimpleMesh)) {
            sm := get_component(entity, SimpleMesh);
            if (!sm.cast_shadows) { continue; }
            sm_set_shader(sm, shadow_shader);
        }
    }

    SH_RES :: 4096
    id: i32;
    for i in 0..<world().ecs_ctx.entities.len {
        ent := ecs_world.ecs_ctx.entities.data[i];
        if (has_component(ent, Light)) {
            lc := get_component(ent, Light);
            if (!lc.data.cast_shadows) { continue; }
            ecs_world.ray_ctx.shadowmaps[id] = {load_shadowmap_rt(SH_RES, SH_RES), lc};
            id += 1;
        }
    }

    for i in 0..<len(ecs_world.ray_ctx.shadowmaps) {
        s_map := ecs_world.ray_ctx.shadowmaps[i];
        if (s_map.light == nil) { continue; }

        light_cam: rl.Camera;
        light_cam.position = s_map.light.transform.position;
        light_cam.target = s_map.light.data.target;
        light_cam.projection = .ORTHOGRAPHIC;
        light_cam.up = {0, 1, 0};
        light_cam.fovy = fovy;

        rl.BeginTextureMode(s_map.target);
        rl.ClearBackground(BLACK);

        rl.BeginMode3D(light_cam);

        view := rl.rlGetMatrixModelview();
        proj := rl.rlGetMatrixProjection();
        light_vp := view * proj;
        s_map.light.data.vp = light_vp;

        using ecs_world;

        rl.rlDisableBackfaceCulling();
        for i in 0..<fa.range(physics.mscs) {
            msc_render(physics.mscs.data[i]);
        }

        for i in 0..<fa.range(ecs_ctx.entities) {
            entity := ecs_ctx.entities.data[i];
            if (has_component(entity, SimpleMesh)) {
                sm := get_component(entity, SimpleMesh);
                if (!sm.cast_shadows) { continue; }
            }
            for j in 0..<fa.range(ecs_ctx._render_systems) {
                system := ecs_ctx._render_systems.data[j];

                system(&ecs_ctx, entity);
            }
        }

        for i in 0..<len(decals) {
            d := decals[i];
            decal_render(d, i32(i));
        }

        rl.EndMode3D();
        rl.EndTextureMode();
    }

    for i in 0..<fa.range(world().physics.mscs) {
        msc := ecs_world.physics.mscs.data[i];
        for &mesh in msc.meshes {
            mesh.material.shader = world().ray_ctx.shader;
        }
    }

    for i in 0..<fa.range(ecs_world.ecs_ctx.entities) {
        entity := ecs_world.ecs_ctx.entities.data[i];
        if (has_component(entity, SimpleMesh)) {
            sm := get_component(entity, SimpleMesh);
            if (!sm.cast_shadows) { continue; }
            sm_set_shader(sm, world().ray_ctx.shader);
        }
    }
}

load_shadowmap_rt :: proc(width, height: i32) -> rl.RenderTexture {
    target: rl.RenderTexture;
    target.id = rl.rlLoadFramebuffer(width, height);
    target.texture.width = width;
    target.texture.height = height;

    if (target.id > 0) {
        rl.rlEnableFramebuffer(target.id);

        // Create depth texture
        // NOTE: No need a color texture attachment for the shadowmap
        target.depth.id = rl.rlLoadTextureDepth(width, height, false);
        target.depth.width = width;
        target.depth.height = height;
        target.depth.format = rl.PixelFormat(19); // DEPTH_COMPONENT_24BIT?
        target.depth.mipmaps = 1;

        // Attach depth texture to FBO
        rl.rlFramebufferAttach(
            target.id, target.depth.id, 
            i32(rl.FramebufferAttachType.DEPTH), i32(rl.FramebufferAttachTextureType.TEXTURE2D), 0
        );

        // Check if fbo is complete with attachments (valid)
        if (rl.rlFramebufferComplete(target.id)) { dbg_log("Framebuffer object created successfully"); }

        rl.rlDisableFramebuffer();
    } else {
        dbg_log("Failed to create framebuffer object");
    }

    return target;
}

unload_shadowmap_rt :: proc(target: rl.RenderTexture) {
    if (target.id > 0) {
        rl.rlUnloadFramebuffer(target.id);
    }
}
