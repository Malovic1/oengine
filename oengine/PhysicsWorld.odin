package oengine

import "core:math"
import "core:math/linalg"
import "core:fmt"

import "fa"

DEFAULT_RESTITUTION :: 0.5
COLLISION_MASK_SIZE :: 10
DAMPING_VEL_FACTOR :: 0.994

MAX_RBS :: 1024
MAX_JOINTS :: 1024
MAX_RAYCASTS :: 128
MAX_MSCS :: 64

WORLD_SIZE :: 200
SECTOR_SIZE :: 10
WORLD_SECTOR_SIZE :: WORLD_SIZE / SECTOR_SIZE

OCTREE_SIZE :: 500

TriangleCollider :: struct {
    using pts: [3]Vec3,
    normal: Vec3,
    color: Color,
    texture_tag: string,
    rot: i32,
    is_lit: bool,
    use_fog: bool,
    flipped: bool,
    division_level: i32,
}

PhysicsWorld :: struct {
    bodies: fa.FixedArray(^RigidBody, MAX_RBS),
    reverse_slopes: [dynamic]u32,
    joints: fa.FixedArray(^Joint, MAX_JOINTS),
    mscs: fa.FixedArray(^MSCObject, MAX_MSCS),
    tree: BodyOctree,

    gravity: Vec3,
    delta_time: f32,
    iterations: i32,

    paused: bool,
}

pw_init :: proc(using self: ^PhysicsWorld, s_gravity: Vec3, s_iter: i32 = 8) {
    bodies = fa.fixed_array(^RigidBody, MAX_RBS);
    joints = fa.fixed_array(^Joint, MAX_JOINTS);
    mscs = fa.fixed_array(^MSCObject, MAX_MSCS);
    tree = make_tree({}, vec3_one() * OCTREE_SIZE);

    gravity = s_gravity;
    iterations = s_iter;
}

pw_debug :: proc(using self: ^PhysicsWorld) {
    if (PHYS_OCTREE_DEBUG) {
        for i in 0..<mscs.len {
            msc := mscs.data[i];
            render_octree(msc.tree, 0);
        }
    }
}

ContactPair :: struct {
    a, b: int,
}

pw_update :: proc(using self: ^PhysicsWorld, dt: f32) {
    delta_time = dt;
    if (paused) { return; }

    candidates: [dynamic]int;
    defer delete(candidates);

    for n: i32; n < iterations; n += 1 {
        bo_clear_tree(tree.root);

        for i := 0; i < fa.range(bodies); i += 1 {
            rb := bodies.data[i];
            if (rb == nil) { continue; }
            rb_fixed_update(rb, delta_time / f32(iterations));
            rb._front_hit = {};
            rb._up_hit = {};
            fa.clear(&rb.contacts);

            insert_octree(tree.root, int(rb.id), get_aabb(int(rb.id)));
                    
            for j in 0..<fa.range(mscs) {
                msc := mscs.data[j];
                if (msc == nil) { continue; }
                if (!aabb_collision(msc._aabb, trans_to_aabb(rb.transform))) {
                    continue;
                }

                if (rb.is_static) do continue;

                if (msc.tree != nil) {
                    query_octree(msc.tree, rb, dt);
                }
            }

            resolve_contacts(rb, dt);
        }

        for i in 0..<fa.range(bodies) {
            rb := bodies.data[i];
            if (rb == nil || rb.is_static) { continue; }

            clear(&candidates);
            bo_query_octree(tree.root, get_aabb(int(rb.id)), &candidates);
            for other_id in candidates {
                if (other_id == int(rb.id)) { continue; }

                rb2 := bodies.data[other_id];
                if (rb2 == nil) { continue; }

                if (ignored(rb, rb2)) { continue; }

                coll, _ := rc_is_colliding(rb._down, rb2.transform, .BOX);
                if (coll) { rb.grounded = true; }

                info := rc_is_colliding_info(
                    rb._front, rb2.transform, .BOX
                );
                if (info.collision) { rb._front_hit = info; }

                info2 := rc_is_colliding_info(
                    rb._up, rb2.transform, .BOX
                );
                if (info2.collision) { rb2._up_hit = info2; }

                if (!collision_transforms(rb.transform, rb2.transform)) { continue; }

                // Narrowphase
                if (rb.shape == ShapeType.HEIGHTMAP) {
                    resolve_heightmap_collision(rb, rb2);
                } else if (rb2.shape == ShapeType.HEIGHTMAP) {
                    resolve_heightmap_collision(rb2, rb);
                } else if (rb.shape == ShapeType.SLOPE) {
                    resolve_slope_collision(self, rb, rb2);
                } else if (rb2.shape == ShapeType.SLOPE) {
                    resolve_slope_collision(self, rb2, rb);
                } else {
                    resolve_aabb_collision(self, rb, rb2);
                }
            }
        }

        for i in 0..<fa.range(joints) {
            joint := joints.data[i];
            if (joint == nil) { continue; }
            joint.update(joint);
        }
    }
}

