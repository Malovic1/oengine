package oengine

import "core:fmt"
import "core:io"
import "core:os"
import "core:path/filepath"
import sc "core:strconv"
import strs "core:strings"
import rl "vendor:raylib"
import "fa"
import od "object_data"
import "core:encoding/json"
import "core:thread"
import "core:sync"

MAX_DIDS :: 2048
MAX_TEXTURES :: 2048

ComponentMarshall :: struct {
    tag, type: string
}

DataID :: struct {
    reg_tag: string, // tag registerd in registry
    tag: string,
    id: u32,
    transform: Transform,
    flags: fa.FixedArray(i32, 16),
    comps: fa.FixedArray(ComponentMarshall, 16),
}

Asset :: union {
    Texture,
    Model,
    Shader,
    CubeMap,
    Sound,
    DataID,
}

LazyAsset :: struct {
    loaded: bool,
    data: Asset,
}

// LoadInstruction :: #type proc(asset_json: json.Object) -> rawptr
LoadInstruction :: #type proc(asset: od.Object) -> rawptr
LoaderFunc :: #type proc(ent: AEntity, tag: string)

ComponentParse :: struct {
    name: string,
    instr: LoadInstruction
}

ComponentType :: struct {
    name: string,
    type: typeid,
}

asset_manager: struct {
    registry: map[string]Asset,
    component_types: map[ComponentParse]typeid,
    component_loaders: map[string]LoaderFunc,
    component_reg: map[ComponentType]rawptr,
}

reg_component :: proc(
    t: typeid, 
    instr: LoadInstruction = nil, 
    loader: LoaderFunc = nil
) {
    using asset_manager;
    tag := fmt.aprintf("%v", t);

    component_types[{tag, instr}] = t;
    component_loaders[tag] = loader;
}

get_component_type :: proc(s: string) -> typeid {
    using asset_manager;
    for k, v in component_types {
        if (k.name == s) do return v;
    }

    return nil;
}

get_component_instr :: proc(s: string) -> LoadInstruction {
    using asset_manager;
    for k, v in component_types {
        if (k.name == s) do return k.instr;
    }

    return nil;
}

get_component_data :: proc(s: string, $T: typeid) -> ^T {
    comp := cast(^T)asset_manager.component_reg[{s, T}];
    return new_clone(comp^);
}

save_registry :: proc(path: string) {
    if (filepath.ext(path) == ".od") {
        save_registry_od(path);
        return;
    }

    save_registry_json(path);
}

save_registry_od :: proc(path: string) {
    using asset_manager;
    mode := FileMode.WRITE_RONLY | FileMode.CREATE;
    file := file_handle(path, mode);
    res: string;

    TextureMarshal :: struct {
        path: string,
        type: string,
    }
    
    ModelMarshal :: struct {
        path: string,
        type: string,
    }

    SoundMarshal :: struct {
        path: string,
        volume: f32,
        type: string,
    }

    CubeMapMarshal :: struct {
        type: string,
        path_front: string,
        path_back: string,
        path_left: string,
        path_right: string,
        path_top: string,
        path_bottom: string,
    }

    for tag, asset in registry {
        #partial switch var in asset {
            case Texture:
                tm := TextureMarshal { var.path, "Texture" };
                res = str_add({res, od.marshal(tm, TextureMarshal, tag), "\n"});
            case Model:
                mm := ModelMarshal { var.path, "Model" };
                res = str_add({res, od.marshal(mm, ModelMarshal, tag), "\n"});
            case Sound:
                sm := SoundMarshal { var.path, var.volume, "Sound" };
                res = str_add({res, od.marshal(sm, SoundMarshal, tag), "\n"});
            case CubeMap:
                cmm := CubeMapMarshal {
                    "CubeMap",
                    var[0].path,
                    var[1].path,
                    var[2].path,
                    var[3].path,
                    var[4].path,
                    var[5].path,
                };
                res = str_add({res, od.marshal(cmm, CubeMapMarshal, tag), "\n"});
        }
    }

    file_write(file, res);
    file_close(file);
}

