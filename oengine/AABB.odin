package oengine

import "core:math"
import "core:math/linalg"
import "core:fmt"
import rl "vendor:raylib"

AABB :: struct {
    x, y, z: f32,
    width, height, depth: f32,
}

trans_to_aabb :: proc(t: Transform) -> AABB {
    return AABB {
        x = t.position.x,
        y = t.position.y,
        z = t.position.z,
        width = t.scale.x,
        height = t.scale.y,
        depth = t.scale.z,
    }
}

split_aabb_8 :: proc(aabb: AABB) -> [8]AABB {
    pos := Vec3 {aabb.x, aabb.y, aabb.z};

    half_size := Vec3 {
        aabb.width * 0.5,
        aabb.height * 0.5,
        aabb.depth * 0.5
    };

    q_size := half_size * 0.5; // quarter size

    return {
        AABB {pos.x - q_size.x, pos.y - q_size.y, pos.z - q_size.z, half_size.x, half_size.y, half_size.z}, // bottom back left
        AABB {pos.x + q_size.x, pos.y - q_size.y, pos.z - q_size.z, half_size.x, half_size.y, half_size.z}, // bottom back right
        AABB {pos.x - q_size.x, pos.y - q_size.y, pos.z + q_size.z, half_size.x, half_size.y, half_size.z}, // bottom front left
        AABB {pos.x + q_size.x, pos.y - q_size.y, pos.z + q_size.z, half_size.x, half_size.y, half_size.z}, // bottom front right
        AABB {pos.x - q_size.x, pos.y + q_size.y, pos.z - q_size.z, half_size.x, half_size.y, half_size.z}, // top back left
        AABB {pos.x + q_size.x, pos.y + q_size.y, pos.z - q_size.z, half_size.x, half_size.y, half_size.z}, // top back right
        AABB {pos.x - q_size.x, pos.y + q_size.y, pos.z + q_size.z, half_size.x, half_size.y, half_size.z}, // top front left
        AABB {pos.x + q_size.x, pos.y + q_size.y, pos.z + q_size.z, half_size.x, half_size.y, half_size.z}, // top front right
    };
}

compute_aabb :: proc(v0, v1, v2: Vec3) -> AABB {
    min_x := linalg.min(v0.x, v1.x, v2.x);
    min_y := linalg.min(v0.y, v1.y, v2.y);
    min_z := linalg.min(v0.z, v1.z, v2.z);

    max_x := linalg.max(v0.x, v1.x, v2.x);
    max_y := linalg.max(v0.y, v1.y, v2.y);
    max_z := linalg.max(v0.z, v1.z, v2.z);

    center := Vec3{(min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5};
    return AABB{
        x = center.x,
        y = center.y,
        z = center.z,
        width  = max_x - min_x,
        height = max_y - min_y,
        depth  = max_z - min_z,
    };
}

aabb_collision :: proc(cube1, cube2: AABB) -> bool {
    cube1MinX: f32 = cube1.x - cube1.width / 2;
    cube1MaxX: f32 = cube1.x + cube1.width / 2;
    cube1MinY: f32 = cube1.y - cube1.height / 2;
    cube1MaxY: f32 = cube1.y + cube1.height / 2;
    cube1MinZ: f32 = cube1.z - cube1.depth / 2;
    cube1MaxZ: f32 = cube1.z + cube1.depth / 2;

    cube2MinX: f32 = cube2.x - cube2.width / 2;
    cube2MaxX: f32 = cube2.x + cube2.width / 2;
    cube2MinY: f32 = cube2.y - cube2.height / 2;
    cube2MaxY: f32 = cube2.y + cube2.height / 2;
    cube2MinZ: f32 = cube2.z - cube2.depth / 2;
    cube2MaxZ: f32 = cube2.z + cube2.depth / 2;

    if (cube1MinX <= cube2MaxX && cube1MaxX >= cube2MinX &&
        cube1MinY <= cube2MaxY && cube1MaxY >= cube2MinY &&
        cube1MinZ <= cube2MaxZ && cube1MaxZ >= cube2MinZ) {
        return true; 
    }

    return false;
}

aabb_to_bounding_box :: proc(aabb: AABB) -> rl.BoundingBox {
    half_w := aabb.width / 2.0
    half_h := aabb.height / 2.0
    half_d := aabb.depth / 2.0

    min := Vec3 {
        aabb.x - half_w,
        aabb.y - half_h,
        aabb.z - half_d,
    };

    max := Vec3 {
        aabb.x + half_w,
        aabb.y + half_h,
        aabb.z + half_d,
    };

    return rl.BoundingBox{min = min, max = max}
}

point_in_aabb :: proc(point: Vec3, box: AABB) -> bool {
    boxMinX: f32 = box.x - box.width / 2;
    boxMaxX: f32 = box.x + box.width / 2;
    boxMinY: f32 = box.y - box.height / 2;
    boxMaxY: f32 = box.y + box.height / 2;
    boxMinZ: f32 = box.z - box.depth / 2;
    boxMaxZ: f32 = box.z + box.depth / 2;

    return (point.x >= boxMinX && point.x <= boxMaxX &&
            point.y >= boxMinY && point.y <= boxMaxY &&
            point.z >= boxMinZ && point.z <= boxMaxZ);
}

tris_to_aabb :: proc(tris: [dynamic]TriangleCollider) -> AABB {
    min := vec3_one() * math.F32_MAX;
    max := vec3_one() * -math.F32_MAX;

    for t in tris {
        for pt in t.pts {
            if (pt.x < min.x) do min.x = pt.x;
            if (pt.y < min.y) do min.y = pt.y;
            if (pt.z < min.z) do min.z = pt.z;

            if (pt.x > max.x) do max.x = pt.x;
            if (pt.y > max.y) do max.y = pt.y;
            if (pt.z > max.z) do max.z = pt.z;
        }
    }

    w := max.x - min.x;
    h := max.y - min.y;
    d := max.z - min.z;

    return AABB {
        x = min.x + w * 0.5, y = min.y + h * 0.5, z = min.z + d * 0.5,
        width = w,
        height = h,
        depth = d
    };
} 
