package oengine

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import ecs "ecs"
import "core:math/linalg"
import "core:math"

Prop :: struct {
    collider: Transform,
    _model: Model,
}

prop_init :: proc(
    ent: AEntity, model: Model, _position: Vec3, scale: Vec3 = {1, 1, 1}, 
    preset_size: Vec3 = {}, use_preset := false, _msc := false, 
    voxel_size: f32 = 0.1, render_msc := false, 
    model_pos_off := Vec3{}, model_scale_off := Vec3{}) -> (p: Prop) {
    if (use_preset) {
        p = Prop {
            collider = Transform {
                position = _position,
                rotation = {},
                scale = preset_size,
            },
            _model = model,
        };

        if (_msc) {
            msc := msc_init();
            msc.render = render_msc;
            simplify_msc_model(
                msc, model, 
                offs = _position + model_pos_off, scale = model_scale_off, 
                voxel_size = voxel_size);
            msc_gen_mesh(msc, true);
        } else {
            add_component(ent, rb_init(p.collider, 1, 0.5, true, ShapeType.BOX));
        }

        return;
    }

    rlbb := rl.GetModelBoundingBox(model);
    size := rlbb.max - rlbb.min;
    position := rlbb.min + size * 0.5;
    
    p = Prop {
        collider = Transform {
            position = _position,
            rotation = {},
            scale = size * scale,
        },
        _model = model,
    };

    if (_msc) {
        msc := msc_init();
        msc.render = render_msc;
        simplify_msc_model(
            msc, model, offs = _position, scale = scale, voxel_size = voxel_size);
        msc_gen_mesh(msc, true);
    } else {
        add_component(ent, rb_init(p.collider, 1, 0.5, true, ShapeType.BOX));
    }

    return;
}

prop_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    tr, p := ecs.get_components(ent, Transform, Prop);
    if (is_nil(tr, p)) { return; }
    if (!OE_DEBUG) { return; }

    t := p.collider;
    draw_cube_wireframe(t.position, t.rotation, t.scale, GREEN);
    rl.DrawModelWires(p._model, tr.position, 1, GREEN);
}

simplify_msc_model :: proc(
    using self: ^MSCObject, model: Model, 
    offs: Vec3 = {}, scale: Vec3 = {1, 1, 1}, voxel_size: f32 = 0.1
) {
    voxel_size := voxel_size;
    if voxel_size <= 0 {
        voxel_size = 0.1
    }

    for mi in 0..<model.meshCount {
        mesh := model.meshes[mi]

        V := int(mesh.vertexCount)
        tri_count := int(mesh.triangleCount)

        indices: [^]u32
        if mesh.indices != nil {
            indices = transmute([^]u32) mesh.indices
        }

        // Clustered data
        clustered_positions := make([dynamic]Vec3)
        clustered_normals   := make([dynamic]Vec3)
        clustered_counts    := make([dynamic]int)
        vertex_map          := make([]int, V)

        // Hashmap for voxel -> cluster index
        cluster_map := make(map[u64]int)

        // Assign vertices into voxel clusters
        for vi in 0..<V {
            p := scale * Vec3{
                mesh.vertices[vi*3+0],
                mesh.vertices[vi*3+1],
                mesh.vertices[vi*3+2],
            }

            xi := int(math.floor(p.x / voxel_size))
            yi := int(math.floor(p.y / voxel_size))
            zi := int(math.floor(p.z / voxel_size))
            key := hash_voxel(xi, yi, zi)

            idx, ok := cluster_map[key]
            if !ok {
                idx = len(clustered_positions)
                cluster_map[key] = idx

                append(&clustered_positions, p)
                if mesh.normals != nil {
                    append(&clustered_normals, Vec3{
                        mesh.normals[vi*3+0],
                        mesh.normals[vi*3+1],
                        mesh.normals[vi*3+2],
                    })
                } else {
                    append(&clustered_normals, Vec3{})
                }
                append(&clustered_counts, 1)
            } else {
                clustered_positions[idx] += p
                if mesh.normals != nil {
                    clustered_normals[idx] += Vec3{
                        mesh.normals[vi*3+0],
                        mesh.normals[vi*3+1],
                        mesh.normals[vi*3+2],
                    }
                }
                clustered_counts[idx] += 1
            }

            vertex_map[vi] = idx
        }

        // Average out cluster positions & normals
        for k in 0..<len(clustered_positions) {
            inv := 1.0 / f32(clustered_counts[k])
            clustered_positions[k] *= inv
            clustered_normals[k] = linalg.normalize0(clustered_normals[k] * inv)
        }

        // Rebuild triangles from clustered vertices
        for t in 0..<tri_count {
            a, b, c: int
            if indices != nil {
                a = vertex_map[int(indices[t*3+0])]
                b = vertex_map[int(indices[t*3+1])]
                c = vertex_map[int(indices[t*3+2])]
            } else {
                a = vertex_map[t*3+0]
                b = vertex_map[t*3+1]
                c = vertex_map[t*3+2]
            }

            if a == b || b == c || a == c {
                continue // degenerate
            }

            v0 := clustered_positions[a]
            v1 := clustered_positions[b]
            v2 := clustered_positions[c]

            normal := clustered_normals[a]
            if normal == (Vec3{0,0,0}) {
                e1 := v1 - v0
                e2 := v2 - v0
                normal = linalg.normalize0(linalg.cross(e1, e2))
            }

            materialIndex := model.meshMaterial[mi]
            material := model.materials[materialIndex]
            tag := str_add("mtl", materialIndex)
            texture := material.maps[rl.MaterialMapIndex.ALBEDO].texture
            reg_asset(tag, load_texture(texture))

            msc_append_tri(
                self, v0, v1, v2, offs, texture_tag = tag, normal = normal)
        }
    }
}

hash_voxel :: proc(x, y, z: int) -> u64 {
    return u64(x)*73856093 ~ u64(y)*19349663 ~ u64(z)*83492791;
}