save_registry_json :: proc(path: string) {
    using asset_manager;
    mode := FileMode.WRITE_RONLY | FileMode.CREATE;
    file := file_handle(path, mode);

    res := "{";

    for tag, asset in registry {
        #partial switch var in asset {
            case Texture:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n",
                        "\t\t\"path\": \"", strs.clone(var.path), "\",\n",
                        "\t\t\"type\": \"", "Texture", "\"",
                    "\n\t},"}
                );
            case Model:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n",
                        "\t\t\"path\": \"", var.path, "\",\n",
                        "\t\t\"type\": \"", "Model", "\"",
                    "\n\t},"}
                );
            case CubeMap:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n",
                        "\t\t\"type\": \"", "CubeMap", "\",\n",
                        "\t\t\"path_front\": \"", strs.clone(var[0].path), "\",\n",
                        "\t\t\"path_back\": \"", strs.clone(var[1].path), "\",\n",
                        "\t\t\"path_left\": \"", strs.clone(var[2].path), "\",\n",
                        "\t\t\"path_right\": \"", strs.clone(var[3].path), "\",\n",
                        "\t\t\"path_top\": \"", strs.clone(var[4].path), "\",\n",
                        "\t\t\"path_bottom\": \"", strs.clone(var[5].path), "\"",
                    "\n\t},"}
                );
            case Sound:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n",
                        "\t\t\"path\": \"", strs.clone(var.path), "\",\n",
                        "\t\t\"volume\": \"", strs.clone(str_add("", var.volume)), "\",\n",
                        "\t\t\"type\": \"", "Sound", "\"",
                    "\n\t},"}
                );
        }
    }

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

TagObjectPair :: struct {
    tag: string,
    object: od.Object,
}

AssetJob :: struct {
    tag: string,
    type: string,
    data: od.Object,
}

CJobPair :: struct{tag: string, asset: [6]Image}
TJobPair :: struct{tag: string, asset: Image}
MJobPair :: struct{tag: string, path: string}
cubemap_job: [dynamic]CJobPair;
texture_job: [dynamic]TJobPair;
model_job: [dynamic]MJobPair;
jobs_done: i32;

load_asset_job :: proc(_data: rawptr) {
    job := cast(^AssetJob)_data;
    tag := job.tag;
    data := job.data;

    if job.type == "CubeMap" {
        front := get_path(data["path_front"].(string));
        back := get_path(data["path_back"].(string));
        left := get_path(data["path_left"].(string));
        right := get_path(data["path_right"].(string));
        top := get_path(data["path_top"].(string));
        bottom := get_path(data["path_bottom"].(string));

        sky := [6]Image {
            load_image(strs.clone(front)), load_image(strs.clone(back)),
            load_image(strs.clone(left)), load_image(strs.clone(right)),
            load_image(strs.clone(top)), load_image(strs.clone(bottom)),
        };
        // reg_asset(strs.clone(tag), sky);
        append(&cubemap_job, CJobPair {strs.clone(tag), sky});
    } else if job.type == "Sound" {
        path := get_path(data["path"].(string));
        vol, ok := sc.parse_f32(data["path"].(string));
        res := load_sound(strs.clone(path));
        if ok do set_sound_vol(&res, vol);
        reg_asset(strs.clone(tag), res);
    } else if job.type == "Texture" {
        res := get_path(data["path"].(string));
        tex := load_image(strs.clone(res));
        // reg_asset(strs.clone(tag), tex);
        append(&texture_job, TJobPair{strs.clone(tag), tex});
    } else if job.type == "Model" {
        res := get_path(data["path"].(string));
        // mdl := load_model(strs.clone(res));
        // reg_asset(strs.clone(tag), mdl);
        append(&model_job, MJobPair{strs.clone(tag), res});
    }

    sync.atomic_add(&jobs_done, 1);
    if (OE_DEBUG) {
        dbg_log(str_add("Finished job: ", sync.atomic_load(&jobs_done)));
    }
}

load_registry :: proc(path: string, threaded := false) {
    if (filepath.ext(path) == ".od") {
        load_registry_od(path, threaded);
        return;
    }

    load_registry_json(path);
}

