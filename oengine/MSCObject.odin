package oengine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import "core:encoding/json"
import "core:io"
import "core:os"
import strs "core:strings"
import "fa"
import od "object_data"
import "core:path/filepath"
import "core:math/linalg"
import "core:time"

/*
EXAMPLE

msc := oe.msc_init();
oe.msc_append_tri(msc, {0, 0, 0}, {10, 0, 0}, {5, 10, 0}, {0, 0.5, 0});
oe.msc_append_quad(msc, {0, 0, 0}, {10, 0, 0}, {0, 10, 10}, {10, 10, 10}, {10, 0, 20});
oe.msc_append_quad(msc, {0, 0, 0}, {10, 0, 0}, {0, 0, 10}, {10, 0, 10}, {10, 10, 30});
oe.msc_append_quad(msc, {0, 0, 0}, {0, 10, 5}, {10, 0, 0}, {10, 10, 0}, {10, 10, 40});
oe.msc_append_quad(msc, {0, 0, 0}, {10, 0, 0}, {0, 0, 10}, {10, 0, 10}, {10, 10, 40});

oe.msc_to_json(msc, "../assets/maps/test.json");
oe.msc_from_json(msc, "../assets/maps/test.json");

oe.msc_init_atlas(msc, "../assets/atlas.png");
oe.atlas_texture(&msc.atlas, {0, 0, 256, 256}, "albedo");
oe.atlas_texture(&msc.atlas, {256, 0, 256, 256}, "water");
oe.atlas_texture(&msc.atlas, {256 * 2, 0, 256, 256}, "tile");
*/

tri_count: i32;

AtlasTexture :: struct {
    tag: string,
    uvs: [4]Vec2,
}

Atlas :: struct {
    using texture: Texture,
    subtextures: [dynamic]AtlasTexture, 
}

init_atlas :: proc() -> Atlas {
    return {
        subtextures = make([dynamic]AtlasTexture),
    };
}

load_atlas :: proc(path: string) -> Atlas {
    res := init_atlas();
    
    img_path := str_add(path, "/atlas.png");
    res.texture = load_texture(img_path);

    data_path := str_add(path, "/atlas.od");
    data, ok := os.read_entire_file_from_filename(data_path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return {};
    }
    defer delete(data);

    od_data := od.parse(string(data));
    root := od_data;

    for k, v in root {
        if (k == "path") { continue; }

        texture_text := "texture";
        if (k[:len(texture_text)] == "texture") {
            tex_data := v.(od.Object);
            texture_tag := tex_data["tag"].(string);
            texture_uvs := tex_data["uvs"].(od.Object);
            uv0 := Vec2{
                texture_uvs["uv_0"].(od.Object)["x"].(f32),
                texture_uvs["uv_0"].(od.Object)["y"].(f32),
            };
            uv1 := Vec2{
                texture_uvs["uv_1"].(od.Object)["x"].(f32),
                texture_uvs["uv_1"].(od.Object)["y"].(f32),
            };
            uv2 := Vec2{
                texture_uvs["uv_2"].(od.Object)["x"].(f32),
                texture_uvs["uv_2"].(od.Object)["y"].(f32),
            };
            uv3 := Vec2{
                texture_uvs["uv_3"].(od.Object)["x"].(f32),
                texture_uvs["uv_3"].(od.Object)["y"].(f32),
            };

            uvs := [4]Vec2 {
                uv0, uv1, uv2, uv3
            };

            at := AtlasTexture {
                tag = strs.clone(texture_tag),
                uvs = uvs,
            };

            append(&res.subtextures, at);
        } 
    }

    return res;
}

atlas_texture :: proc(atlas: ^Atlas, rec: Rect, tag: string, flipped := false) {
    dims := Vec2{f32(atlas.width), f32(atlas.height)};
    uvs: [4]Vec2;
    uvs[0] = {rec.x, rec.y} / dims;
    uvs[1] = {rec.x + rec.width, rec.y} / dims;
    uvs[2] = {rec.x + rec.width, rec.y + rec.height} / dims;
    uvs[3] = {rec.x, rec.y + rec.height} / dims;

    if (flipped) {
        uvs[0] = {rec.x + rec.width, rec.y + rec.height} / dims;
        uvs[1] = {rec.x, rec.y + rec.height} / dims;
        uvs[2] = {rec.x, rec.y} / dims;
        uvs[3] = {rec.x + rec.width, rec.y} / dims;
    } else {
        uvs[0] = {rec.x, rec.y} / dims;
        uvs[1] = {rec.x + rec.width, rec.y} / dims;
        uvs[2] = {rec.x + rec.width, rec.y + rec.height} / dims;
        uvs[3] = {rec.x, rec.y + rec.height} / dims;
    }

    at := AtlasTexture {
        tag = tag,
        uvs = uvs,
    };

    append(&atlas.subtextures, at);
}

atlas_texture_rec :: proc(atlas: Atlas, at: AtlasTexture, flipped := false) -> Rect {
    dims := Vec2{ f32(atlas.width), f32(atlas.height) };
    if (!flipped) {
        x := at.uvs[0].x * dims.x;
        y := at.uvs[0].y * dims.y;
        return {
            x = x, y = y,
            width = (at.uvs[2].x - x) * dims.x,
            height = (at.uvs[2].y - y) * dims.y,
        };
    }

    x := at.uvs[2].x * dims.x;
    y := at.uvs[2].y * dims.y;
    return {
        x = x, y = y,
        width = (at.uvs[0].x - x) * dims.x,
        height = (at.uvs[0].y - y) * dims.y,
    };
}

ODVec2 :: struct { x, y: f32 }
vec2_to_od :: proc(v: Vec2) -> ODVec2 {
    return ODVec2 {v.x, v.y};
}

