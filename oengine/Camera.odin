package oengine

import rl "vendor:raylib"
import "core:math"
import "core:math/linalg"

Camera :: struct {
    fov, near, far: f32,

    rl_matrix: rl.Camera,

    position, rotation, target: Vec3,
    up, right, front: Vec3,

    prev_mp, curr_mp: Vec2,

    raycast: Raycast,
    frustum: Frustum,
}

cm_init :: proc(s_position: Vec3, s_fov: f32 = 60, s_near: f32 = 0.1, s_far: f32 = 100) -> Camera {
    using res: Camera;
    
    fov = s_fov;
    near = s_near;
    far = s_far;

    position = s_position;
    target = vec3_zero();
    up = vec3_y();

    prev_mp = {};
    curr_mp = {};

    right = vec3_zero();
    rotation = vec3_zero();
    front = -vec3_z();

    raycast = Raycast {
        position,
        position + front * far,
    };

    return res;
}

cm_update :: proc(using self: ^Camera) {
    rl_matrix.position = position;
    rl_matrix.target = target;
    rl_matrix.up = up;
    rl_matrix.fovy = fov;

    raycast.position = position;
    raycast.target = position + vec3_normalize(front) * far;

    frustum = CameraGetFrustum(self^, w_render_aspect());
}

cm_set_fps :: proc(using self: ^Camera, sensitivity: f32, is_mouse_locked: bool) {
    if (is_mouse_locked) {
        rl.HideCursor();
        curr_mp = rl.GetMousePosition();
        mouseDelta := Vec2 {curr_mp.x - prev_mp.x, -(curr_mp.y - prev_mp.y)};
        rotation.y += mouseDelta.x * sensitivity;
        rotation.x -= mouseDelta.y * sensitivity;

        // Clamp camera pitch to avoid flipping
        if (rotation.x > 89.0) do rotation.x = 89.0;
        if (rotation.x < -89.0) do rotation.x = -89.0;

        prev_mp = curr_mp;
        rl.SetMousePosition(rl.GetScreenWidth() / 2, rl.GetScreenHeight() / 2);
        prev_mp = rl.GetMousePosition();
    } else {
        rl.ShowCursor();
    }
    
    cameraRotation: Mat4 = mat4_rotate_XYZ(rl.DEG2RAD * rotation.x, rl.DEG2RAD * rotation.y, rl.DEG2RAD * rotation.z);
    front = vec3_transform(-vec3_z(), cameraRotation);
    right = vec3_transform(vec3_x(), cameraRotation);
    up = vec3_transform(vec3_y(), cameraRotation);
}

cm_set_fps_controls :: proc(using self: ^Camera, speed: f32, is_mouse_locked, fly: bool) {
    if (rl.IsKeyDown(rl.KeyboardKey.W) && is_mouse_locked) {
        position.x += front.x * speed * rl.GetFrameTime();
        position.z += front.z * speed * rl.GetFrameTime();
    }

    if (rl.IsKeyDown(rl.KeyboardKey.S) && is_mouse_locked) {
        position.x -= front.x * speed * rl.GetFrameTime();
        position.z -= front.z * speed * rl.GetFrameTime();
    }
    
    if (rl.IsKeyDown(rl.KeyboardKey.A) && is_mouse_locked) {
        position.x -= right.x * speed * rl.GetFrameTime();
        position.z -= right.z * speed * rl.GetFrameTime();
    }

    if (rl.IsKeyDown(rl.KeyboardKey.D) && is_mouse_locked) {
        position.x += right.x * speed * rl.GetFrameTime();
        position.z += right.z * speed * rl.GetFrameTime();
    }
    
    if (fly) {
        if (rl.IsKeyDown(rl.KeyboardKey.SPACE) && is_mouse_locked) {
            position.y += speed * rl.GetFrameTime();
        }
        if (rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) || (rl.IsKeyDown(rl.KeyboardKey.LEFT_SUPER)) && is_mouse_locked) {
            position.y -= speed * rl.GetFrameTime();
        }
    }
}

cm_default_fps_matrix :: proc(using self: ^Camera) {
    target = position + front;
}

cm_look_at :: proc(using self: ^Camera, target_position: Vec3) {
    self.target = target_position;

    self.front = vec3_normalize(self.target - self.position);
    world_up := vec3_y();

    self.right = vec3_normalize(vec3_cross(world_up, self.front));
    self.up = vec3_cross(self.front, self.right);
}

cm_set_third_person :: proc(
    using self: ^Camera, 
    player_position: Vec3, 
    sensitivity: f32, 
    is_mouse_locked: bool, 
    distance_from_player: f32,
    offset: Vec3 = {0, 1, 0}) {
    if (is_mouse_locked) {
        rl.HideCursor();
        curr_mp = rl.GetMousePosition();
        mouseDelta := Vec2 {curr_mp.x - prev_mp.x, -(curr_mp.y - prev_mp.y)};
        rotation.y += mouseDelta.x * sensitivity;
        rotation.x -= mouseDelta.y * sensitivity;

        // Clamp pitch
        if (rotation.x > 89.0) do rotation.x = 89.0;
        if (rotation.x < -89.0) do rotation.x = -89.0;

        prev_mp = curr_mp;
        rl.SetMousePosition(rl.GetScreenWidth() / 2, rl.GetScreenHeight() / 2);
        prev_mp = rl.GetMousePosition();
    } else {
        rl.ShowCursor();
    }

    // Build camera rotation matrix
    cameraRotation: Mat4 = mat4_rotate_XYZ(rl.DEG2RAD * rotation.x, rl.DEG2RAD * rotation.y, rl.DEG2RAD * rotation.z);
    front = vec3_transform(-vec3_z(), cameraRotation); // Direction the camera looks at
    right = vec3_transform(vec3_x(), cameraRotation);
    up = vec3_transform(vec3_y(), cameraRotation);

    // Set camera position to be behind the player
    position = player_position - front * distance_from_player + offset;
    target = player_position; // Look at player
}
