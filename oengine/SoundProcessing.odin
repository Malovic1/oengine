package oengine


import "core:math"
import "base:runtime"

SoundFilter :: enum {
    NONE = 0,
    DISTORTION,
    LOWPASS,
    ECHO,
}

@(private = "file")
sound_filters := [?]rl_AudioCallback {
    nil,
    distort_filter,
    lpf_filter,
    echo_filter,
};

set_distortion_exponent :: proc(exp: f32) {
    distortion_exponent = exp;
}

@(private = "file")
distortion_exponent: f32 = 0.5;
distort_filter :: proc "c" (buffer: rawptr, frames: u32) {
    samples := cast([^]f32)buffer;

    for frame: u32; frame < frames; frame += 1 {
        left := &samples[frame * 2];
        right := &samples[frame * 2 + 1];

        left^ = math.pow(math.abs(left^), distortion_exponent) * ( (left^ < 0.0) ? -1.0 : 1.0);
        right^ = math.pow(math.abs(right^), distortion_exponent) * ( (right^ < 0.0) ? -1.0 : 1.0);
    }
}

// lowpass filter
lpf_filter :: proc "c" (buffer: rawptr, frames: u32) {
    @static low: Vec2;
    CUTOFF: f32 : 70.0 / 44100.0; // 70hz lowpass filter
    K: f32 : CUTOFF / (CUTOFF + 0.1591549431); // RC filter formula

    samples := cast([^]f32)buffer;
    for frame: u32; frame < frames * 2; frame += 2 {
        l := samples[frame];
        r := samples[frame + 1];

        low.x += K * (l - low.x);
        low.y += K * (r - low.y);

        samples[frame] = low.x;
        samples[frame + 1] = low.y;
    }
}

// wip, not recommended
echo_filter :: proc "c" (buffer: rawptr, frames: u32) {
    @static delay_buffer: [^]f32;
    @static delay_buffer_size: u32;
    @static delay_read_id: u32;
    @static delay_write_id: u32;
    delay_read_id = 2;
    delay_buffer_size = 48000 * 2;

    context = runtime.default_context();
    if (delay_buffer == nil) do delay_buffer = make([^]f32, delay_buffer_size);

    samples := cast([^]f32)buffer;
    for frame: u32; frame < frames * 2; frame += 2 {
        left_delay := delay_buffer[delay_read_id];
        delay_read_id += 1;
        righy_delay := delay_buffer[delay_read_id];
        delay_read_id += 1;

        if (delay_read_id == delay_buffer_size) do delay_read_id = 0;

        samples[frame] = 0.5 * samples[frame] + 0.5 * left_delay;
        samples[frame + 1] = 0.5 * samples[frame + 1] + 0.5 * righy_delay;

        delay_buffer[delay_write_id] = samples[frame];
        delay_write_id += 1;
        delay_buffer[delay_write_id] = samples[frame + 1];

        if (delay_write_id == delay_buffer_size) do delay_write_id = 0;
    }
}

attach_sound_filter :: proc(filter: SoundFilter) {
    if (filter == .NONE) do return;
    rl_AttachAudioMixedProcessor(sound_filters[i32(filter)]);
}

detach_sound_filter :: proc(filter: SoundFilter) {
    if (filter == .NONE) do return;
    rl_DetachAudioMixedProcessor(sound_filters[i32(filter)]);
}