save_atlas :: proc(atlas: Atlas, path: string) {
    file := file_handle(path, FileMode.WRITE_RONLY | FileMode.CREATE);
    res: string;

    res = str_add({res, od.marshal(atlas.path, string, "path"), "\n"});

    SubTextureMarshal :: struct {
        tag: string,
        uvs: struct {
            uv_0: ODVec2,
            uv_1: ODVec2,
            uv_2: ODVec2,
            uv_3: ODVec2,
        },
    }

    for i in 0..<len(atlas.subtextures) {
        uvs := atlas.subtextures[i].uvs;
        stm := SubTextureMarshal {
            tag = atlas.subtextures[i].tag,
            uvs = {
                vec2_to_od(uvs[0]), 
                vec2_to_od(uvs[1]), 
                vec2_to_od(uvs[2]), 
                vec2_to_od(uvs[3])
            },
        };

        res = str_add({
            res, 
            od.marshal(stm, SubTextureMarshal, str_add("texture", i)),
            "\n"
        });
    }

    file_write(file, res);
    file_close(file);
}

pack_atlas :: proc(atlas: Atlas, path: string) {
    create_dir(path);

    img := rl.LoadImageFromTexture(atlas.texture);
    img_path := str_add({path, "/atlas.png"});
    rl.ExportImage(img, strs.clone_to_cstring(img_path));

    data_path := str_add({path, "/atlas.od"});
    res := atlas;
    res.path = img_path;
    save_atlas(res, data_path);
}

MSCObject :: struct {
    tris: [dynamic]TriangleCollider,
    mesh_tris: [dynamic]TriangleCollider,
    _aabb: AABB,
    tree: ^OctreeNode,
    mesh: rl.Mesh,
    atlas: Atlas,
    render: bool,
    mesh_tri_count: i32,
}

msc_init :: proc() -> ^MSCObject {
    using self := new(MSCObject);

    tris = make([dynamic]TriangleCollider);
    mesh_tris = make([dynamic]TriangleCollider);
    render = true;

    fa.append(&ecs_world.physics.mscs, self);

    return self;
}

msc_build :: proc(using self: ^MSCObject) {
    tree = build_octree(tris, _aabb, 0);
}

msc_init_atlas :: proc(using self: ^MSCObject, path: string) {
    atlas = init_atlas();
    atlas.texture = load_texture(path);
}

remove_msc :: proc(using self: ^MSCObject) {
    fa.remove(&ecs_world.physics.mscs, fa.get_id(ecs_world.physics.mscs, self));
    tri_count -= i32(len(tris));
    free(self);
}

msc_append_tri :: proc(
    using self: ^MSCObject, 
        a, b, c: Vec3, 
        offs: Vec3 = {}, 
        color: Color = WHITE, 
        texture_tag: string = "", 
        is_lit: bool = true, 
        use_fog: bool = OE_FAE, rot: i32 = 0, normal: Vec3 = {},
        flipped := false, division_level: i32 = 0) {
    t: TriangleCollider;
    t.pts = {a + offs, b + offs, c + offs};
    t.normal = normal;
    t.color = color;
    t.texture_tag = texture_tag;
    t.rot = rot;
    t.is_lit = is_lit;
    t.use_fog = use_fog;
    t.flipped = flipped;
    t.division_level = division_level;

    if (flipped) {
        t.normal = -t.normal;
    }

    add := true;
    for i in 0..<len(tris) {
        _t := tris[i];
        if (_t.pts == t.pts) {
            add = false;
            break;
        }
    }

    if (add) { 
        append(&tris, t);
        subdivide_triangle_coll(t, t.division_level, &mesh_tris);
    }
    tri_count += 1;
    mesh_tri_count += i32(math.pow(4.0, f32(t.division_level)));

    _aabb = tris_to_aabb(tris);
}

msc_append_quad :: proc(
    using self: ^MSCObject,
    a, b, c, d: Vec3,
    offs: Vec3 = {}, color: Color = WHITE,
    texture_tag: string = "", is_lit: bool = true,
    use_fog: bool = OE_FAE, rot: i32 = 0,
    flipped: bool = false, division_level: i32 = 0) {

    pa := a + offs;
    pb := b + offs;
    pc := c + offs;
    pd := d + offs;

    n1a := surface_normal({pa, pb, pc});
    n1b := surface_normal({pa, pc, pd});
    score1 := linalg.dot(n1a, n1b);

    n2a := surface_normal({pa, pb, pd});
    n2b := surface_normal({pb, pc, pd});
    score2 := linalg.dot(n2a, n2b);

    if score1 >= score2 {
        msc_append_tri(self, pa, pb, pc, {}, color, texture_tag, is_lit, use_fog, rot, n1a, flipped, division_level);
        msc_append_tri(self, pa, pc, pd, {}, color, texture_tag, is_lit, use_fog, rot, n1b, flipped, division_level);
    } else {
        msc_append_tri(self, pa, pb, pd, {}, color, texture_tag, is_lit, use_fog, rot, n2a, flipped, division_level);
        msc_append_tri(self, pb, pc, pd, {}, color, texture_tag, is_lit, use_fog, rot, n2b, flipped, division_level);
    }

    _aabb = tris_to_aabb(tris);
}

msc_append_circle :: proc(
    using self: ^MSCObject,
    center: Vec3, edge: Vec3,
    segments: i32 = 10,
    color: Color = WHITE,
    texture_tag: string = "",
    is_lit: bool = true,
    use_fog: bool = OE_FAE,
    rot: i32 = 0,
    flipped: bool = false,
    division_level: i32 = 0
) {
    radius_vec := edge - center;
    radius := linalg.length(radius_vec);

    right := linalg.normalize(radius_vec);

    up_guess := Vec3{0, 1, 0};
    if (linalg.abs(linalg.dot(right, up_guess)) > 0.99) {
        up_guess = Vec3{0, 0, 1};
    }

    normal := linalg.normalize(linalg.cross(right, up_guess));
    up := linalg.normalize(linalg.cross(normal, right));

    if (flipped) {
        normal = -normal;
    }

    angle_step := 2.0 * math.PI / f32(segments);

    for i in 0..<segments {
        angle1 := angle_step * f32(i);
        angle2 := angle_step * f32((i + 1) % segments);

        p1 := center + (linalg.cos(angle1) * right + linalg.sin(angle1) * up) * radius;
        p2 := center + (linalg.cos(angle2) * right + linalg.sin(angle2) * up) * radius;

        msc_append_tri(self, center, p1, p2, {}, color, texture_tag, is_lit, use_fog, rot, normal, flipped, division_level);
    }

    _aabb = tris_to_aabb(tris);
}

