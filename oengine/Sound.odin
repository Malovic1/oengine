package oengine

import rl "vendor:raylib"
import str "core:strings"
import "core:math/linalg"

Sound :: struct {
    using data: rl.Sound,
    path: string,
    volume: f32,
}

load_sound :: proc {
    load_sound_path,
    load_sound_data,
    load_sound_pro,
}

load_sound_path :: proc(s_path: string) -> Sound {
    return {
        data = rl.LoadSound(str.clone_to_cstring(s_path)),
        path = s_path,
        volume = 1.0,
    };
}

load_sound_data :: proc(s_data: rl.Sound) -> Sound {
    return {
        data = s_data,
        path = DATA_PATH,
        volume = 1.0,
    };
}

load_sound_pro :: proc(s_path: string, s_data: rl.Sound) -> Sound {
    return {
        data = s_data,
        path = s_path,
        volume = 1.0,
    };
}

play_sound :: proc(using self: Sound) {
    rl.PlaySound(self);
}

// 0.0 - 1.0
set_sound_vol :: proc(using self: ^Sound, s_volume: f32) {
    volume = s_volume;
    rl.SetSoundVolume(self, volume);
}

position_sound :: proc(
    listener: Camera,
    sound: ^Sound,
    position: Vec3,
    max_dist: f32,
    strength: f32, // 0..1 (or >1 if you want boosts)
) {
    direction := position - listener.position;
    distance := linalg.length(direction);

    attenuation := 1.0 / (1.0 + (distance / max_dist));
    attenuation = linalg.clamp(attenuation, 0, 1);

    normalized_dir := linalg.normalize(direction);
    forward := linalg.normalize(listener.target - listener.position);
    right := linalg.normalize(linalg.cross(listener.up, forward));

    dot_product := linalg.dot(forward, normalized_dir);
    if dot_product < 0 {
        attenuation *= (1.0 + dot_product * 0.5);
    }

    pan := 0.5 + 0.5 * linalg.dot(normalized_dir, right);

    attenuation *= strength;
    attenuation = linalg.clamp(attenuation, 0, 1);

    set_sound_vol(sound, attenuation);
    rl.SetSoundPan(sound^, pan);
}

deinit_sound :: proc(sound: Sound) {
    rl.UnloadSound(sound);
}
