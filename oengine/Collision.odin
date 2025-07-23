package oengine

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"

CollisionInfo :: struct {
    normal: Vec3,
    depth: f32,
    point: Vec3,
}

collision_transforms :: proc {
    collision_transforms_plain,
    collision_transforms_pro,
}

collision_transforms_plain :: proc(a, b: Transform) -> bool {
    // Calculate half extents along each axis
    extents1 := Vec3 {a.scale.x / 2, a.scale.y / 2, a.scale.z / 2};
    extents2 := Vec3 {b.scale.x / 2, b.scale.y / 2, b.scale.z / 2};

    // Calculate the distance vector between the centers of the two boxes
    distanceX: f32 = abs(b.position.x - a.position.x);
    distanceY: f32 = abs(b.position.y - a.position.y);
    distanceZ: f32 = abs(b.position.z - a.position.z);

    // Calculate the penetration depths along each axis
    penetrationX: f32 = extents1.x + extents2.x - distanceX;
    penetrationY: f32 = extents1.y + extents2.y - distanceY;
    penetrationZ: f32 = extents1.z + extents2.z - distanceZ;

    // Determine the smallest penetration depth and corresponding normal
    if (penetrationX < 0 || penetrationY < 0 || penetrationZ < 0) {
        // No overlap along any axis, no collision
        return false;
    }

    // If execution reaches here, there is an overlap along at least one axis, indicating a collision
    return true;
}

collision_transforms_pro :: proc(a, b: Transform, contact: ^CollisionInfo) -> bool {
    // Calculate half extents along each axis
    extents1 := Vec3 {a.scale.x / 2, a.scale.y / 2, a.scale.z / 2};
    extents2 := Vec3 {b.scale.x / 2, b.scale.y / 2, b.scale.z / 2};

    // Calculate the distance vector between the centers of the two boxes
    distanceX: f32 = abs(b.position.x - a.position.x);
    distanceY: f32 = abs(b.position.y - a.position.y);
    distanceZ: f32 = abs(b.position.z - a.position.z);

    // Calculate the penetration depths along each axis
    penetrationX: f32 = extents1.x + extents2.x - distanceX;
    penetrationY: f32 = extents1.y + extents2.y - distanceY;
    penetrationZ: f32 = extents1.z + extents2.z - distanceZ;

    // Determine the smallest penetration depth and corresponding normal
    if (penetrationX < 0 || penetrationY < 0 || penetrationZ < 0) {
        // No overlap along any axis, no collision
        return false;
    }

    if (penetrationX < penetrationY && penetrationX < penetrationZ) {
        contact.normal.x = (b.position.x > a.position.x) ? -1.0 : 1.0;
        contact.normal.y = 0.0;
        contact.normal.z = 0.0;
        contact.depth = penetrationX;
    } else if (penetrationY < penetrationZ) {
        contact.normal.x = 0.0;
        contact.normal.y = (b.position.y > a.position.y) ? -1.0 : 1.0;
        contact.normal.z = 0.0;
        contact.depth = penetrationY;
    } else {
        contact.normal.x = 0.0;
        contact.normal.y = 0.0;
        contact.normal.z = (b.position.z > a.position.z) ? -1.0 : 1.0;
        contact.depth = penetrationZ;
    }

    // If execution reaches here, there is an overlap along at least one axis, indicating a collision
    return true;
}

OBB :: struct {
    pos, axis_x, axis_y, axis_z, half_size: Vec3
}

get_separating_plane :: proc(r_pos, plane: Vec3, box1, box2: OBB, contact: ^CollisionInfo) -> bool {
    collision := (abs(vec3_dot(r_pos, plane)) > 
        (abs((vec3_dot(box1.axis_x, plane)) * box1.half_size.x) +
        abs((vec3_dot(box1.axis_y, plane)) * box1.half_size.y) +
        abs((vec3_dot(box1.axis_z, plane)) * box1.half_size.z) +
        abs((vec3_dot(box2.axis_x, plane)) * box2.half_size.x) + 
        abs((vec3_dot(box2.axis_y, plane)) * box2.half_size.y) +
        abs((vec3_dot(box2.axis_z, plane)) * box2.half_size.z)));

    if (collision) {
        contact.normal = plane;

        depth1 := (abs(box1.half_size.x * (vec3_dot(box1.axis_x, plane))) +
                       abs(box1.half_size.y * (vec3_dot(box1.axis_y, plane))) +
                       abs(box1.half_size.z * (vec3_dot(box1.axis_z, plane))));
        depth2 := (abs(box2.half_size.x * (vec3_dot(box2.axis_x, plane))) +
                       abs(box2.half_size.y * (vec3_dot(box2.axis_y, plane))) +
                       abs(box2.half_size.z * (vec3_dot(box2.axis_z, plane))));

        contact.depth = depth1 + depth2;
    }

    // fmt.println(contact);
    // fmt.println(collision);
    return collision;
}