msc_append_model :: proc(
    using self: ^MSCObject,
    model: Model,
    offs: Vec3 = {},
    color: Color = WHITE,
    texture_tag: string = "",
    is_lit: bool = true,
    use_fog: bool = OE_FAE,
    rot: i32 = 0,
    flipped: bool = false,
    division_level: i32 = 0
) {
    scale: f32 = 1;
    for i in 0..<model.meshCount {
        mesh := model.meshes[i];

        materialIndex := model.meshMaterial[i];
        material := model.materials[materialIndex];
        tag := str_add("mtl", materialIndex);
        texture := material.maps[rl.MaterialMapIndex.ALBEDO].texture;
        reg_asset(tag, load_texture(texture));

        vertices := mesh.vertices;
        for j := 0; j < int(mesh.vertexCount); j += 3 {
            v0 := scale * Vec3 { vertices[j * 3], vertices[j * 3 + 1], vertices[j * 3 + 2] };
            v1 := scale * Vec3 { vertices[(j + 1) * 3], vertices[(j + 1) * 3 + 1], vertices[(j + 1) * 3 + 2] };
            v2 := scale * Vec3 { vertices[(j + 2) * 3], vertices[(j + 2) * 3 + 1], vertices[(j + 2) * 3 + 2] };

            normal := Vec3 { 
                mesh.normals[j * 3], 
                mesh.normals[j * 3 + 1], 
                mesh.normals[j * 3 + 2]
            };

            msc_append_tri(
                self, v0, v1, v2, 
                offs, 
                texture_tag = tag, normal = normal,
                is_lit = is_lit, use_fog = use_fog,
                rot = rot, flipped = flipped, division_level = division_level
            );
        } 
    }
}

msc_append_terrain :: proc(
    using self: ^MSCObject,
    heightmap: Texture,
    scale: Vec3 = {1, 1, 1},
    offs: Vec3 = {},
    color: Color = WHITE,
    texture_tag: string = "",
    is_lit: bool = true,
    use_fog: bool = OE_FAE,
    rot: i32 = 0,
    flipped: bool = false,
    division_level: i32 = 0
) {
    img := rl.LoadImageFromTexture(heightmap);
    _mesh := rl.GenMeshHeightmap(img, scale);

    vertices := _mesh.vertices;
    for j := 0; j < int(_mesh.vertexCount); j += 3 {
        v0 := Vec3 { vertices[j * 3], vertices[j * 3 + 1], vertices[j * 3 + 2] };
        v1 := Vec3 { vertices[(j + 1) * 3], vertices[(j + 1) * 3 + 1], vertices[(j + 1) * 3 + 2] };
        v2 := Vec3 { vertices[(j + 2) * 3], vertices[(j + 2) * 3 + 1], vertices[(j + 2) * 3 + 2] };

        normal := Vec3 { 
            _mesh.normals[j * 3], 
            _mesh.normals[j * 3 + 1], 
            _mesh.normals[j * 3 + 2]
        };

        msc_append_tri(
            self, v0, v1, v2, 
            offs, 
            texture_tag = texture_tag, normal = normal,
            is_lit = is_lit, use_fog = use_fog,
            rot = rot, flipped = flipped, division_level = division_level
        );
    }

    rl.UnloadImage(img);
    rl.UnloadMesh(_mesh);
}

reload_mesh_tris :: proc(using self: ^MSCObject) {
    if (OE_DEBUG) {
        dbg_log("Reloading mesh", .INFO);
    }
    mesh_tri_count = 0;
    clear(&mesh_tris);

    for tri in tris {
        subdivide_triangle_coll(tri, tri.division_level, &mesh_tris);
        mesh_tri_count += i32(math.pow(4.0, f32(tri.division_level)));
    }
}

tri_recalc_uvs :: proc(t: ^TriangleCollider, #any_int uv_rot: i32 = 0) {
    t.rot = uv_rot;
}

msc_gen_mesh :: proc(using self: ^MSCObject, gen_tree := true) {
    mesh.triangleCount = i32(len(mesh_tris));
    mesh.vertexCount = mesh.triangleCount * 3;
    allocate_mesh(&mesh);

    for i in 0..<len(mesh_tris) {
        gen_tri(self, &mesh_tris[i], i);
    }

    rl.UploadMesh(&mesh, false);

    if (gen_tree) {
        msc_build(self);
    }
}

gen_tri :: proc(using self: ^MSCObject, t: ^TriangleCollider, #any_int index: i32) {
    verts := t.pts;

    at: AtlasTexture;
    for st in atlas.subtextures {
        if (st.tag == t.texture_tag) {
            at = st;
        }
    }

    uv1, uv2, uv3 := atlas_triangle_uvs(
        verts[0], verts[1], verts[2],
        at.uvs,
        0
    );

    v_offset := index * 9;
    uv_offset := index * 6;
    clr_offset := index * 12;

    normal := t.normal;

    mesh.vertices[v_offset + 0] = verts[0].x;
    mesh.vertices[v_offset + 1] = verts[0].y;
    mesh.vertices[v_offset + 2] = verts[0].z;
    mesh.normals[v_offset + 0] = normal.x;
    mesh.normals[v_offset + 1] = normal.y;
    mesh.normals[v_offset + 2] = normal.z;
    mesh.texcoords[uv_offset + 0] = uv1.x;
    mesh.texcoords[uv_offset + 1] = uv1.y;
    mesh.colors[clr_offset + 0] = t.color.r;
    mesh.colors[clr_offset + 1] = t.color.g;
    mesh.colors[clr_offset + 2] = t.color.b;
    mesh.colors[clr_offset + 3] = t.color.a;

    mesh.vertices[v_offset + 3] = verts[1].x;
    mesh.vertices[v_offset + 4] = verts[1].y;
    mesh.vertices[v_offset + 5] = verts[1].z;
    mesh.normals[v_offset + 3] = normal.x;
    mesh.normals[v_offset + 4] = normal.y;
    mesh.normals[v_offset + 5] = normal.z;
    mesh.texcoords[uv_offset + 2] = uv2.x;
    mesh.texcoords[uv_offset + 3] = uv2.y;
    mesh.colors[clr_offset + 4] = t.color.r;
    mesh.colors[clr_offset + 5] = t.color.g;
    mesh.colors[clr_offset + 6] = t.color.b;
    mesh.colors[clr_offset + 7] = t.color.a;

    mesh.vertices[v_offset + 6] = verts[2].x;
    mesh.vertices[v_offset + 7] = verts[2].y;
    mesh.vertices[v_offset + 8] = verts[2].z;
    mesh.normals[v_offset + 6] = normal.x;
    mesh.normals[v_offset + 7] = normal.y;
    mesh.normals[v_offset + 8] = normal.z;
    mesh.texcoords[uv_offset + 4] = uv3.x;
    mesh.texcoords[uv_offset + 5] = uv3.y;
    mesh.colors[clr_offset + 8] = t.color.r;
    mesh.colors[clr_offset + 9] = t.color.g;
    mesh.colors[clr_offset + 10] = t.color.b;
    mesh.colors[clr_offset + 11] = t.color.a;
}

