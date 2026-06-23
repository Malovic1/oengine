package oengine

import "core:fmt"


get_particle_data :: proc(data: rawptr, $T: typeid) -> ^T {
    return cast(^T)data;
}

GradientBehaviourData :: struct {
    clr_a, clr_b: Color,
    speed: f32,
}

gradient_beh :: proc(p: ^Particle) {
    p.tint.rgb = p.data.color1.rgb;

    if (p.data.color1 == p.data.color2) { return; }

    delta_r := i32(p.data.color2.r) - i32(p.data.color1.r);
    delta_g := i32(p.data.color2.g) - i32(p.data.color1.g);
    delta_b := i32(p.data.color2.b) - i32(p.data.color1.b);

    adjust := proc(speed: f32, comp: u8, delta: i32) -> u8 {
        step := i32(speed * rl_GetFrameTime());
        if delta < 0 {
            return max(comp - u8(min(-delta, step)), 0);
        } else {
            return min(comp + u8(min(delta, step)), 255);
        }
    };

    speed := cast(^f32)p.data.data;
    speed_val := speed^;
    p.data.color1.r = adjust(speed_val, p.data.color1.r, delta_r);
    p.data.color1.g = adjust(speed_val, p.data.color1.g, delta_g);
    p.data.color1.b = adjust(speed_val, p.data.color1.b, delta_b);
}
