package oengine

import "core:math"
import "core:fmt"

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

get_aabb :: proc(id: int) -> BO_AABB {
    rb := ecs_world.physics.bodies.data[id];

    if (rb == nil) {
        return BO_AABB {
            min = {F32_MAX, F32_MAX, F32_MAX},
            max = {F32_MIN, F32_MIN, F32_MIN},
        };
    }

    padding: f32 = 0.1;
    return make_aabb(rb.transform.position, rb.transform.scale * 0.5 + padding);
}

aabb_overlap :: proc(a, b: BO_AABB) -> bool {
    return !(a.max.x < b.min.x || a.min.x > b.max.x ||
             a.max.y < b.min.y || a.min.y > b.max.y ||
             a.max.z < b.min.z || a.min.z > b.max.z);
}