// .obj recommended
// work in progress
msc_from_model :: proc(using self: ^MSCObject, model: Model, offs: Vec3 = {}, scale: f32 = 1) {
    for i in 0..<model.meshCount {
        mesh := model.meshes[i];

        materialIndex := model.meshMaterial[i];
        material := model.materials[materialIndex];
        tag := str_add("mtl", materialIndex);
        texture := material.maps[rl.MaterialMapIndex.ALBEDO].texture;
        reg_asset(tag, load_texture(texture));

        vertices := mesh.vertices;
        for j := 0; j < int(mesh.vertexCount); j += 3 {
            v0 := scale * Vec3 { vertices[j * 3], vertices[j * 3 + 1], vertices[j * 3 + 2] };
            v1 := scale * Vec3 { vertices[(j + 1) * 3], vertices[(j + 1) * 3 + 1], vertices[(j + 1) * 3 + 2] };
            v2 := scale * Vec3 { vertices[(j + 2) * 3], vertices[(j + 2) * 3 + 1], vertices[(j + 2) * 3 + 2] };

            normal := Vec3 { 
                mesh.normals[j * 3], 
                mesh.normals[j * 3 + 1], 
                mesh.normals[j * 3 + 2]
            };

            msc_append_tri(self, v0, v1, v2, offs, texture_tag = tag, normal = normal);
        } 
    }
}

ODVec3 :: struct { x, y, z: f32 }
ODColor :: struct { r, g, b, a: i32 }

vec3_to_od :: proc(v: Vec3) -> ODVec3 {
    return ODVec3 {v.x, v.y, v.z};
}

color_to_od :: proc(c: Color) -> ODColor {
    return ODColor {i32(c.r), i32(c.g), i32(c.b), i32(c.a)};
}

CompArrayMarshal :: struct {
    c0: ComponentMarshall,
    c1: ComponentMarshall,
    c2: ComponentMarshall,
    c3: ComponentMarshall,
    c4: ComponentMarshall,
    c5: ComponentMarshall,
    c6: ComponentMarshall,
    c7: ComponentMarshall,
    c8: ComponentMarshall,
    c9: ComponentMarshall,
    c10: ComponentMarshall,
    c11: ComponentMarshall,
    c12: ComponentMarshall,
    c13: ComponentMarshall,
    c14: ComponentMarshall,
    c15: ComponentMarshall,
}

FlagsArrayMarshal :: struct {
    c0: i32,
    c1: i32,
    c2: i32,
    c3: i32,
    c4: i32,
    c5: i32,
    c6: i32,
    c7: i32,
    c8: i32,
    c9: i32,
    c10: i32,
    c11: i32,
    c12: i32,
    c13: i32,
    c14: i32,
    c15: i32,
}

comps_to_od :: proc(s: [16]ComponentMarshall) -> CompArrayMarshal {
    return CompArrayMarshal {
        s[0], s[1], s[2], s[3],
        s[4], s[5], s[6], s[7],
        s[8], s[9], s[10], s[11],
        s[12], s[13], s[14], s[15],
    };
}

flags_to_od :: proc(s: [16]i32) -> FlagsArrayMarshal {
    return FlagsArrayMarshal {
        i32(s[0]), i32(s[1]), i32(s[2]), i32(s[3]),
        i32(s[4]), i32(s[5]), i32(s[6]), i32(s[7]),
        i32(s[8]), i32(s[9]), i32(s[10]), i32(s[11]),
        i32(s[12]), i32(s[13]), i32(s[14]), i32(s[15]),
    };
}

save_msc :: proc(
    using self: ^MSCObject,
    path: string,
    save_dids: bool = true,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);

    res: string;

    TriangleColliderMarshal :: struct {
        pts: struct {
            pt_0: ODVec3,
            pt_1: ODVec3,
            pt_2: ODVec3,
        },
        color: ODColor,
        texture_tag: string,
        is_lit: bool,
        use_fog: bool,
        rot: i32,
        flipped: bool,
        normal: ODVec3,
        division: i32,
    }

    i := 0;
    for t in tris {
        tm := TriangleColliderMarshal {
            pts = {vec3_to_od(t.pts[0]), vec3_to_od(t.pts[1]), vec3_to_od(t.pts[2])},
            color = color_to_od(t.color),
            texture_tag = t.texture_tag,
            is_lit = t.is_lit,
            use_fog = t.use_fog,
            rot = t.rot,
            flipped = t.flipped,
            normal = vec3_to_od(t.normal),
            division = t.division_level,
        };
        data := od.marshal(tm, TriangleColliderMarshal, str_add("triangle", i));

        res = str_add({res, data, "\n"});
        i += 1;
    }

    DataIDMarshal :: struct {
        tag: string,
        id: i32,
        transform: struct {
            position: ODVec3,
            rotation: ODVec3,
            scale: ODVec3,
        },
        components: CompArrayMarshal,
        flags: FlagsArrayMarshal,
    };

    if (save_dids) {
        j := 0;
        dids := get_reg_data_ids();
        for i in 0..<len(dids) {
            data_id := dids[i];
            mrshl := DataIDMarshal {
                tag = data_id.tag,
                id = i32(data_id.id),
                transform = {
                    position = vec3_to_od(data_id.transform.position),
                    rotation = vec3_to_od(data_id.transform.rotation),
                    scale = vec3_to_od(data_id.transform.scale),
                },
                components = comps_to_od(data_id.comps.data),
                flags = flags_to_od(data_id.flags.data),
            };

            data := od.marshal(mrshl, DataIDMarshal, str_add("data_id", j));
            res = str_add({res, data, "\n"});
            j += 1;
        }
        delete(dids);
    }

    file_write(file, res);
    file_close(file);
}

