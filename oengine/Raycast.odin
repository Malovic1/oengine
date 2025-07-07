package oengine

import rl "vendor:raylib"
import "core:math"
import "core:math/linalg"
import "core:fmt"

Raycast :: struct {
    position, target: Vec3,
}

rc_debug :: proc(using self: Raycast) {
    rl.DrawLine3D(position, target, rl.GREEN);
}

rc_is_colliding :: proc(using self: Raycast, transform: Transform, shape: ShapeType) -> (bool, Vec3) {
    if (shape == ShapeType.BOX) {
        tmin, tmax, tymin, tymax, tzmin, tzmax: f32;
        
        // apply rotation to ray
        rotationMatrix: Mat4 = mat4_from_yaw_pitch_roll(
            transform.rotation.y * rl.DEG2RAD,
            transform.rotation.x * rl.DEG2RAD,
            transform.rotation.z * rl.DEG2RAD,
        );

        rayDirRaw: Vec3 = target - position;
        ray_length := vec3_length(rayDirRaw);
        if (ray_length <= 0.0001) {
            return false, {}; // No valid direction
        }

        rayDirection: Vec3 = vec3_normalize(rayDirRaw);
        rotatedRayDirection: Vec3 = vec3_transform(rayDirection, rotationMatrix);
        
        boxSize: Vec3 = transform.scale;
        boxMin: Vec3 = transform.position - boxSize * 0.5;
        boxMax: Vec3 = transform.position + boxSize * 0.5;

        tmin = (boxMin.x - position.x) / rayDirection.x;
        tmax = (boxMax.x - position.x) / rayDirection.x;

        if (tmin > tmax) {
            tmin, tmax = tmax, tmin;
        }

        tymin = (boxMin.y - position.y) / rayDirection.y;
        tymax = (boxMax.y - position.y) / rayDirection.y;

        if (tymin > tymax) {
            tymin, tymax = tymax, tymin;
        }

        if ((tmin > tymax) || (tymin > tmax)) {
            return false, {};
        }

        if (tymin > tmin) {
            tmin = tymin;
        }

        if (tymax < tmax) {
            tmax = tymax;
        }

        tzmin = (boxMin.z - position.z) / rayDirection.z;
        tzmax = (boxMax.z - position.z) / rayDirection.z;

        if (tzmin > tzmax) {
            tzmin, tzmax = tzmax, tzmin;
        }

        if ((tmin > tzmax) || (tzmin > tmax)) {
            return false, {};
        }

        if (tzmin > tmin) {
            tmin = tzmin;
        }

        if (tzmax < tmax) {
            tmax = tzmax;
        }

        if (tmin < 0.0 || tmin > ray_length) {
            return false, {};
        }

        // Calculate contact point for a box
        contactPoint := position + rotatedRayDirection * tmin;
        return true, contactPoint;
    }
     
    if (shape == ShapeType.SPHERE) {
        t1, t2: f32;

        rayDirection: Vec3 = vec3_normalize(target - position);
        sphereCenter: Vec3 = transform.position;
        sphereRadius: f32 = transform.scale.x * 0.5;

        oc: Vec3 = position - sphereCenter;
        a: f32 = vec3_dot(rayDirection, rayDirection);
        b: f32 = 2.0 * vec3_dot(oc, rayDirection);
        c: f32 = vec3_dot(oc, oc) - sphereRadius * sphereRadius;
        discriminant: f32 = b * b - 4 * a * c;

        if (discriminant < 0) {
            return false, {};
        }

        sqrtDiscriminant: f32 = f32(math.sqrt(discriminant));
        t1 = (-b - sqrtDiscriminant) / (2.0 * a);
        t2 = (-b + sqrtDiscriminant) / (2.0 * a);

        if (t1 >= 0 || t2 >= 0) {
            // // Calculate contact point for a sphere
            contactPoint := position + rayDirection * t1; // You can choose either t1 or t2
            return true, contactPoint;
        }

        return false, {};
    }

    return false, {};
}

MSCCollisionInfo :: struct {
    t: ^TriangleCollider,
    point: Vec3,
    normal: Vec3,
    id: int,
}

get_mouse_rc :: proc(camera: Camera, scalar: f32 = 100) -> Raycast {
    rlc := rl.GetMouseRay(window.mouse_position, camera.rl_matrix);
    return Raycast {
        position = rlc.position,
        target = rlc.position + (rlc.direction * scalar),
    };
}

rc_is_colliding_msc :: proc(using self: Raycast, msc: ^MSCObject, closest := false) -> (bool, MSCCollisionInfo) {
    if (closest) {
        distance := F32_MAX;
        collision := false;
        info: MSCCollisionInfo;

        for i in 0..<len(msc.tris) {
            t := msc.tris[i];
            ok, pt := ray_tri_collision(self, t);
            if (ok) {
                normal := linalg.cross(t.pts[1] - t.pts[0], t.pts[2] - t.pts[0]);
                normal = linalg.normalize(normal);

                dist := vec3_dist(position, pt);
                if (dist < distance) {
                    info = {t, pt, normal, i};
                    distance = dist;
                }

                collision = true;
            }
        }

        return collision, info;
    }

    for i in 0..<len(msc.tris) {
        t := msc.tris[i];
        ok, pt := ray_tri_collision(self, t);
        if (ok) {
            // normal := linalg.cross(t.pts[1] - t.pts[0], t.pts[2] - t.pts[0]);
            // normal = linalg.normalize(normal);
            normal := t.normal;
            return true, {t, pt, normal, i};
        }
    }

    return false, {};
}

// the resulting array is sorted by the distance of collision
rc_colliding_tris :: proc(using self: Raycast, msc: ^MSCObject, sort := true) -> (bool, [dynamic]MSCCollisionInfo) {
    res := make([dynamic]MSCCollisionInfo);
    coll: bool;

    for i in 0..<len(msc.tris) {
        t := msc.tris[i];
        ok, pt := ray_tri_collision(self, t);
        if (ok) {
            // normal := linalg.cross(t.pts[1] - t.pts[0], t.pts[2] - t.pts[0]);
            // normal = linalg.normalize(normal);
            normal := t.normal; // no need to calculate normal again
            append(&res, MSCCollisionInfo{t, pt, normal, i});
            coll = true;
        }
    }

    if (sort) { sort_tris(self, &res); }
    return coll, res;
}

sort_tris :: proc(ray: Raycast, tris: ^[dynamic]MSCCollisionInfo) {
    for i in 0..<len(tris) {
        d1 := vec3_dist(ray.position, tris[i].point);
        for j in 0..<len(tris) {
            d2 := vec3_dist(ray.position, tris[j].point);
            if (d1 < d2) {
                temp := tris[i];
                tris[i] = tris[j];
                tris[j] = temp;
            }
        }
    }
}