// threaded is wip, it works and is faster but unstable and tends to not load some stuff
load_registry_od :: proc(path: string, threaded := false) {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return;
    }

    od_data := od.parse(string(data));
    root := od_data;

    second_pass := make([dynamic]TagObjectPair);

    threads: [dynamic]^thread.Thread;
    if (threaded) {
        threads = make([dynamic]^thread.Thread);
    }

    for tag, asset in root {
        if (tag == "dbg_pos") {
            val := asset.(i32);
            window._dbg_stats_pos = val;
            continue;
        } else if (tag == "exe_path") {
            val := asset.(string);
            epath: string;
            s_id, e_id: i32;
            semi0, semi1: i32 = -1, -1;

            for i in 0..<len(val) {
                c := val[i];
                if (c == '{') { s_id = auto_cast i; }
                else if (c == '}') { e_id = auto_cast i; }
                else if (c == ';') {
                    if (semi0 == -1) { semi0 = auto_cast i; }
                    else { semi1 = auto_cast i; }
                }
            }

            epath = val[:s_id];
            platform := sys_os();
            plat: string;
            if (platform == .Windows) { plat = val[s_id + 1:semi0]; }
            else if (platform == .Linux) { plat = val[semi0 + 1:semi1]; }
            else if (platform == .Darwin) { plat = val[semi1 + 1:e_id]; }
            epath = str_add(epath, plat);
            epath = str_add(epath, val[e_id + 1:]);

            window._exe_path = strs.clone(epath);
            continue;
        }

        asset_od := asset.(od.Object);
        type := asset_od["type"].(string);

        if (type == "CubeMap" || 
            type == "Sound" || 
            type == "Texture" || 
            type == "Model") {
            job := new(AssetJob);
            job^ = AssetJob{strs.clone(tag), type, asset_od};

            if (threaded) {
                h := thread.create_and_start_with_data(job, load_asset_job);
                append(&threads, h);
            } else {
                load_asset_job(job);
            }
        } else {
            append(&second_pass, TagObjectPair{strs.clone(tag), asset_od});
        }
    }

    if (threaded) {
        for h in threads { thread.join(h); }
    }

    for pair in cubemap_job {
        sky: CubeMap;

        for i in 0..<len(pair.asset) {
            sky[i] = load_texture(
                pair.asset[i].path,
                rl.LoadTextureFromImage(pair.asset[i].data)
            );
            deinit_image(pair.asset[i]);
        }

        reg_asset(pair.tag, sky);
    }

    for pair in texture_job {
        reg_asset(
            pair.tag, 
            load_texture(pair.asset.path, rl.LoadTextureFromImage(pair.asset.data))
        );
        deinit_image(pair.asset);
    }

    for pair in model_job {
        mdl := load_model(pair.path);
        reg_asset(pair.tag, mdl);
    }

    clear(&cubemap_job);
    clear(&texture_job);
    clear(&model_job);

    for pair in second_pass {
        tag := pair.tag;
        asset_od := pair.object;
        type := asset_od["type"].(string);

        if (type == "CubeMap" || 
            type == "Sound" || 
            type == "Texture" || 
            type == "Model") { continue; }

        ct := ComponentType {
            name = tag,
            type = get_component_type(type),
        };

        instr := get_component_instr(type);
        if (instr != nil) {
            asset_manager.component_reg[ct] = instr(asset_od);
        } else {
            dbg_log("Parse instructions are nil", .ERROR);
        }
    }

    defer delete(data);
    defer delete(second_pass);
    defer delete(threads);
}

