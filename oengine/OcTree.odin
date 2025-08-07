package oengine

import "core:fmt"
import rl "vendor:raylib"
import "fa"
import "core:math/linalg"

MIN_TRIS :: 8
MAX_DEPTH :: 6

BVHNode :: struct {
    aabb: AABB,
    left: ^BVHNode,
    right: ^BVHNode,
    tris: [dynamic]TriangleCollider, // only used in leaves
}

tri_centroid :: proc(t: TriangleCollider) -> Vec3 {
    return (t.pts[0] + t.pts[1] + t.pts[2]) / 3;
}

build_bvh :: proc(tris: [dynamic]TriangleCollider, depth: i32) -> ^BVHNode {
    node := new(BVHNode);
    node.aabb = tris_to_aabb(tris);

    if (len(tris) <= 4 || depth >= 16) {
        node.tris = tris;
        return node;
    }

    // Split axis: longest axis of AABB
    extent := aabb_max(node.aabb) - aabb_min(node.aabb);
    axis := 0;
    if extent.y > extent.x && extent.y > extent.z {
        axis = 1;
    } else if extent.z > extent.x {
        axis = 2;
    }

    // Sort triangles by centroid
    for i in 1..<len(tris) {
        temp := tris[i];
        key := tri_centroid(temp)[axis];
        j := i - 1;

        // Shift elements greater than key
        for (j >= 0) && (tri_centroid(tris[j])[axis] > key) {
            tris[j + 1] = tris[j];
            j -= 1;
        }

        tris[j + 1] = temp;
    }

    mid := len(tris) / 2;
    left := make([dynamic]TriangleCollider);
    right := make([dynamic]TriangleCollider);
    append(&left, ..tris[:mid]);
    append(&right, ..tris[mid:]);
    node.left  = build_bvh(left, depth+1);
    node.right = build_bvh(right, depth+1);

    return node;
}

rb_bvh_collision :: proc(rb: ^RigidBody, node: ^BVHNode) {
    rb_aabb := trans_to_aabb(rb.transform);

    if (!aabb_collision(rb_aabb, node.aabb)) {
        return;
    }

    if (node.tris != nil) {
        for tri in node.tris {
            coll, _ := ray_tri_collision(rb._down, tri);
            if (coll) {
                rb.grounded = true;
            }

            resolve_tri_collision(rb, tri);
        }
        return;
    }

    if (node.left != nil) {
        rb_bvh_collision(rb, node.left);
    }

    if (node.right != nil) {
        rb_bvh_collision(rb, node.right);
    }
}

OctreeNode :: struct {
    aabb: AABB,
    children:  [8]^OctreeNode,
    triangles: [dynamic]TriangleCollider,
    triangle_bvh: ^BVHNode,
    is_leaf: bool,
}

build_octree :: proc(tris: [dynamic]TriangleCollider, aabb: AABB, depth: i32) -> ^OctreeNode {
    node := new(OctreeNode);
    node.aabb = aabb;

    if (depth >= MAX_DEPTH || len(tris) <= MIN_TRIS) {
        node.triangles = tris    
        if (len(tris) > 8) {
            node.triangle_bvh = build_bvh(tris, 0);
        }
        node.is_leaf = true;
        return node;
    }

    child_boxes := split_aabb_8(aabb);
    children_tris := make([][dynamic]TriangleCollider, 8);

    for tri in tris {
        tri_aabb := compute_aabb(tri.pts[0], tri.pts[1], tri.pts[2]);
        for j in 0..<8 {
            if (aabb_collision(tri_aabb, child_boxes[j])) {
                append(&children_tris[j], tri);
            }
        }
    }

    for i in 0..<8 {
        if (len(children_tris[i]) > 0) {
            node.children[i] = build_octree(children_tris[i], child_boxes[i], depth + 1);
        }
    }

    return node;
}

