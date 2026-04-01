package oengine

import rl "vendor:raylib"
import str "core:strings"
import "core:mem"

Model :: struct {
    using data: rl.Model,
    path: string,
    tex_filtering: rl.TextureFilter,
    excluded_mesh: i32,
}

load_model :: proc {
    load_model_path,
    load_model_data,
    load_model_pro,
}

load_model_path :: proc(s_path: string) -> Model {
    return {
        data = rl.LoadModel(str.clone_to_cstring(s_path)),
        path = s_path,
        excluded_mesh = -1,
    };
}

load_model_data :: proc(s_data: rl.Model) -> Model {
    return {
        data = s_data,
        path = DATA_PATH,
        excluded_mesh = -1,
    };
}

load_model_pro :: proc(s_path: string, s_data: rl.Model) -> Model {
    return {
        data = s_data,
        path = s_path,
        excluded_mesh = -1,
    };
}

// models can have animation so you have to clone it for using it with seperate 
// components if you dont want the animation to affect all of them
model_clone :: proc(m: Model) -> Model {
    res := load_model(str.clone(m.path));
    set_model_tex_filter(res, m.tex_filtering);
    return res;
}

model_mat_clone :: proc(m: Model) -> Model {
    clone := m;
    clone.materials[0] = rl.LoadMaterialDefault();
    if (m.materialCount > 0) {
        clone.materials = cast(^rl.Material)rl.MemAlloc(
            u32(m.materialCount * size_of(rl.Material))
        );

        for i in 0..<m.materialCount {
            clone.materials[i] = m.materials[i];
        }
    }

    return clone;
}

deinit_model :: proc(Model: Model) {
    rl.UnloadModel(Model.data);
}
