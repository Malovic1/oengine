package oengine

import rl "vendor:raylib"
import "core:fmt"
import ecs "ecs"
import "core:encoding/json"
import od "object_data"

ParticleData :: struct {
    vel, accel, grav: Vec3,
    color1, color2: Color,
    data: rawptr,
}

ParticleBehaviour :: #type proc(p: ^Particle);

default_behaviour :: proc(p: ^Particle) {
    p.data.accel = -p.data.grav;
    p.data.vel += p.data.accel * rl.GetFrameTime();
    p.position += p.data.vel * rl.GetFrameTime();
}

Particle :: struct {
    render: proc(self: ^Particle),
    tint: Color,
    texture: Texture,
    position: Vec3,
    size: Vec3,
    life_time: f32,
    data: ParticleData,
}

Particles :: struct {
    particles: [dynamic]^Particle,
    _removed_particles: [dynamic]int,
    position: Vec3,
    timer: Timer,
    behaviours: [dynamic]ParticleBehaviour,
    disable_depth_mask: bool,
}

checkered_image: Texture; 

particle_init :: proc(spawn_pos: Vec3 = {}, 
    s_grav: Vec3 = {0, -9.81, 0}, 
    slf: f32 = 10, color: Color = WHITE) -> Particle {
    using res: Particle;
    tint = color;
    texture = checkered_image;
    position = spawn_pos;
    size = {0.5, 0.5, 0.5};
    life_time = slf;

    data.grav = s_grav;
    data.color1 = WHITE;
    data.color2 = WHITE;

    render = proc(using self: ^Particle) {
        rl.DrawBillboard(ecs_world.camera.rl_matrix, texture, position, size.x, tint);
    }

    return res;
}

@(private = "file")
ps_init_all :: proc(using ps: ^Particles) {
    particles = make([dynamic]^Particle);
}

ps_add_particle :: proc(using self: ^Particles, p: Particle, delay: f32 = 0) {
    if (!interval(&timer, delay)) do return;

    clone := new_clone(p);
    clone.position += position;
    append(&particles, clone);
}

ps_init :: proc(behaviours: []ParticleBehaviour) -> Particles {
    ps: Particles;

    ps_init_all(&ps);
    ps.behaviours = make([dynamic]ParticleBehaviour);
    append(&ps.behaviours, ..behaviours);

    return ps;
}

ps_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, ps := ecs.get_components(ent, Transform, Particles);
    if (is_nil(t, ps)) do return;
    using ps;

    position = t.position;

    for i in 0..<len(particles) {
        p := particles[i];
        p.life_time -= 10 * rl.GetFrameTime();

        if (p.life_time <= 0) do append(&_removed_particles, i);

        for behaviour in ps.behaviours {
            behaviour(p);
        }
    }

    for &p in _removed_particles {
        if (p != -1 && p < len(particles)) { 
            pr := particles[p];

            // free(pr.data.data);
            // free(pr);
            ordered_remove(&particles, p);
        }
        p = -1;
    }
}

ps_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    ps := ecs.get_component(ent, Particles);
    if (is_nil(ps)) do return;
    using ps;

    if (disable_depth_mask) { rl.rlDisableDepthMask(); }
    for p in particles {
        p->render();
    }
    if (disable_depth_mask) { rl.rlEnableDepthMask(); }
}

ps_parse :: proc(asset: od.Object) -> rawptr {
    life_time := asset["life_time"].(f32);

    color := od_color(asset["color"].(od.Object));

    def_beh := true;
    if (od_contains(asset, "default_behaviour")) {
        def_beh = asset["default_behaviour"].(bool);
    }

    gravity := Vec3 {0, -9.81, 0};
    if (od_contains(asset, "gravity")) {
        gravity = od_vec3(asset["gravity"].(od.Object));
    }

    ps := ps_init({default_behaviour});
    return new_clone(ps);
}

ps_loader :: proc(ent: AEntity, tag: string) {
    comp := get_component_data(tag, Particles);
    add_component(ent, comp^);
}
