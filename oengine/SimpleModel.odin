package oengine

import "core:math"

SimpleModel :: struct {
    base: Model,
    armature: ModelArmature,
}

apply_model_anims :: proc(model: Model, ma: ^ModelArmature, id: i32) {
    ma.frame_counter += ma.speed * rl_GetFrameTime();
    fc := i32(math.floor(ma.frame_counter));
    rl_UpdateModelAnimation(model, ma.animations[id], fc);

    if (fc >= ma.animations[id].frameCount) {
        ma.frame_counter = 0;
    }
}
