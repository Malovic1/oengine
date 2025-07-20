package oengine

import "core:fmt"
import rl "vendor:raylib"
import "core:os"
import od "object_data"
import "core:math/linalg"

MeshTransform :: struct {
    mesh: Model,
    transform: Transform,
    pivot: Vec3,
}

ShapeModel :: struct {
    transform: Transform,
    meshes: map[string]MeshTransform,
}

shape_model_load :: proc(tag, path: string) -> ShapeModel {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return {};
    }
    defer delete(data);

    od_data := od.parse(string(data));

    if (!od_contains(od_data, tag)) {
        dbg_log(str_add({"Shape model of tag ", tag, "was not found"}), .WARNING);
        return {};
    }

    model_data := od_data[tag].(od.Object);

    res: ShapeModel;
    res.meshes = make(map[string]MeshTransform);
    res.transform = transform_default();

    for k, v in model_data {
        if (!od_contains(model_data[k].(od.Object), "type")) {
            continue;
        }

        v_data := model_data[k].(od.Object);
        type := v_data["type"].(string);
        if (type == "Mesh") {
            position := od_vec3(v_data["position"].(od.Object));
            rotation := od_vec3(v_data["rotation"].(od.Object));
            scale := od_vec3(v_data["scale"].(od.Object));
            color := od_color(v_data["color"].(od.Object));
            pivot := od_vec3(v_data["pivot"].(od.Object));

            shape := od.target_type(v_data["shape"], i32);
            mesh := mesh_loaders[shape]();

            mesh.materials[0].maps[rl.MaterialMapIndex.ALBEDO].color = color;
            mesh.materials[0].shader = world().ray_ctx.shader;
            res.meshes[k] = MeshTransform{mesh, Transform{position, rotation, scale}, pivot};
        }
    }

    return res;
}

shape_model_render :: proc(m: ShapeModel) {
    global := m.transform;
    // global_mat := transform_to_matrix(global);

    for k, v in m.meshes {
        mesh := m.meshes[k];
        local := mesh.transform;
        local_mat := transform_to_matrix(local);

        // combined_matrix := global_mat * local_mat;
        // combined := matrix_to_transform(combined_matrix);

        combined := Transform{
            position = global.position + local.position,
            rotation = global.rotation + local.rotation,
            scale    = global.scale * local.scale,
        };
        pivot := global.position + mesh.pivot;
        draw_model(mesh.mesh, combined, WHITE, use_pivot = true, pivot = pivot);

        if (OE_DEBUG) {
            draw_cube_wireframe(global.position, global.rotation, global.scale, GREEN);
            rl.DrawSphere(global.position, 0.1, GREEN);

            draw_cube_wireframe(combined.position, combined.rotation, combined.scale, ORANGE);
            rl.DrawSphere(combined.position, 0.1, ORANGE);

            rl.DrawSphere(pivot, 0.1, RED);
        }
    }
}
