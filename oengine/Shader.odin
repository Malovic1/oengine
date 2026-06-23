package oengine


import strs "core:strings"

Shader :: struct {
    using data: rl_Shader,
    v_path, f_path: string,
}

load_shader :: proc {
    load_shader_path,
    load_shader_data,
    load_shader_pro,
}

load_shader_path :: proc(sv_path, sf_path: string) -> Shader {
    return {
        data = rl_LoadShader(strs.clone_to_cstring(sv_path), strs.clone_to_cstring(sf_path)),
        v_path = sv_path,
        f_path = sf_path,
    };
}

load_shader_data :: proc(s_data: rl_Shader) -> Shader {
    return {
        data = s_data,
        v_path = DATA_PATH,
        f_path = DATA_PATH,
    };
}

load_shader_pro :: proc(sv_path, sf_path: string, s_data: rl_Shader) -> Shader {
    return {
        data = s_data,
        v_path = sv_path,
        f_path = sf_path,
    };
}

deinit_shader :: proc(shader: Shader) {
    rl_UnloadShader(shader.data);
}

shader_defined :: proc(using shader: Shader) -> bool {
    return v_path != "" || f_path != "";
}
