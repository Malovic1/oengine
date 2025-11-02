package main

import rl "vendor:raylib"
import oe "../../oengine"

SelectMode :: enum {
    TRIANGLE,
    DATA_ID,
    PROP
}

editor_data: struct {
    hovered_data_id: string,
    active_data_id: string,
    csg_textures: map[oe.Vec3]oe.Texture,
    props: [dynamic]PropHandle,
    active_prop: i32,
    select_mode: map[SelectMode]bool,
};

PropHandle :: struct {
    ent_tag: string,
    model_tag: string,
    collider: oe.Transform,
    is_msc: bool,
    voxel_size: f32,
    model_tr: oe.Transform,
}
