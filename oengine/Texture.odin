package oengine


import str "core:strings"

Texture :: struct {
    using data: rl_Texture,
    path: string,
}

load_texture :: proc {
    load_texture_path,
    load_texture_data,
    load_texture_pro,
}

load_texture_path :: proc(s_path: string) -> Texture {
    return {
        data = rl_LoadTexture(str.clone_to_cstring(s_path)),
        path = s_path,
    };
}

load_texture_data :: proc(s_data: rl_Texture) -> Texture {
    return {
        data = s_data,
        path = DATA_PATH,
    };
}

load_texture_pro :: proc(s_path: string, s_data: rl_Texture) -> Texture {
    return {
        data = s_data,
        path = s_path,
    };
}

deinit_texture :: proc(texture: Texture) {
    rl_UnloadTexture(texture.data);
}

tex_flip_vert :: proc(texture: Texture) -> Texture {
    img := rl_LoadImageFromTexture(texture.data);
    rl_ImageFlipVertical(&img);

    return load_texture(texture.path, rl_LoadTextureFromImage(img));
}

tex_flip_horz :: proc(texture: Texture) -> Texture {
    img := rl_LoadImageFromTexture(texture.data);
    rl_ImageFlipHorizontal(&img);

    return load_texture(texture.path, rl_LoadTextureFromImage(img));
}

Image :: struct {
    data: rl_Image,
    path: string,
}

load_image :: proc {
    load_image_path,
    load_image_data,
    load_image_pro,
}

load_image_path :: proc(s_path: string) -> Image {
    return {
        data = rl_LoadImage(str.clone_to_cstring(s_path)),
        path = s_path,
    };
}

load_image_data :: proc(s_data: rl_Image) -> Image {
    return {
        data = s_data,
        path = DATA_PATH,
    };
}

load_image_pro :: proc(s_path: string, s_data: rl_Image) -> Image {
    return {
        data = s_data,
        path = s_path,
    };
}

deinit_image :: proc(texture: Image) {
    rl_UnloadImage(texture.data);
}
