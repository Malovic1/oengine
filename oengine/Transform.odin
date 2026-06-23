package oengine


import ecs "ecs"
import "core:fmt"
import "core:encoding/json"
import od "object_data"

Transform :: struct {
    position: Vec3,
    rotation: Vec3,
    scale: Vec3
}

transform_default :: proc() -> Transform {
    return Transform {
        position = vec3_zero(),
        rotation = vec3_zero(),
        scale = vec3_one(),
    };
}

transform_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t := ecs.get_component(ent, Transform);
    if (is_nil(t)) do return;

    if (OE_DEBUG) do draw_cube_wireframe(t.position, t.rotation, t.scale, GREEN);
}

transform_add :: proc(t1, t2: Transform) -> Transform {
    return {
        position = t1.position + t2.position,
        rotation = t1.rotation + t2.rotation,
        scale = t1.scale + t2.scale,
    };
}

transform_subtract :: proc(t1, t2: Transform) -> Transform {
    return {
        position = t1.position - t2.position,
        rotation = t1.rotation - t2.rotation,
        scale = t1.scale - t2.scale,
    };
}

transform_parse :: proc(asset: od.Object) -> rawptr {
    t := Transform {
        position = od_vec3(asset["position"].(od.Object)),
        rotation = od_vec3(asset["rotation"].(od.Object)),
        scale = od_vec3(asset["scale"].(od.Object)),
    };

    return new_clone(t);
}