pw_deinit :: proc(using self: ^PhysicsWorld) {
    for i in 0..<fa.range(joints) {
        joint := joints.data[i];
        free(joint);
    }

    // do something with this
    // for i in 0..<fa.range(mscs) {
    //     free(mscs.data[i]);
    // }
}

@(private = "file")
ignored :: proc(rb, rb2: ^RigidBody) -> bool {
    return rb.is_static && rb2.is_static ||
           rb.shape == ShapeType.HEIGHTMAP && rb2.shape == ShapeType.HEIGHTMAP ||
           rb.shape == ShapeType.SLOPE && rb2.shape == ShapeType.SLOPE ||
           rb.id == rb2.id ||
           !compare_masks(rb.collision_mask, rb2.collision_mask);
}

@(private = "file") 
resolve_heightmap_collision :: proc(terrain, rb: ^RigidBody) {
    if (rb.is_static) { return; }

    terrain_height := rb_get_height_terrain_at(
        terrain, rb.transform.position.x, rb.transform.position.z);

    bottom_y := rb.transform.position.y - rb.transform.scale.y * 0.5;
    penetration := terrain_height - bottom_y;

    if penetration > 0 {
        rb.transform.position.y += penetration;

        if rb.velocity.y < 0 {
            rb.velocity.y = 0;
        }

        rb.grounded = true;
    }
}

@(private = "file")
resolve_slope_collision :: proc(using self: ^PhysicsWorld, rb, rb2: ^RigidBody) { // rb is the slope rb2 is something else
    collision, height := collision_slope(rb.shape_variant.(Slope), rb.transform, rb2.transform);

    orientation_check := (rb2.transform.position.z < rb.transform.position.z - rb.transform.scale.z * 0.5) ||
    (rb2.transform.position.z > rb.transform.position.z + rb.transform.scale.z * 0.5);

    if (rb_slope_orientation(rb) == .Z) {
        orientation_check = (rb2.transform.position.x < rb.transform.position.x - rb.transform.scale.x * 0.5) ||
        (rb2.transform.position.x > rb.transform.position.x + rb.transform.scale.x * 0.5);
    }

    if (orientation_check) {
        resolve_slope_side_collision(self, rb, rb2, height);
    }

    coll_transform := Transform {
        position = rb.transform.position,
        rotation = rb.transform.rotation,
        scale = rb.transform.scale - 0.5,
    };
    if (collision && collision_transforms(coll_transform, rb2.transform)) {
        reverse := false
        for i in reverse_slopes {
            if (rb.id == i) {
                reverse = true;
                break;
            }
        }

        if (reverse) {
            if (rb2.transform.position.y + rb2.transform.scale.y > height) {
                rb2.transform.position.y = height - rb2.transform.scale.y; 
            }
        } else {
            rb2.transform.position.y = height + rb2.transform.scale.y * 0.5;
        }
    }
}

@(private = "file")
resolve_slope_side_collision :: proc(using self: ^PhysicsWorld, rb, rb2: ^RigidBody, height: f32) {
    contact: CollisionInfo;
    if (collision_transforms(rb2.transform, rb.transform, &contact)) {
        contact.point = vec3_lerp(rb2.transform.position, rb.transform.position, 0.5);

        if (rb2.transform.position.y - rb2.transform.scale.y * 0.5 < height) {
            resolve_collision(rb2, contact.normal, contact.depth);
            resolve_joints(self, rb2, contact.normal, contact.depth); 
        }
    }
}