load_msc :: proc(using self: ^MSCObject, path: string, load_dids := true) {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return;
    }
    defer delete(data);

    _data := od.parse(string(data));
    msc := _data;

    for tag, obj in msc {
        if (strs.contains(tag, "triangle")) { msc_load_tri(self, obj.(od.Object)); }
        else { 
            if (load_dids) {
                msc_load_data_id(
                    strs.clone(obj.(od.Object)["tag"].(json.String)), 
                    obj.(od.Object)
                ); 
            }
        }
    }
}

msc_to_json :: proc(
    using self: ^MSCObject, 
    path: string,
    save_dids: bool = true,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);
    
    res: string = "{";

    TriangleColliderMarshal :: struct {
        using pts: [3]Vec3,
        color: Color,
        texture_tag: string,
        is_lit: bool,
        use_fog: bool,
        rot: i32,
        flipped: bool,
        normal: Vec3,
        division: i32,
    }

    i := 0;
    for t in tris {
        tm := TriangleColliderMarshal {
            pts = t.pts,
            color = t.color,
            texture_tag = t.texture_tag,
            is_lit = t.is_lit,
            use_fog = t.use_fog,
            rot = t.rot,
            flipped = t.flipped,
            normal = t.normal,
            division = t.division_level,
        };
        data, ok := json.marshal(tm, {pretty = true});

        if (ok != nil) {
            fmt.printfln("An error occured marshalling data: %v", ok);
            return;
        }

        name := str_add({str_add("\"triangle", i), "\": {\n"});
        res = str_add({res, "\n", name, string(data[1:len(data) - 1]), "},\n"});
        i += 1;
    }

    DataIDMarshall :: struct {
        tag: string,
        id: u32,
        transform: Transform,
        components: []ComponentMarshall,
        flags: []i32,
    };

    if (save_dids) {
        j := 0;
        dids := get_reg_data_ids();
        for i in 0..<len(dids) {
            data_id := dids[i];
            mrshl := DataIDMarshall {
                data_id.tag, 
                data_id.id, 
                data_id.transform,
                fa.slice(new_clone(data_id.comps)),
                fa.slice(new_clone(data_id.flags)),
            };
            data, ok := json.marshal(mrshl, {pretty = true});

            if (ok != nil) {
                fmt.printfln("An error occured marshalling data: %v", ok);
                return;
            }
            
            name := str_add({"\"", str_add("data_id", j), "\": {\n"});
            res = str_add({res, "\n", name, string(data[1:len(data) - 1]), "},\n"});
            j += 1;
        }
        delete(dids);
    }

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

load_data_ids :: proc(
    path: string, 
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE
) {
    file := file_handle(path, mode);
    
    res: string = "{";

    DataIDMarshall :: struct {
        tag: string,
        id: u32,
        transform: Transform,
        components: []ComponentMarshall, 
    };

    j := 0;
    dids := get_reg_data_ids();
    for i in 0..<len(dids) {
        data_id := dids[i];
        mrshl := DataIDMarshall {
            data_id.tag, 
            data_id.id, 
            data_id.transform,
            fa.slice(new_clone(data_id.comps)),
        };
        data, ok := json.marshal(mrshl, {pretty = true});

        if (ok != nil) {
            fmt.printfln("An error occured marshalling data: %v", ok);
            return;
        }
        
        name := str_add({"\"", str_add("data_id", j), "\": {\n"});
        res = str_add({res, "\n", name, string(data[1:len(data) - 1]), "},\n"});
        j += 1;
    }
    delete(dids);

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

msc_from_json :: proc(using self: ^MSCObject, path: string, load_dids := true) {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return;
    }
    defer delete(data);

    json_data, err := json.parse(data);
    if (err != json.Error.None) {
		dbg_log("Failed to parse the json file", DebugType.WARNING);
		dbg_log(str_add("Error: ", err), DebugType.WARNING);
		return;
	}
	defer json.destroy_value(json_data);

    msc := json_data.(json.Object);

    for tag, obj in msc {
        if (strs.contains(tag, "triangle")) { msc_load_tri(self, obj); }
        else { 
            if (load_dids) {
                msc_load_data_id(strs.clone(obj.(json.Object)["tag"].(json.String)), obj); 
            }
        }
    }
}

save_data_ids :: proc (
    path: string,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    if (filepath.ext(path) == ".od") {
        save_data_ids_od(path, mode);
        return;
    }

    save_data_ids_json(path, mode);
}

save_data_ids_od :: proc(
    path: string,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);

    res: string;

    DataIDMarshal :: struct {
        tag: string,
        id: i32,
        transform: struct {
            position: ODVec3,
            rotation: ODVec3,
            scale: ODVec3,
        },
        components: CompArrayMarshal,
        flags: FlagsArrayMarshal,
    };

    j := 0;
    dids := get_reg_data_ids();
    for i in 0..<len(dids) {
        data_id := dids[i];
        mrshl := DataIDMarshal {
            tag = data_id.tag,
            id = i32(data_id.id),
            transform = {
                position = vec3_to_od(data_id.transform.position),
                rotation = vec3_to_od(data_id.transform.rotation),
                scale = vec3_to_od(data_id.transform.scale),
            },
            components = comps_to_od(data_id.comps.data),
            flags = flags_to_od(data_id.flags.data),
        };

        data := od.marshal(mrshl, DataIDMarshal, str_add("data_id", j));
        res = str_add({res, data, "\n"});
        j += 1;
    }
    delete(dids);

    file_write(file, res);
    file_close(file);
}

