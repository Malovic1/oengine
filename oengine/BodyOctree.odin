package oengine

import "core:math"
import "core:fmt"
import "core:math/linalg"

BO_AABB :: struct {
    min, max: Vec3,
}

aabb_to_bo :: proc(a: AABB) -> BO_AABB {
    return BO_AABB {
        min = {a.x - a.width, a.y - a.height, a.z - a.depth},
        max = {a.x + a.width, a.y + a.height, a.z + a.depth},
    };
}

BodyOctreeNode :: struct {
    bounds: BO_AABB,
    children: [8]^BodyOctreeNode,
    objects: [dynamic]i32,
    is_leaf: bool,
    depth: i32,
}

BODY_MAX_DEPTH :: 5
BODY_MAX_COUNT :: 8

BodyOctree :: struct {
    root: ^BodyOctreeNode,
}

make_aabb :: proc(center, half_size: Vec3) -> BO_AABB {
    return BO_AABB {
        min = center - half_size,
        max = center + half_size,
    };
}

make_node :: proc(bounds: BO_AABB, depth: i32) -> ^BodyOctreeNode {
    res := new(BodyOctreeNode);
    res.bounds = bounds;
    res.is_leaf = true;
    res.depth = depth;

    return res;
}

make_tree :: proc(center: Vec3, half_size: Vec3) -> BodyOctree {
    return BodyOctree {
        root = make_node(make_aabb(center, half_size), 0),
    };
}

insert_octree :: proc(node: ^BodyOctreeNode, body_id: int, body_aabb: BO_AABB) {
    if (node.is_leaf && 
        (len(node.objects) < BODY_MAX_COUNT || 
        node.depth >= BODY_MAX_DEPTH)) {
        append(&node.objects, i32(body_id));
        return;
    }

    if (node.is_leaf) {
        bo_subdivide(node);
    }

    for i in 0..<8 {
        child := node.children[i];
        if (child != nil && aabb_overlap(child.bounds, body_aabb)) {
            insert_octree(child, body_id, body_aabb);
        }
    }
}

bo_subdivide :: proc(node: ^BodyOctreeNode) {
    center := (node.bounds.min + node.bounds.max) / 2;
    size := (node.bounds.max - node.bounds.min) / 2;
    offsets := [8]Vec3{
        {-1, -1, -1}, {1, -1, -1}, {-1, 1, -1}, {1, 1, -1},
        {-1, -1, 1},  {1, -1, 1},  {-1, 1, 1},  {1, 1, 1},
    };

    for i in 0..<8 {
        offset := offsets[i];
        child_center := center + offset * (size * 0.5);
        child_bounds := make_aabb(child_center, size * 0.5);
        node.children[i] = make_node(child_bounds, node.depth + 1);
    }

    for id in node.objects {
        for i in 0..<8 {
            if (node.children[i] != nil && 
                aabb_overlap(node.children[i].bounds, get_aabb(int(id)))) {
                insert_octree(node.children[i], int(id), get_aabb(int(id)));
            }
        }
    }

    clear(&node.objects);
    node.is_leaf = false;
}

bo_query_octree :: proc(node: ^BodyOctreeNode, query_aabb: BO_AABB, out: ^[dynamic]int) {
    if (!aabb_overlap(node.bounds, query_aabb)) { return; }

    if node.is_leaf {
        for id in node.objects {
            append(out, int(id));
        }
        return;
    }

    for child in node.children {
        if child != nil {
            bo_query_octree(child, query_aabb, out);
        }
    }
}

bo_clear_tree :: proc(node: ^BodyOctreeNode) {
    clear(&node.objects);
    if (node.is_leaf) { return; }

    for i in 0..<8 {
        if (node.children[i] != nil) {
            bo_clear_tree(node.children[i]);
        }
    }
}

bo_remove :: proc(node: ^BodyOctreeNode, body_id: i32) {
    // Remove from this node
    for i in 0..<len(node.objects) {
        if (node.objects[i] == body_id) {
            ordered_remove(&node.objects, i);
            break;
        }
    }

    // Recurse into children
    if (!node.is_leaf) {
        for child in node.children {
            if (child != nil) {
                bo_remove(child, body_id);
            }
        }
    }
}

get_aabb :: proc(id: int, padding: f32 = 0.1) -> BO_AABB {
    rb := ecs_world.physics.bodies.data[id];

    if (rb == nil) {
        return BO_AABB {
            min = {F32_MAX, F32_MAX, F32_MAX},
            max = {F32_MIN, F32_MIN, F32_MIN},
        };
    }

    return make_aabb(rb.transform.position, rb.transform.scale * 0.5 + padding);
}

aabb_overlap :: proc(a, b: BO_AABB) -> bool {
    return !(a.max.x < b.min.x || a.min.x > b.max.x ||
             a.max.y < b.min.y || a.min.y > b.max.y ||
             a.max.z < b.min.z || a.min.z > b.max.z);
}

aabb_contact_point :: proc(a, b: BO_AABB) -> Vec3 {
    overlap_min := linalg.max(a.min, b.min);
    overlap_max := linalg.min(a.max, b.max);
    return (overlap_min + overlap_max) * 0.5;
}