@(private = "file")
resolve_aabb_collision :: proc(using self: ^PhysicsWorld, rb, rb2: ^RigidBody) {
    contact: CollisionInfo;
    if (collision_transforms(rb.transform, rb2.transform, &contact)) {
        contact.point = vec3_lerp(rb.transform.position, rb2.transform.position, 0.5);

        if (rb2.is_static) {
            resolve_collision(rb, contact.normal, contact.depth);
            resolve_joints(self, rb, contact.normal, contact.depth); 
        } else if (rb.is_static) {
            resolve_collision(rb2, contact.normal, -contact.depth);
            resolve_joints(self, rb2, contact.normal, -contact.depth);
        } else {
            if (rb.joints.len != 0) {
                for jj in 0..<rb.joints.len {
                    j := rb.joints.data[jj];
                    if (joints.data[j].variant.(^FixedJoint).child.id == rb2.id || 
                        joints.data[j].variant.(^FixedJoint).parent.id == rb2.id) {
                        return;
                    }
                }
            }

            // resolve_collision(rb, contact.normal, (contact.depth * 0.5));
            // resolve_collision(rb2, contact.normal, -(contact.depth * 0.5));
            inv_mass1 := rb_inverse_mass(rb^);
            inv_mass2 := rb_inverse_mass(rb2^);
            total_inv_mass := inv_mass1 + inv_mass2;

            // Avoid division by zero
            if total_inv_mass > 0 {
                move1 := contact.depth * (inv_mass1 / total_inv_mass);
                move2 := contact.depth * (inv_mass2 / total_inv_mass);

                resolve_collision(rb, contact.normal, move1);
                resolve_collision(rb2, contact.normal, -move2);
            }
        }

        relative_vel := rb2.velocity - rb.velocity;

        if (vec3_dot(relative_vel, contact.normal) < 0) {
            e: f32 = math.min(rb.restitution, rb2.restitution);

            j: f32 = -(1 + e) * vec3_dot(relative_vel, contact.normal);
            j /= rb_inverse_mass(rb^) + rb_inverse_mass(rb2^);

            impulse := contact.normal * j;

            rb_apply_impulse(rb, impulse);
            rb_apply_impulse(rb2, -impulse);
        }

        // friction
        rb_apply_force(rb, rb.force * rb2.friction);
        rb_apply_force(rb2, rb2.force * rb.friction);
    }
}

@(private = "file")
resolve_joints :: proc(using self: ^PhysicsWorld, rb: ^RigidBody, normal: Vec3, depth: f32) {
    if (rb.joints.len != 0) {
        for j in 0..<rb.joints.len {
            joint := joints.data[rb.joints.data[j]];
            fj := joint.variant.(^FixedJoint);

            if (fj.parent.id == rb.id) {
                resolve_collision(fj.child, normal, (depth * 0.3));
            } else {
                resolve_collision(fj.parent, normal, (depth * 0.3));
            }
        }
    }
}

@(private = "file")
resolve_collision :: proc(rb: ^RigidBody, normal: Vec3, depth: f32) {
    rb.transform.position.x += normal.x * depth;
    rb.transform.position.y += normal.y * depth;
    rb.transform.position.z += normal.z * depth;
}

@(private)
resolve_tri_collision :: proc(rb: ^RigidBody, t: TriangleCollider, dt: f32) {
    if (rb.shape != .CAPSULE) {
        center := rb.transform.position;
        extents := rb.transform.scale * 0.5;

        // Move triangle into AABB space
        v0 := t.pts[0] - center;
        v1 := t.pts[1] - center;
        v2 := t.pts[2] - center;

        // Triangle edges
        e0 := v1 - v0;
        e1 := v2 - v1;
        e2 := v0 - v2;

        penetration := F32_MAX;
        best_axis := Vec3{};

        test_axis :: proc(v0, v1, v2, axis: Vec3, penetration: ^f32, extents: Vec3, best_axis: ^Vec3) -> bool {
            if linalg.length2(axis) < 0.000001 {
                return true; // skip degenerate axis
            }

            // Normalize axis for stable penetration depth
            axis_n := linalg.normalize(axis);

            p0 := linalg.dot(v0, axis_n);
            p1 := linalg.dot(v1, axis_n);
            p2 := linalg.dot(v2, axis_n);

            min_p := min(p0, min(p1, p2));
            max_p := max(p0, max(p1, p2));

            r :=
                extents.x * abs(axis_n.x) +
                extents.y * abs(axis_n.y) +
                extents.z * abs(axis_n.z);

            if min_p > r || max_p < -r {
                return false; // separating axis → no collision
            }

            overlap := min(r - min_p, max_p + r);

            if overlap < penetration^ {
                penetration^ = overlap;
                best_axis^ = axis_n;
            }

            return true;
        };

        // --- 1. AABB face axes ---
        if !test_axis(v0, v1, v2, vec3_x(), &penetration, extents, &best_axis) do return;
        if !test_axis(v0, v1, v2, vec3_y(), &penetration, extents, &best_axis) do return;
        if !test_axis(v0, v1, v2, vec3_z(), &penetration, extents, &best_axis) do return;

        // --- 2. Triangle normal ---
        tri_normal := linalg.cross(e0, e1);
        if !test_axis(v0, v1, v2, tri_normal, &penetration, extents, &best_axis) do return;

        // --- 3. Edge cross products (9 axes) ---
        box_axes := [3]Vec3{vec3_x(), vec3_y(), vec3_z()};
        tri_edges := [3]Vec3{e0, e1, e2};

        for e in tri_edges {
            for a in box_axes {
                axis := linalg.cross(a, e);
                if !test_axis(v0, v1, v2, axis, &penetration, extents, &best_axis) do return;
            }
        }

        // --- Collision confirmed ---
        resolve_normal := best_axis;

        // Make sure it pushes OUT of triangle
        to_center := center - t.pts[0];
        if linalg.dot(resolve_normal, to_center) < 0 {
            resolve_normal = -resolve_normal;
        }

        // Apply positional correction
        // rb.transform.position += resolve_normal * penetration;
        if (rb.contacts.len < MAX_CONTACTS) {
            fa.append(&rb.contacts, Contact{resolve_normal, penetration});
        }

        return;
    }

    // --- Capsule definition ---
    radius := rb.transform.scale.x * 0.5;
    height := rb.transform.scale.y;

    // assume position is bottom of capsule
    p0 := rb.transform.position;
    p1 := p0 + Vec3{0, height, 0};

    // --- Closest points ---
    seg_pt, tri_pt := closest_pt_segment_triangle(p0, p1, t);

    delta := seg_pt - tri_pt;
    dist2 := linalg.dot(delta, delta);

    if dist2 >= radius * radius {
        return;
    }

    dist := linalg.sqrt(dist2);

    // --- Compute normal ---
    normal: Vec3;

    if dist > 0.00001 {
        normal = delta / dist;
    } else {
        // fallback if perfectly overlapping
        normal = t.normal;
    }

    penetration := radius - dist;

    // --- Optional: stabilize ground contact ---
    up := vec3_y();
    if linalg.dot(normal, up) > 0.5 {
        normal = t.normal;
    }

    // --- Resolve position ---
    if (rb.contacts.len < MAX_CONTACTS) {
        fa.append(&rb.contacts, Contact{normal, penetration});
    }
}

