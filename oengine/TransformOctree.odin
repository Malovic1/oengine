package oengine

import "core:math"
import "core:fmt"

TransformOctreeNode :: struct {
    bounds: BO_AABB,
    children: [8]^TransformOctreeNode,
    objects: [dynamic]u32,
    is_leaf: bool,
    depth: i32,
}

TR_BODY_MAX_DEPTH :: 5
TR_BODY_MAX_COUNT :: 8

TransformOctree :: struct {
    root: ^TransformOctreeNode,
}

tr_make_node :: proc(bounds: BO_AABB, depth: i32) -> ^TransformOctreeNode {
    res := new(TransformOctreeNode);
    res.bounds = bounds;
    res.is_leaf = true;
    res.depth = depth;

    return res;
}

tr_make_tree :: proc(center: Vec3, half_size: Vec3) -> TransformOctree {
    return TransformOctree {
        root = tr_make_node(make_aabb(center, half_size), 0),
    };
}

tr_insert_octree :: proc(node: ^TransformOctreeNode, body_id: u32, body_aabb: BO_AABB) {
    if (node.is_leaf && 
        (len(node.objects) < TR_BODY_MAX_COUNT || 
        node.depth >= TR_BODY_MAX_DEPTH)) {
        append(&node.objects, body_id);
        return;
    }

    if (node.is_leaf) {
        tr_subdivide(node);
    }

    for i in 0..<8 {
        child := node.children[i];
        if (child != nil && aabb_overlap(child.bounds, body_aabb)) {
            tr_insert_octree(child, body_id, body_aabb);
        }
    }
}

tr_subdivide :: proc(node: ^TransformOctreeNode) {
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
        node.children[i] = tr_make_node(child_bounds, node.depth + 1);
    }

    for id in node.objects {
        for i in 0..<8 {
            if (node.children[i] != nil && 
                aabb_overlap(node.children[i].bounds, tr_get_aabb(id))) {
                tr_insert_octree(node.children[i], id, tr_get_aabb(id));
            }
        }
    }

    clear(&node.objects);
    node.is_leaf = false;
}

tr_query_octree :: proc(node: ^TransformOctreeNode, query_aabb: BO_AABB, out: ^[dynamic]u32) {
    if (!aabb_overlap(node.bounds, query_aabb)) { return; }

    if node.is_leaf {
        for id in node.objects {
            append(out, id);
        }
        return;
    }

    for child in node.children {
        if child != nil {
            tr_query_octree(child, query_aabb, out);
        }
    }
}

tr_clear_tree :: proc(node: ^TransformOctreeNode) {
    clear(&node.objects);
    if (node.is_leaf) { return; }

    for i in 0..<8 {
        if (node.children[i] != nil) {
            tr_clear_tree(node.children[i]);
        }
    }
}

tr_target_transform :: proc(id: u32) -> Transform {
    ent := ew_get_ent(id);
    tr := get_component(ent, Transform)^;
    if (ent.use_rb_transform) {
        if (has_component(ent, RigidBody)) {
            rb := get_component(ent, RigidBody);
            tr = rb.transform;
        }
    }

    return tr;
}

tr_get_aabb :: proc(id: u32) -> BO_AABB {
    ent := ew_get_ent(id);
    tr := tr_target_transform(id);

    if (ent == nil) {
        return BO_AABB {
            min = {F32_MAX, F32_MAX, F32_MAX},
            max = {F32_MIN, F32_MIN, F32_MIN},
        };
    }

    return make_aabb(tr.position, tr.scale * 0.5);
}