save_data_ids_json :: proc(
    path: string,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);
    
    res: string = "{";

    DataIDMarshall :: struct {
        tag: string,
        id: u32,
        transform: Transform,
        flags: []i32,
        components: []ComponentMarshall, 
    };

    j := 0;
    dids := get_reg_data_ids();
    for i in 0..<len(dids) {
        data_id := dids[i];
        mrshl := DataIDMarshall {
            data_id.tag, 
            data_id.id, 
            data_id.transform,
            fa.slice(new_clone(data_id.flags)),
            fa.slice(new_clone(data_id.comps)),
        };
        data, ok := json.marshal(mrshl, {pretty = true});

        if (ok != nil) {
            fmt.printfln("An error occured marshalling data: %v", ok);
            return;
        }
        
        name := str_add({"\"", str_add("data_id", j), "\": {\n"});
        res = str_add({res, "\n", name, string(data[1:len(data) - 1]), "},\n"});
        j += 1;
    }
    delete(dids);

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

save_map :: proc(
    name, path: string, use_json := false, mode: FileMode = .WRITE_RONLY | .CREATE) {
    dir := str_add({path, "/", name})
    create_dir(dir);

    for i in 0..<ecs_world.physics.mscs.len {
        msc := ecs_world.physics.mscs.data[i];
        if (len(msc.tris) == 0) { continue; }
        name := str_add("msc", i);

        if (use_json) {
            res_path := str_add({dir, "/", name, ".json"});
            msc_to_json(ecs_world.physics.mscs.data[i], res_path, save_dids = false);
        } else {
            res_path := str_add({dir, "/", name, ".od"});
            save_msc(ecs_world.physics.mscs.data[i], res_path, save_dids = false);
        }
    }

    if (use_json) {
        save_data_ids(str_add(dir, "/data_ids.json"));
    } else {
        save_data_ids(str_add(dir, "/data_ids.od"));
    }
}

load_map :: proc(path: string, atlas: Atlas, use_json := false) {
    list := get_files(path);

    for dir in list {
        msc := msc_init();
        if (use_json) { msc_from_json(msc, dir); }
        else { load_msc(msc, dir); }
        msc.atlas = atlas;
        msc_gen_mesh(msc);
    }
}

update_msc :: proc(old, new: ^MSCObject) {
    for i in 0..<len(new.tris) {
        new_tri := new.tris[i];
        for j in 0..<len(old.tris) {
            old_tri := old.tris[j];
            if (new_tri.pts == old_tri.pts) {
                continue;
            }
        }

        msc_append_tri(
            old, 
            new_tri.pts[0],
            new_tri.pts[1],
            new_tri.pts[2],
            offs = {},
            color = new_tri.color,
            texture_tag = new_tri.texture_tag,
            is_lit = new_tri.is_lit,
            use_fog = new_tri.use_fog,
            rot = new_tri.rot,
            normal = new_tri.normal,
            flipped = new_tri.flipped,
            division_level = new_tri.division_level,
        );
    }

    old._aabb = tris_to_aabb(old.tris);
}

json_vec3_to_vec3 :: proc(v: json.Array) -> Vec3 {
    return Vec3 {
        f32(v[0].(json.Float)),
        f32(v[1].(json.Float)),
        f32(v[2].(json.Float))
    };
}

msc_load_data_id :: proc {
    msc_load_data_id_json,
    msc_load_data_id_od,
}

msc_load_data_id_od :: proc(tag: string, obj: od.Object) {
    id := obj["id"].(i32);

    if (!od_contains(obj, "transform")) do return;

    transfrom_obj := obj["transform"].(od.Object);
    transform := Transform {
        position = od_vec3(transfrom_obj["position"].(od.Object)),
        rotation = od_vec3(transfrom_obj["rotation"].(od.Object)),
        scale = od_vec3(transfrom_obj["scale"].(od.Object)),
    };

    reg_tag := str_add("data_id_", tag);
    if (asset_manager.registry[reg_tag] != nil) { 
        reg_tag = str_add(reg_tag, rl.GetRandomValue(1000, 9999)); 
    }
    
    flags := fa.fixed_array(i32, 16);
    if (obj["flags"] != nil) {
        flags_handle := obj["flags"].(od.Object);
        for i in 0..<16 {
            flag := od.target_type(flags_handle[str_add("c", i)], i32);
            fa.append(&flags, flag);
        }
    }

    comps_arr := fa.fixed_array(ComponentMarshall, 16);

    if (window.instance_name != EDITOR_INSTANCE) {
        ent := aent_init(tag);
        ent_tr := get_component(ent, Transform);
        ent_tr^ = transform;

        if (od_contains(obj, "components")) {
            comps_handle := obj["components"].(od.Object);

            for i in 0..<16 {
                comp := comps_handle[str_add("c", i)].(od.Object);
                tag := comp["tag"].(string);
                type := comp["type"].(string);

                loader := asset_manager.component_loaders[type];
                if (loader != nil) { loader(ent, tag); }

                fa.append(
                    &comps_arr, 
                    ComponentMarshall {
                        strs.clone(tag), 
                        strs.clone(type)
                    },
                );
            }
        }

        for i in 0..<16 {
            ent.flags[i] = flags.data[i];
        }
    } else {
        if (od_contains(obj, "components")) {
            comps_handle := obj["components"].(od.Object);

            for i in 0..<16 {
                comp := comps_handle[str_add("c", i)].(od.Object);
                tag := comp["tag"].(string);
                type := comp["type"].(string);

                fa.append(
                    &comps_arr, 
                    ComponentMarshall {
                        strs.clone(tag), 
                        strs.clone(type)
                    },
                );
            }
        }
    }

    reg_asset(
        reg_tag, 
        DataID {
            reg_tag, 
            tag, 
            u32(id), 
            transform,
            flags,
            comps_arr,
        }
    );
}