resolve_contacts :: proc(rb: ^RigidBody, dt: f32) {
    if rb.contacts.len == 0 {
        return;
    }

    EPSILON :: 0.0001
    MAX_STEP := rb.transform.scale.y * 0.5
    ITER_SUBSTEPS :: 2

    up := vec3_y()

    for substep in 0..<ITER_SUBSTEPS {

        total_normal := Vec3{}
        total_weight: f32 = 0.0
        max_penetration: f32 = 0.0

        for i in 0..<rb.contacts.len {
            c := rb.contacts.data[i]

            total_normal += c.normal * c.penetration
            total_weight += c.penetration

            if c.penetration > max_penetration {
                max_penetration = c.penetration
            }
        }

        if total_weight < EPSILON {
            break
        }

        resolve_normal := linalg.normalize(total_normal / total_weight)

        slope_dot := linalg.dot(resolve_normal, up)

        if slope_dot > 0.5 {
            resolve_normal = up
        }

        move_vec := resolve_normal * max_penetration
        move_len := linalg.length(move_vec)

        if move_len > MAX_STEP {
            move_vec *= MAX_STEP / move_len
        }

        rb.transform.position += move_vec

        vel_dot := linalg.dot(rb.velocity, resolve_normal)

        if vel_dot < -EPSILON {
            rb.velocity -= resolve_normal * vel_dot

            if OE_SLOPE_SLIDING && (slope_dot >= OE_SLOPE_THRESHOLD || slope_dot < 0) {

                MOVING_EPSILON :: 0.1
                vel_len := linalg.length(rb.velocity.xz)

                if slope_dot < 1.0 && vel_len < MOVING_EPSILON {

                    recalc := linalg.dot(rb.velocity, resolve_normal)
                    vel_tangent := rb.velocity - resolve_normal * recalc

                    speed := linalg.length(vel_tangent)
                    if speed > EPSILON {
                        friction := min(rb.friction * dt, speed)
                        vel_tangent *= max(0, speed - friction) / speed
                    }

                    rb.velocity = vel_tangent
                }
            }
        }
    }

    fa.clear(&rb.contacts)
}

@(private)
check_tri_collision :: proc(
    position: Vec3,
    scale: Vec3, // box dimensions
    t: TriangleCollider,
) -> (bool, MSCCollisionInfo) {
    result: MSCCollisionInfo;

    // Closest point on triangle to box center
    closest := closest_point_on_triangle(
        position,
        t.pts[0],
        t.pts[1],
        t.pts[2],
    );

    diff := position - closest;

    half := scale * 0.5;

    // Ellipsoid-style normalization
    adjusted := Vec3{
        diff.x / half.x,
        diff.y / half.y,
        diff.z / half.z,
    };

    dist := linalg.length(adjusted);

    RAD :: 1.0;

    if dist >= RAD {
        return false, result; // no hit
    }

    // Avoid divide-by-zero
    EPS :: 1e-6;
    if dist < EPS {
        // Fallback: triangle normal
        normal := linalg.normalize(
            linalg.cross(
                t.pts[1] - t.pts[0],
                t.pts[2] - t.pts[0],
            )
        );

        result.t = t;
        result.point = closest;
        result.normal = normal;

        return true, result;
    }

    normal := adjusted / dist;

    result.t = t;
    result.point = closest;
    result.normal = normal;

    return true, result;
}