query_octree :: proc(node: ^OctreeNode, rb: ^RigidBody) {
    aabb := trans_to_aabb(rb.transform);
    if (!aabb_collision(node.aabb, aabb)) { return; }

    if (node.is_leaf) {
        if (node.triangle_bvh != nil) {
            rb_bvh_collision(rb, node.triangle_bvh);
        } else {
            for tri in node.triangles {
                coll, _ := ray_tri_collision(rb._down, tri);
                if (coll) {
                    rb.grounded = true;
                }

                resolve_tri_collision(rb, tri);
            }
        }
        return;
    }

    for i in 0..<len(node.children) {
        child := node.children[i];
        if (child != nil) {
            query_octree(child, rb);
        }
    }
}

ray_bvh_info :: proc(node: ^BVHNode, ray: Raycast) -> (bool, MSCCollisionInfo) {
    hit_found := false;
    closest_info: MSCCollisionInfo;
    closest_dist := F32_MAX;

    if (node.tris != nil) {
        for i in 0..<len(node.tris) {
            tri := node.tris[i];
            coll, point := ray_tri_collision(ray, tri);
            if (coll) {
                dist := linalg.length2(ray.position - point);

                normal := tri.normal;
                if (dist < closest_dist) {
                    closest_dist = dist;
                    closest_info = MSCCollisionInfo{tri, point, normal, i};
                    hit_found = true;
                }
            }
        }
        return hit_found, closest_info;
    }

    left_hit, left_info := ray_bvh_info(node.left, ray);
    if (left_hit) {
        d := linalg.length2(ray.position - left_info.point);
        if (d < closest_dist) {
            closest_dist = d;
            closest_info = left_info;
            hit_found = true;
        }
    }

    right_hit, right_info := ray_bvh_info(node.right, ray);
    if (right_hit) {
        d := linalg.length2(ray.position - right_info.point);
        if (d < closest_dist) {
            closest_dist = d;
            closest_info = right_info;
            hit_found = true;
        }
    }

    return hit_found, closest_info;
}

ray_octree_info :: proc(
    node: ^OctreeNode, ray: Raycast) -> (bool, MSCCollisionInfo) {
    hit_found := false;
    closest_info: MSCCollisionInfo;
    closest_dist := F32_MAX;

    if (node.is_leaf) {
        if (node.triangle_bvh != nil) {
            return ray_bvh_info(node.triangle_bvh, ray);
        }

        for i in 0..<len(node.triangles) {
            tri := node.triangles[i];
            coll, point := ray_tri_collision(ray, tri);
            if (coll) {
                // normal := linalg.normalize(
                //     linalg.cross(tri.pts[1] - tri.pts[0], tri.pts[2] - tri.pts[0]));
                normal := tri.normal;
                dist := linalg.length2(ray.position - point);

                if (dist < closest_dist) {
                    closest_dist = dist;
                    closest_info = {tri, point, normal, i};
                    hit_found = true;
                }
            }
        }
        return hit_found, closest_info;
    }

    // For non-leaf nodes check children
    for i in 0..<len(node.children) {
        child := node.children[i];
        if (child != nil) {
            child_hit, child_info := ray_octree_info(child, ray);
            if (child_hit) {
                dist := linalg.length2(ray.position - child_info.point);
                if (dist < closest_dist) {
                    closest_dist = dist;
                    closest_info = child_info;
                    hit_found = true;
                }
            }
        }
    }

    return hit_found, closest_info;
}

render_octree :: proc(node: ^OctreeNode, depth: i32) {
    if node == nil {
        return;
    }

    color := Color {255 - u8(depth) * 20, 255 - u8(depth) * 20, 255, 255};

    draw_aabb_wires(node.aabb, color);

    for i in 0..<8 {
        render_octree(node.children[i], depth + 1);
    }
}

free_octree :: proc(node: ^OctreeNode) {
    if (node == nil) { return; }

    for i in 0..<8 {
        if node.children[i] != nil {
            free_octree(node.children[i]);
            node.children[i] = nil;
        }
    }

    if (node.is_leaf && node.triangles != nil) {
        node.triangles = nil;
    }

    free(node);
}