msc_load_data_id_json :: proc(tag: string, obj: json.Value) {
    id := obj.(json.Object)["id"].(json.Float);

    if (obj.(json.Object)["transform"] == nil) do return;

    transfrom_obj := obj.(json.Object)["transform"].(json.Object);
    transform := Transform {
        position = json_vec3_to_vec3(transfrom_obj["position"].(json.Array)),
        rotation = json_vec3_to_vec3(transfrom_obj["rotation"].(json.Array)),
        scale = json_vec3_to_vec3(transfrom_obj["scale"].(json.Array)),
    };

    reg_tag := str_add("data_id_", tag);
    if (asset_manager.registry[reg_tag] != nil) do reg_tag = str_add(reg_tag, rl.GetRandomValue(1000, 9999));

    flags := fa.fixed_array(i32, 16);
    if (obj.(json.Object)["flags"] != nil) {
        flags_handle := obj.(json.Object)["flags"].(json.Array);
        for i in flags_handle {
            fa.append(&flags, i32(i.(json.Float)));
        }
    }

    comps_arr := fa.fixed_array(ComponentMarshall, 16);

    if (window.instance_name != EDITOR_INSTANCE) {
        ent := aent_init(tag);
        ent_tr := get_component(ent, Transform);
        ent_tr^ = transform;

        for i in 0..<flags.len {
            ent.flags[i] = flags.data[i];
        }

        if (obj.(json.Object)["components"] != nil) {
            comps_handle := obj.(json.Object)["components"].(json.Array);
            for i in comps_handle {
                tag := i.(json.Object)["tag"].(json.String);
                type := i.(json.Object)["type"].(json.String);
          
                loader := asset_manager.component_loaders[type];
                if (loader != nil) { loader(ent, tag); }
                fa.append(
                    &comps_arr, 
                    ComponentMarshall {
                        strs.clone(tag), 
                        strs.clone(type)
                    },
                );
            }
        }
    } else {
        if (obj.(json.Object)["components"] != nil) {
            comps_handle := obj.(json.Object)["components"].(json.Array);
            for i in comps_handle {
                tag := i.(json.Object)["tag"].(json.String);
                type := i.(json.Object)["type"].(json.String);
          
                fa.append(
                    &comps_arr, 
                    ComponentMarshall {
                        strs.clone(tag), 
                        strs.clone(type)
                    },
                );
            }
        }
    }

    reg_asset(
        reg_tag, 
        DataID {
            reg_tag, 
            tag, 
            u32(id), 
            transform,
            flags,
            comps_arr,
        }
    );
}

msc_load_tri :: proc {
    msc_load_tri_json,
    msc_load_tri_od,
}

msc_load_tri_od :: proc(using self: ^MSCObject, obj: od.Object) {
    tri: [3]Vec3;
    if (od_contains(obj, "pts")) {
        pts_h := obj["pts"].(od.Object);

        tri[0] = {
            pts_h["pt_0"].(od.Object)["x"].(f32),
            pts_h["pt_0"].(od.Object)["y"].(f32),
            pts_h["pt_0"].(od.Object)["z"].(f32),
        };

        tri[1] = {
            pts_h["pt_1"].(od.Object)["x"].(f32),
            pts_h["pt_1"].(od.Object)["y"].(f32),
            pts_h["pt_1"].(od.Object)["z"].(f32),
        };

        tri[2] = {
            pts_h["pt_2"].(od.Object)["x"].(f32),
            pts_h["pt_2"].(od.Object)["y"].(f32),
            pts_h["pt_2"].(od.Object)["z"].(f32),
        };
    }

    color: Color;
    if (od_contains(obj, "color")) {
        color.r = u8(obj["color"].(od.Object)["r"].(i32));
        color.g = u8(obj["color"].(od.Object)["g"].(i32));
        color.b = u8(obj["color"].(od.Object)["b"].(i32));
        color.a = u8(obj["color"].(od.Object)["a"].(i32));
    }

    tex_tag := obj["texture_tag"].(string);

    if (!asset_exists(tex_tag)) {
        dbg_log(
            str_add({"Texture ", tex_tag, " doesn't exist in the asset manager"}), 
            DebugType.WARNING
        );
    }

    is_lit := true;
    if (od_contains(obj, "is_lit")) {
        is_lit = obj["is_lit"].(bool);
    }

    use_fog := OE_FAE;
    if (od_contains(obj, "use_fog")) {
        use_fog = obj["use_fog"].(bool);
    }

    rot: i32;
    if (od_contains(obj, "rot")) {
        rot = obj["rot"].(i32);
    }

    flipped: bool;
    if (od_contains(obj, "flipped"))  {
        flipped = obj["flipped"].(bool);
    }

    division_level: i32;
    if (od_contains(obj, "division")) {
        division_level = od.target_type(obj["division"], i32);
    }

    normal: Vec3;
    set_normal := false;
    if (od_contains(obj, "normal")) {
        normal = od_vec3(obj["normal"].(od.Object));
        set_normal = true;
    }

    if (set_normal) {
        msc_append_tri(
            self, tri[0], tri[1], tri[2], 
            color = color, texture_tag = strs.clone(tex_tag), 
            is_lit = is_lit, use_fog = use_fog, 
            rot = rot, normal = normal, 
            flipped = flipped, division_level = division_level,
        );
    } else {
        msc_append_tri(
            self, tri[0], tri[1], tri[2], 
            color = color, texture_tag = strs.clone(tex_tag), 
            is_lit = is_lit, use_fog = use_fog, 
            rot = rot, normal = surface_normal(tri), 
            flipped = flipped, division_level = division_level,
        );
    }
}