load_registry_json :: proc(path: string) {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return;
    }

    json_data, err := json.parse(data);
    if (err != json.Error.None) {
		dbg_log("Failed to parse the json file", DebugType.WARNING);
		dbg_log(str_add("Error: ", err), DebugType.WARNING);
		return;
	}

    root := json_data.(json.Object);

    // first load assets
    for tag, asset in root {
        if (tag == "dbg_pos") {
            val := i32(asset.(json.Float));
            window._dbg_stats_pos = val;
            continue;
        } else if (tag == "exe_path") {
            val := asset.(json.String);
            epath: string;
            s_id, e_id: i32;
            semi0, semi1: i32 = -1, -1;

            for i in 0..<len(val) {
                c := val[i];
                if (c == '{') {
                    s_id = auto_cast i;
                } else if (c == '}') {
                    e_id = auto_cast i;
                } else if (c == ';') {
                    if (semi0 == -1) {
                        semi0 = auto_cast i;
                    } else {
                        semi1 = auto_cast i;
                    }
                }
            }

            epath = val[:s_id];
            
            plat: string;
            if (sys_os() == .Windows) {
                plat = val[s_id + 1:semi0]; 
            } else if (sys_os() == .Linux) {
                plat = val[semi0 + 1:semi1];
            } else if (sys_os() == .Darwin) {
                plat = val[semi1 + 1:e_id];
            }
            epath = str_add(epath, plat);
            epath = str_add(epath, val[e_id + 1:]);

            window._exe_path = strs.clone(epath);

            continue;
        }

        asset_json := asset.(json.Object);
        type := asset_json["type"].(json.String);

        if (type == "CubeMap") {
            front := get_path(asset_json["path_front"].(json.String));
            back := get_path(asset_json["path_back"].(json.String));
            left := get_path(asset_json["path_left"].(json.String));
            right := get_path(asset_json["path_right"].(json.String));
            top := get_path(asset_json["path_top"].(json.String));
            bottom := get_path(asset_json["path_bottom"].(json.String));

            reg_asset(strs.clone(tag), SkyBox {
                load_texture(strs.clone(front)), load_texture(strs.clone(back)),
                load_texture(strs.clone(left)), load_texture(strs.clone(right)),
                load_texture(strs.clone(top)), load_texture(strs.clone(bottom)),
            });
        } else if (type == "Sound") {
            path := get_path(asset_json["path"].(json.String));
            vol, ok := sc.parse_f32(asset_json["path"].(json.String));
            res := load_sound(strs.clone(path));
            if (ok) do set_sound_vol(&res, vol);

            reg_asset(strs.clone(tag), res);
        } else if (type == "Texture") {
            res := get_path(asset_json["path"].(json.String));

            tex := load_texture(strs.clone(res));
            reg_asset(strs.clone(tag), tex);
        } else if (type == "Model") {
            res := get_path(asset_json["path"].(json.String));
            reg_asset(strs.clone(tag), load_model(strs.clone(res)));
        }
    }

    // then load components
    for tag, asset in root {
        if (tag == "dbg_pos" || tag == "exe_path") { continue; }

        asset_json := asset.(json.Object);
        type := asset_json["type"].(json.String);

        if (type == "CubeMap" ||
            type == "Sound" ||
            type == "Texture" ||
            type == "Model") { continue; }

        ct := ComponentType {
            name = strs.clone(tag),
            type = get_component_type(type),
        };

        instr := get_component_instr(type);
        if (instr != nil) {
            asset_manager.component_reg[ct] = instr(od.json_to_od(asset_json));
        } else {
            dbg_log("Parse instructions are nil", .ERROR);
        }
    }

    delete(data);
    json.destroy_value(json_data);
}

reload_assets :: proc() {
    using asset_manager;

    for tag, &asset in registry {
        if (asset_has_path(asset)) {
            load_asset(&asset);
        }
    }
}

am_texture_atlas :: proc() -> Atlas {
    atlas := init_atlas();
    textures := get_reg_textures_arr();
    if len(textures) == 0 {
        return atlas;
    }

    for i in 0..<len(textures) {
        max_index := i;
        for j in i+1..<len(textures) {
            area_j := textures[j].width * textures[j].height;
            area_max := textures[max_index].width * textures[max_index].height;
            if area_j > area_max {
                max_index = j;
            }
        }

        if max_index != i {
            temp := textures[i];
            textures[i] = textures[max_index];
            textures[max_index] = temp;
        }
    }

    // Estimate total size (simple vertical stack)
    width: i32 = 0;
    height: i32 = 0;
    for tex in textures {
        width = max(width, tex.width);
        height += tex.height;
    }

    atlas.width = width;
    atlas.height = height;

    render_target := rl.LoadRenderTexture(width, height);
    rl.BeginTextureMode(render_target);
    rl.ClearBackground(BLANK);

    free_rects := make([dynamic]Rect);
    append(&free_rects, Rect{0, 0, f32(width), f32(height)});

    for tex in textures {
        placement := find_best_fit_rect(&free_rects, tex.width, tex.height);
        if placement.width == 0 || placement.height == 0 {
            break; // No space left
        }

        rect := Rect{placement.x, placement.y, f32(tex.width), f32(tex.height)};
        atlas_texture(&atlas, rect, tex.tag, true);

        rl.DrawTexturePro(
            tex,
            {0, 0, f32(tex.width), f32(tex.height)},
            {rect.x, rect.y, rect.width, rect.height},
            {0, 0}, 0, WHITE
        );

        split_free_space(&free_rects, rect);
    }

    rl.EndTextureMode();
    atlas.texture = tex_flip_vert(load_texture(render_target.texture));

    return atlas;
}

@(private)
asset_has_path :: proc(asset: Asset) -> bool {
    if (!asset_is(asset, DataID)) {
        return true;
    }

    return false;
}

