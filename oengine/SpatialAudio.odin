package oengine

import "ecs"
import "core:fmt"
import rl "vendor:raylib"
import "core:encoding/json"
import od "object_data"

MAX_SOUND_DISTANCE :: 10

SpatialAudio :: struct {
    sound: Sound,
    position, _target: Vec3,
    strength: f32,
    can_play: bool,
}

sa_init :: proc(position: Vec3, s_sound: Sound) -> SpatialAudio {
    return SpatialAudio {
        sound = s_sound,
        position = position,
        strength = 1,
        can_play = true
    };
}

sa_play :: proc(using self: ^SpatialAudio) {
    if (!rl.IsSoundPlaying(sound) && can_play) {
        play_sound(sound);
    }
}

sa_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, sa := ecs.get_components(ent, Transform, SpatialAudio);
    if (is_nil(t, sa)) do return;
    using sa;

    position = t.position;

    if (ecs_world.camera != nil) { 
        _target = ecs_world.camera.position; 
    }

    dist := vec3_dist(_target, position);
    strength = 1.0 / (dist / MAX_SOUND_DISTANCE + 1.0);
    strength = clamp(strength, 0.0, 1.0); 

    rl.SetSoundVolume(sound, strength);
}

sa_parse :: proc(asset: od.Object) -> rawptr {
    sound_tag := asset["sound"].(string);
    sound := get_asset_var(sound_tag, Sound);

    strength := asset["strength"].(f32);

    can_play := true;
    if (od_contains(asset, "can_play")) {
        can_play = asset["can_play"].(bool);
    }

    sa := sa_init({}, sound);
    sa.strength = strength;
    sa.can_play = can_play;
    return new_clone(sa);
}

sa_loader :: proc(ent: AEntity, tag: string) {
    comp := get_component_data(tag, SpatialAudio);
    add_component(ent, comp^);
}
