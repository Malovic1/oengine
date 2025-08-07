package oengine

import "core:math"
import "core:math/linalg"
import "core:fmt"
import rl "vendor:raylib"
import "fa"

DEFAULT_RESTITUTION :: 0.5
COLLISION_MASK_SIZE :: 10
DAMPING_VEL_FACTOR :: 0.994

MAX_RBS :: 1024
MAX_JOINTS :: 1024
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

    @static candidates: [dynamic]int;

    for n: i32; n < iterations; n += 1 {
        bo_clear_tree(tree.root);
        clear(&candidates);

        for i := 0; i < fa.range(bodies); i += 1 {
            rb := bodies.data[i];
            if (rb == nil) { continue; }
            rb_fixed_update(rb, delta_time / f32(iterations));

            insert_octree(tree.root, int(rb.id), get_aabb(int(rb.id)));
                    
            for i in 0..<fa.range(mscs) {
                msc := mscs.data[i];
                if (msc == nil) { continue; }
                if (!aabb_collision(msc._aabb, trans_to_aabb(rb.transform))) {
                    continue;
                }

                if (rb.is_static) do continue;

                // for tri in msc.tris {
                //     resolve_tri_collision(rb, tri);
                // }
                if (msc.tree != nil) {
                    query_octree(msc.tree, rb);
                }
            }
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
                if (coll) {
                    rb.grounded = true;
                }

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
resolve_tri_collision :: proc(rb: ^RigidBody, t: TriangleCollider) {
    // Get the dimensions of the cube
    cube_dimensions := rb.transform.scale; // Assuming `scale` is used to store dimensions here

    // Scale the player's position
    scaled_position := rb.transform.position;

    // Calculate the closest point on the triangle
    closest := closest_point_on_triangle(scaled_position, t.pts[0], t.pts[1], t.pts[2]);
    diff := scaled_position - closest;

    // Adjust the distance calculation to account for cube dimensions
    half_dimensions := cube_dimensions * 0.5;
    adjusted_diff := Vec3{
        diff.x / half_dimensions.x,
        diff.y / half_dimensions.y,
        diff.z / half_dimensions.z,
    };
    dist := linalg.length(adjusted_diff);

    normal := adjusted_diff / dist;

    RAD :: 1

    if dist < RAD {
        // Adjust position considering the cube dimensions
        rb.transform.position += Vec3{
            normal.x * (RAD - dist) * half_dimensions.x,
            normal.y * (RAD - dist) * half_dimensions.y,
            normal.z * (RAD - dist) * half_dimensions.z,
        };

        // Project velocity to the normal plane if moving towards it
        vel_normal_dot := linalg.dot(rb.velocity, normal);
        if vel_normal_dot < 0 {
            rb.velocity -= normal * vel_normal_dot;
        }
    }
}