load_asset :: proc(asset: ^Asset) {
    #partial switch &v in asset {
        case Texture:
            v = load_texture(v.path);
            dbg_log(str_add("Loading texture: ", v.path));
        case Model:
            v = load_model(v.path);
            dbg_log(str_add("Loading model: ", v.path));
        case Shader:
            v = load_shader(v.v_path, v.f_path);
            dbg_log(str_add("Loading shader: ", v.v_path));
            dbg_log(str_add("Loading shader: ", v.f_path));
        case CubeMap:
            for &i in v {
                i = load_texture(i.path);
                dbg_log(str_add("Loading cubemap texture: ", i.path));
            }
        case Sound:
            v = load_sound(v.path);
            dbg_log(str_add("Loading sound: ", v.path));
    }
}

@(private)
get_path :: proc(path: string) -> string {
    absolute, ok := filepath.abs(path);
    res, err := filepath.rel(string(rl.GetWorkingDirectory()), absolute);
    t: bool;
    res, t = strs.replace_all(res, "\\", "/");
    return res;
}

get_reg_data_ids :: proc() -> [dynamic]DataID {
    using asset_manager;

    res := make([dynamic]DataID);

    for tag, asset in registry {
        if (asset_is(asset, DataID)) {
            append(&res, asset_variant(asset, DataID));
        }
    }

    return res;
}

get_reg_textures :: proc() -> fa.FixedMap(string, Texture, MAX_TEXTURES) {
    using asset_manager;

    res := fa.fixed_map(string, Texture, MAX_TEXTURES);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            fa.map_set(&res, tag, asset_variant(asset, Texture));
        }
    }

    return res;
}

TextureTag :: struct {
    using handle: Texture,
    tag: string,
}

get_reg_textures_arr :: proc() -> [dynamic]TextureTag {
    using asset_manager;

    res := make([dynamic]TextureTag);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            append(&res, TextureTag{asset_variant(asset, Texture), tag});
        }
    }

    return res;
}

get_reg_textures_tags :: proc() -> fa.FixedArray(string, MAX_TEXTURES) {
    using asset_manager;

    res := fa.fixed_array(string, MAX_TEXTURES);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            fa.append(&res, tag);
        }
    }

    return res;
}

asset_variant :: proc(self: Asset, $T: typeid) -> T {
    return self.(T);
}

asset_is :: proc(self: Asset, $T: typeid) -> bool {
    #partial switch v in self {
        case T: return true;
    }

    return false;
}

asset_mutex: sync.Mutex;
reg_asset :: proc(tag: string, asset: Asset) {
    using asset_manager;
    sync.lock(&asset_mutex);
    defer sync.unlock(&asset_mutex);
    #partial switch &v in asset {
        case Texture:
            rl.GenTextureMipmaps(&v);
            rl.rlTextureParameters(
                v.id, 
                rl.RL_TEXTURE_MIN_FILTER,
                rl.RL_TEXTURE_FILTER_MIP_LINEAR, 
            );
    }
    registry[tag] = asset;
}

unreg_asset :: proc(tag: string) {
    using asset_manager;
    registry[tag] = nil;
}

get_asset :: proc(tag: string) -> Asset {
    using asset_manager;

    if (registry[tag] == nil) {
        dbg_log(str_add({"Asset ", tag, " doesn\'t exist"}), DebugType.WARNING);
        return nil;
    }

    return registry[tag];
}

get_asset_var :: proc(tag: string, $T: typeid) -> T {
    using asset_manager;

    if (registry[tag] == nil) {
        dbg_log(str_add({"Asset ", tag, " doesn\'t exist"}), DebugType.WARNING);
    }

    return asset_variant(registry[tag], T);
}

asset_exists :: proc(tag: string) -> bool {
    return asset_manager.registry[tag] != nil;
}

deinit_assets :: proc() {
    using asset_manager;
    for i, v in registry {
        if (asset_is(v, Texture)) do deinit_texture(get_asset_var(i, Texture));
        else if (asset_is(v, Model)) do deinit_model(get_asset_var(i, Model));
        else if (asset_is(v, Shader)) do deinit_shader(get_asset_var(i, Shader));
        else if (asset_is(v, CubeMap)) do deinit_cubemap(get_asset_var(i, CubeMap));
        else if (asset_is(v, Sound)) do deinit_sound(get_asset_var(i, Sound));
    }
}
