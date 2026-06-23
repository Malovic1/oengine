package oengine

import "core:fmt"

import ecs "ecs"
import "core:encoding/json"
import od "object_data"

Light :: struct {
    id: u32,
    transform: Transform,
    offset: Vec3,
    data: RayLight,
    locked_pos: bool,
}

@(private = "file")
lc_init_all :: proc(
    using lc: ^Light, 
    s_type: RayLightType = .Point,
    target: Vec3 = {},
    s_color: Color = WHITE,
    intensity: f32 = 1.0
) {
    transform = transform_default();
    locked_pos = true;

    data = ray_create_light(
        lc.id,
        s_type, 
        transform.position, 
        target, s_color, 
        ecs_world.ray_ctx.shader, intensity
    );
}

lc_toggle :: proc(using lc: ^Light) {
    data.enabled = !data.enabled;
}

lc_init :: proc(
    s_type: RayLightType = .Point, 
    s_color: Color = WHITE,
) -> Light {
    lc: Light;
    lc.id = u32(ecs_world.ray_ctx.light_count);
    ecs_world.ray_ctx.light_count += 1;

    lc_init_all(&lc, s_type = s_type, s_color = s_color);
    
    return lc;
}

lc_init_id :: proc(
    id: u32, 
    s_type: RayLightType = .Point, 
    s_color: Color = WHITE) -> Light {
    lc: Light;
    lc.id = id;
    ecs_world.ray_ctx.light_count += 1;

    lc_init_all(&lc, s_type = s_type, s_color = s_color);
    
    return lc;
}

lc_init_without_adding :: proc(
    id: u32, 
    s_type: RayLightType = .Point, 
    s_color: Color = WHITE) -> Light {
    lc: Light;
    lc.id = id;
    using lc;

    transform = transform_default();

    data.enabled = true;
    data.type = s_type;
    data.position = transform.position;
    data.color = s_color;
    data.intensity = 1.0;
    
    return lc;
}

lc_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, lc := ecs.get_components(ent, Transform, Light);
    if (is_nil(t, lc)) do return;
    using lc;

    transform = t^;

    if (locked_pos) {
        data.position = transform.position + offset;
    }

    update_light_values(ecs_world.ray_ctx.shader, data);
}

lc_clone :: proc(l: Light) -> Light {
    res := lc_init(l.data.type, l.data.color);
    res.transform = l.transform;
    res.data = l.data;

    return res;
}

lc_clone_data :: proc(d, l: RayLight) -> (data: RayLight) {
    data.type = l.type;
    data.enabled = l.enabled;
    data.position = l.position;
    data.target = l.target;
    data.color = l.color;
    data.intensity = l.intensity;
    data.attenuation = data.attenuation;

    data.enabledLoc = d.enabledLoc;
    data.typeLoc = d.typeLoc;
    data.positionLoc = d.positionLoc;
    data.targetLoc = d.targetLoc;
    data.colorLoc = d.colorLoc;
    data.inner_loc = d.inner_loc;
    data.outer_loc = d.outer_loc;
    data.intensity_loc = d.intensity_loc;
    return;
}

lc_parse :: proc(asset: od.Object) -> rawptr {
    id := u32(ecs_world.ray_ctx.light_count); 
    if (asset["id"] != nil) {
        id = u32(od.target_type(asset["id"], i32));
    }

    type := RayLightType(od.target_type(asset["light_type"], i32));

    color := od_color(asset["color"].(od.Object));

    enabled := true;
    if (od_contains(asset, "enabled")) {
        enabled = asset["enabled"].(bool);
    }

    lc := lc_init_without_adding(id, type, color);
    lc.data.enabled = enabled;
    return new_clone(lc);
}

lc_loader :: proc(ent: AEntity, tag: string) {
    using comp := get_component_data(tag, Light);
    light := lc_init(comp.data.type, comp.data.color);
    light.data = lc_clone_data(light.data, comp.data);
    add_component(ent, light);
}