QueryInfo :: struct {
    id: i32,
    point: Vec3,
}

bo_aabb_collide :: proc(tree: ^BodyOctree, tr: Transform) -> (bool, QueryInfo) {
    hit_pos: Vec3 = {};
    id: i32;
    found: bool = false;

    aabb := AABB {
        tr.position.x, tr.position.y, tr.position.z,
        tr.scale.x, tr.scale.y, tr.scale.z
    };
    query := aabb_to_bo(aabb);

    bo_aabb_query_node(tree.root, query, &hit_pos, &id, &found);

    return found, {id, hit_pos};
}

bo_raycast :: proc(tree: ^BodyOctree, ray: Raycast, ignore_id: i32 = -1) -> (bool, Vec3) {
    closest_t: f32 = F32_MAX;
    hit_id: int = -1;

    bo_raycast_node(tree.root, ray, &closest_t, &hit_id, auto_cast ignore_id);

    if (hit_id == -1) {
        return false, {};
    }

    dir := vec3_normalize(ray.target - ray.position);
    hit_pos := ray.position + dir * closest_t;

    return true, hit_pos;
}

bo_raycast_info :: proc(tree: ^BodyOctree, ray: Raycast) -> (bool, QueryInfo) {
    closest_t: f32 = F32_MAX;
    hit_id: int = -1;

    bo_raycast_node(tree.root, ray, &closest_t, &hit_id, -1);

    if (hit_id == -1) {
        return false, {};
    }

    dir := vec3_normalize(ray.target - ray.position);
    hit_pos := ray.position + dir * closest_t;

    return true, {i32(hit_id), hit_pos};
}

bo_raycast_node :: proc(
    node: ^BodyOctreeNode,
    ray: Raycast,
    closest_t: ^f32,
    hit_id: ^int,
    ignore_id: int
) {
    hit, t := ray_vs_aabb(ray, node.bounds);
    if (!hit || t > closest_t^) {
        return;
    }

    if (node.is_leaf) {
        for id in node.objects {
            if (ignore_id != -1 && int(id) == ignore_id) {
                continue;
            }

            body_aabb := get_aabb(int(id), 0);

            bhit, bt := ray_vs_aabb(ray, body_aabb);
            if (bhit && bt < closest_t^) {
                closest_t^ = bt;
                hit_id^ = int(id);
            }
        }
        return;
    }

    for child in node.children {
        if (child != nil) {
            bo_raycast_node(child, ray, closest_t, hit_id, ignore_id);
        }
    }
}

ray_vs_aabb :: proc(ray: Raycast, aabb: BO_AABB) -> (bool, f32) {
    dir := linalg.normalize(ray.target - ray.position);

    inv_dir: Vec3;

    if dir.x != 0 {
        inv_dir.x = 1.0 / dir.x;
    } else {
        inv_dir.x = F32_MAX;
    }

    if dir.y != 0 {
        inv_dir.y = 1.0 / dir.y;
    } else {
        inv_dir.y = F32_MAX;
    }

    if dir.z != 0 {
        inv_dir.z = 1.0 / dir.z;
    } else {
        inv_dir.z = F32_MAX;
    }

    tmin := (aabb.min.x - ray.position.x) * inv_dir.x;
    tmax := (aabb.max.x - ray.position.x) * inv_dir.x;
    if (tmin > tmax) { tmin, tmax = tmax, tmin; }

    tymin := (aabb.min.y - ray.position.y) * inv_dir.y;
    tymax := (aabb.max.y - ray.position.y) * inv_dir.y;
    if (tymin > tymax) { tymin, tymax = tymax, tymin; }

    if (tmin > tymax || tymin > tmax) {
        return false, 0;
    }

    if (tymin > tmin) { tmin = tymin; }
    if (tymax < tmax) { tmax = tymax; }

    tzmin := (aabb.min.z - ray.position.z) * inv_dir.z;
    tzmax := (aabb.max.z - ray.position.z) * inv_dir.z;
    if (tzmin > tzmax) { tzmin, tzmax = tzmax, tzmin; }

    if (tmin > tzmax || tzmin > tmax) {
        return false, 0;
    }

    if (tzmin > tmin) { tmin = tzmin; }
    if (tzmax < tmax) { tmax = tzmax; }

    tHit := tmin;
    if (tmin < 0) {
        tHit = tmax;
    }

    if (tHit < 0) {
        return false, 0;
    }

    return true, tHit;
}

bo_aabb_query_node :: proc(
    node: ^BodyOctreeNode,
    query: BO_AABB,
    hit_pos: ^Vec3,
    b_id: ^i32,
    found: ^bool
) {
    if (found^) { return; }

    if (!aabb_overlap(node.bounds, query)) {
        return;
    }

    if (node.is_leaf) {
        for id in node.objects {
            body_aabb := get_aabb(int(id));

            if (aabb_overlap(query, body_aabb)) {
                hit_pos^ = aabb_contact_point(query, body_aabb);
                b_id^ = id;
                found^ = true;
                return;
            }
        }
        return;
    }

    for child in node.children {
        if (child != nil) {
            bo_aabb_query_node(child, query, hit_pos, b_id, found);
            if (found^) { return; }
        }
    }
}