msc_load_tri_json :: proc(using self: ^MSCObject, obj: json.Value) {
    tri: [3]Vec3;
    if (obj.(json.Object)["pts"] != nil) {
        pts := obj.(json.Object)["pts"].(json.Array);

        i := 0;
        for pt in pts {
            val := pt.(json.Array);
            tri[i] = Vec3 {
                f32(val[0].(json.Float)), 
                f32(val[1].(json.Float)),
                f32(val[2].(json.Float))
            };
            i += 1;
        }
    }

    color: Color;
    if (obj.(json.Object)["color"] != nil) {
        colors := obj.(json.Object)["color"].(json.Array);
        color = {
            u8(colors[0].(json.Float)),
            u8(colors[1].(json.Float)),
            u8(colors[2].(json.Float)),
            u8(colors[3].(json.Float)),
        };
    }

    tex_tag := obj.(json.Object)["texture_tag"].(json.String);

    if (!asset_exists(tex_tag)) {
        dbg_log(
            str_add({"Texture ", tex_tag, " doesn't exist in the asset manager"}), 
            DebugType.WARNING
        );
    }

    is_lit := true;
    if (obj.(json.Object)["is_lit"] != nil) {
        is_lit = obj.(json.Object)["is_lit"].(json.Boolean);
    }

    use_fog := OE_FAE;
    if (obj.(json.Object)["use_fog"] != nil) {
        use_fog = obj.(json.Object)["use_fog"].(json.Boolean);
    }

    rot: i32;
    if (obj.(json.Object)["rot"] != nil) {
        rot = i32(obj.(json.Object)["rot"].(json.Float));
    }

    flipped: bool;
    if (obj.(json.Object)["flipped"] != nil) {
        flipped = obj.(json.Object)["flipped"].(json.Boolean);
    }

    division_level: i32;
    if (obj.(json.Object)["division"] != nil) {
        division_level = i32(obj.(json.Object)["division"].(json.Float));
    }

    normal: Vec3;
    set_normal := false;
    if (obj.(json.Object)["normal"] != nil) {
        normal = json_vec3_to_vec3(obj.(json.Object)["normal"].(json.Array));
        set_normal = true;
    }

    if (set_normal) {
        msc_append_tri(
            self, tri[0], tri[1], tri[2], 
            color = color, texture_tag = strs.clone(tex_tag), 
            is_lit = is_lit, use_fog = use_fog, 
            rot = rot, normal = normal, 
            flipped = flipped, division_level = division_level,
        );
    } else {
        msc_append_tri(
            self, tri[0], tri[1], tri[2], 
            color = color, texture_tag = strs.clone(tex_tag), 
            is_lit = is_lit, use_fog = use_fog, 
            rot = rot, normal = surface_normal(tri), 
            flipped = flipped, division_level = division_level,
        );
    }
}

MscRenderMode :: enum {
    COLLISION,
    MESH,
    BOTH,
}

msc_render :: proc(using self: ^MSCObject, mode: MscRenderMode = .MESH) {
    if (!render) { return; }

    m := DEFAULT_MATERIAL;
    m.maps[rl.MaterialMapIndex.ALBEDO].texture = atlas;
    m.shader = ecs_world.ray_ctx.shader;

    if (window.instance_name == EDITOR_INSTANCE) {
        msc_old_render(self, mode);
    } else {
        rl.DrawMesh(mesh, m, rl.Matrix(1));
    }

    if (PHYS_DEBUG) {
        for tri in tris {
            t := tri.pts;

            rl.DrawLine3D(t[0], t[1], rl.YELLOW);
            rl.DrawLine3D(t[0], t[2], rl.YELLOW);
            rl.DrawLine3D(t[1], t[2], rl.YELLOW);

            normal := tri.normal;
            rl.DrawLine3D(t[0], t[0] + normal, rl.RED);
            rl.DrawLine3D(t[1], t[1] + normal, rl.RED);
            rl.DrawLine3D(t[2], t[2] + normal, rl.RED);

            centroid := (t[0] + t[1] + t[2]) / 3;
            rl.DrawLine3D(centroid, centroid + normal, RED);
        }

        draw_cube_wireframe(
            {_aabb.x, _aabb.y, _aabb.z}, {}, 
            {_aabb.width, _aabb.height, _aabb.depth},
            PHYS_DEBUG_COLOR
        ); 
    }
}

msc_old_render :: proc(using self: ^MSCObject, mode: MscRenderMode = .MESH) {
    render_tri :: proc(atlas: Atlas, tris: [dynamic]TriangleCollider) {
        for tri in tris {
            t := tri.pts;

            v1 := t[0];
            v2 := t[1];
            v3 := t[2];
            color := tri.color;

            // uv1, uv2, uv3 := triangle_uvs(v1, v2, v3, tri.rot);

            at: AtlasTexture;
            for st in atlas.subtextures {
                if (st.tag == tri.texture_tag) {
                    at = st;
                }
            }

            verts := tri.pts;
            uv1, uv2, uv3 := atlas_triangle_uvs(
                verts[0], verts[1], verts[2],
                at.uvs,
                0
            );
            
            // fmt.println(uv1, uv2, uv3, tri.texture_tag, at);

            rl.rlColor4ub(color.r, color.g, color.b, color.a);
            rl.rlBegin(rl.RL_TRIANGLES);

            // if (asset_exists(tri.texture_tag)) {
            //     tex := get_asset_var(tri.texture_tag, Texture);
            //     rl.rlSetTexture(tex.id);
            // }
            rl.rlSetTexture(atlas.texture.id);

            rl.rlTexCoord2f(uv1.x, uv1.y); rl.rlVertex3f(v1.x, v1.y, v1.z);
            rl.rlTexCoord2f(uv2.x, uv2.y); rl.rlVertex3f(v2.x, v2.y, v2.z);
            rl.rlTexCoord2f(uv3.x, uv3.y); rl.rlVertex3f(v3.x, v3.y, v3.z);

            rl.rlEnd();

            rl.rlSetTexture(0);
        }
    }

    switch mode {
        case .COLLISION:
            render_tri(atlas, tris);
        case .MESH:
            render_tri(atlas, mesh_tris);
        case .BOTH:
            render_tri(atlas, tris);
            render_tri(atlas, mesh_tris);
    }
}

msc_deinit :: proc(using self: ^MSCObject) {
    delete(tris);
}