collision_transforms_obb :: proc(a, b: Transform, contact: ^CollisionInfo) -> bool {
    @(static) r_pos: Vec3;
    r_pos = b.position - a.position;

    box1 := OBB {
        pos = a.position,
        axis_x = {},
        axis_y = {},
        axis_z = {},
        half_size = a.scale * 0.5
    };
    set_axes_from_euler(&box1, a.rotation);

    box2 := OBB {
        pos = b.position,
        axis_x = {},
        axis_y = {},
        axis_z = {},
        half_size = b.scale * 0.5
    };
    set_axes_from_euler(&box2, b.rotation);

    return !(get_separating_plane(r_pos, box1.axis_x, box1, box2, contact) ||
        get_separating_plane(r_pos, box1.axis_y, box1, box2, contact) ||
        get_separating_plane(r_pos, box1.axis_z, box1, box2, contact) ||
        get_separating_plane(r_pos, box2.axis_x, box1, box2, contact) ||
        get_separating_plane(r_pos, box2.axis_y, box1, box2, contact) ||
        get_separating_plane(r_pos, box2.axis_z, box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_x, box2.axis_x), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_x, box2.axis_y), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_x, box2.axis_z), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_y, box2.axis_x), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_y, box2.axis_y), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_y, box2.axis_z), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_z, box2.axis_x), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_z, box2.axis_y), box1, box2, contact) ||
        get_separating_plane(r_pos, vec3_cross(box1.axis_z, box2.axis_z), box1, box2, contact));
}

collision_slope :: proc(slope: Slope, slope_trans, transform: Transform) -> (bool, f32) {
    x := slope_trans.position.x - transform.position.x;

    if (slope_trans.rotation.y == 45) {
        s_w := math.sqrt(
            math.pow(slope_trans.position.x, 2) + 
            math.pow(slope_trans.position.z, 2)
        );

        w := math.sqrt(
            math.pow(transform.position.x, 2) +
            math.pow(transform.position.z, 2)
        );

        x = s_w - w;
    }

    if (slope[0][0] == slope[1][0]) {
        x = -(slope_trans.position.z - transform.position.z);
    }

    object_height := transform.position.y;

    height := rb_slope_get_height_at(slope, x) + slope_trans.position.y;
    
    return object_height - transform.scale.y * 0.5 <= height, height;
}

ray_tri_collision :: proc(ray: Raycast, t: TriangleCollider) -> (bool, Vec3){
    edge1 := t.pts[1] - t.pts[0];
    edge2 := t.pts[2] - t.pts[0];

    dir := linalg.normalize(ray.target - ray.position); // Use normalized direction
    h := linalg.cross(dir, edge2);
    a := linalg.dot(edge1, h);

    if (linalg.abs(a) < 1e-8) {
        return false, {}; // Ray is parallel to the triangle
    }

    f := 1.0 / a;
    s := ray.position - t.pts[0];
    u := f * linalg.dot(s, h);

    if (u < 0.0 || u > 1.0) {
        return false, {};
    }

    q := linalg.cross(s, edge1);
    v := f * linalg.dot(dir, q);

    if (v < 0.0 || u + v > 1.0) {
        return false, {};
    }

    t_hit := f * linalg.dot(edge2, q);

    ray_length := linalg.length(ray.target - ray.position);
    if (t_hit > 1e-8 && t_hit <= ray_length) { // Ensure hit is within ray segment
        intersection_point := ray.position + dir * t_hit;
        return true, intersection_point;
    }

    return false, {};
}

ray_tri_resolve :: proc(ray: ^Raycast, t: TriangleCollider) {
    intersect, point := ray_tri_collision(ray^, t);

    if (intersect) {
        normal := linalg.cross(t.pts[1] - t.pts[0], t.pts[2] - t.pts[0]);
        normal = linalg.normalize(normal);

        distance := linalg.dot(point - ray.position, normal);

        if (distance < 0.0) {
            ray.target -= normal * distance;
        }
    }
}
