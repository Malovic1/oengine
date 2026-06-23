package oengine


import "core:math/linalg"
import "core:math"

BoundingBoxCornersFlag :: enum u8 {
	BOX_NO_CORNER          = 0,

	BOX_FRONT_BOTTOM_LEFT  = 1,
	BOX_FRONT_BOTTOM_RIGHT = 2,
	BOX_FRONT_TOP_LEFT     = 4,
	BOX_FRONT_TOP_RIGHT    = 8,

	BOX_BACK_BOTTOM_LEFT   = 16,
	BOX_BACK_BOTTOM_RIGHT  = 32,
	BOX_BACK_TOP_LEFT      = 64,
	BOX_BACK_TOP_RIGHT     = 128,

	BOX_ALL_CORNERS        = 255,
}

Frustum :: struct {
	up    : rl_Vector4,
	down  : rl_Vector4,
	left  : rl_Vector4,
	right : rl_Vector4,
	near  : rl_Vector4,
	far   : rl_Vector4,
}

// Computes the signed distance from a point to a plane.
PlaneDistanceToPoint :: proc(plane: rl_Vector4, point: rl_Vector3) -> f32 {
	d := point.x * plane.x + point.y * plane.y + point.z * plane.z + plane.w
	e := math.sqrt(plane.x * plane.x + plane.y * plane.y + plane.z * plane.z)
	return d / e
}

CheckCollisionPlanePoint :: proc(plane: rl_Vector4, point: rl_Vector3) -> bool {
	return PlaneDistanceToPoint(plane, point) <= 0.0
}

CheckCollisionPlaneSphere :: proc(plane: rl_Vector4, center: rl_Vector3, radius: f32) -> bool {
	return PlaneDistanceToPoint(plane, center) <= radius
}

CheckCollisionPlaneBox :: proc(plane: rl_Vector4, box: rl_BoundingBox) -> bool {
	corners := [?]rl_Vector3{
		box.min,
		box.max,
		{box.min.x, box.max.y, box.min.z},
		{box.max.x, box.max.y, box.min.z},
		{box.max.x, box.min.y, box.min.z},
		{box.min.x, box.min.y, box.max.z},
		{box.min.x, box.max.y, box.max.z},
		{box.max.x, box.min.y, box.max.z},
	};

	for point in corners {
		if CheckCollisionPlanePoint(plane, point) do return true
	}

	return false
}

CheckCollisionPlaneBoxEx :: proc(plane: rl_Vector4, box: rl_BoundingBox) -> BoundingBoxCornersFlag {
	result: BoundingBoxCornersFlag = .BOX_NO_CORNER

	if CheckCollisionPlanePoint(plane, box.min)                                       do result |= .BOX_FRONT_BOTTOM_LEFT
	if CheckCollisionPlanePoint(plane, box.max)                                       do result |= .BOX_BACK_TOP_RIGHT
	if CheckCollisionPlanePoint(plane, {box.min.x, box.max.y, box.min.z})         do result |= .BOX_FRONT_TOP_LEFT
	if CheckCollisionPlanePoint(plane, {box.max.x, box.max.y, box.min.z})         do result |= .BOX_FRONT_TOP_RIGHT
	if CheckCollisionPlanePoint(plane, {box.max.x, box.min.y, box.min.z})         do result |= .BOX_FRONT_BOTTOM_RIGHT
	if CheckCollisionPlanePoint(plane, {box.min.x, box.min.y, box.max.z})         do result |= .BOX_BACK_BOTTOM_LEFT
	if CheckCollisionPlanePoint(plane, {box.min.x, box.max.y, box.max.z})         do result |= .BOX_BACK_TOP_LEFT
	if CheckCollisionPlanePoint(plane, {box.max.x, box.min.y, box.max.z})         do result |= .BOX_BACK_BOTTOM_RIGHT

	return result
}

FrustumContainsSphere :: proc(frustum: Frustum, center: rl_Vector3, radius: f32) -> bool {
	if PlaneDistanceToPoint(frustum.left,  center) <= -radius do return false
	if PlaneDistanceToPoint(frustum.right, center) <= -radius do return false
	if PlaneDistanceToPoint(frustum.up,    center) <= -radius do return false
	if PlaneDistanceToPoint(frustum.down,  center) <= -radius do return false
	if PlaneDistanceToPoint(frustum.near,  center) <= -radius do return false
	if PlaneDistanceToPoint(frustum.far,   center) <= -radius do return false
	return true
}

FrustumContainsPoint :: proc(frustum: Frustum, point: rl_Vector3) -> bool {
	return FrustumContainsSphere(frustum, point, 0.0)
}

FrustumContainsBox :: proc(frustum: Frustum, box: rl_BoundingBox) -> bool {
	if CheckCollisionPlaneBoxEx(frustum.up,    box) == .BOX_ALL_CORNERS do return false
	if CheckCollisionPlaneBoxEx(frustum.down,  box) == .BOX_ALL_CORNERS do return false
	if CheckCollisionPlaneBoxEx(frustum.left,  box) == .BOX_ALL_CORNERS do return false
	if CheckCollisionPlaneBoxEx(frustum.right, box) == .BOX_ALL_CORNERS do return false
	if CheckCollisionPlaneBoxEx(frustum.near,  box) == .BOX_ALL_CORNERS do return false
	if CheckCollisionPlaneBoxEx(frustum.far,   box) == .BOX_ALL_CORNERS do return false
	return true
}

DrawFrustum :: proc(frustum: Frustum, color: rl_Color) {
	corners := [8]rl_Vector3{}

	// We'll define the corners in this order:
	// 0: near bottom left
	// 1: near bottom right
	// 2: near top left
	// 3: near top right
	// 4: far bottom left
	// 5: far bottom right
	// 6: far top left
	// 7: far top right

	planes := [6]rl_Vector4{
		frustum.left, frustum.right,
		frustum.up, frustum.down,
		frustum.near, frustum.far,
	}

	// Helper to get 3-plane intersection
	PlaneIntersection :: proc(p1, p2, p3: rl_Vector4) -> rl_Vector3 {
		a := rl_Vector3{p1.x, p1.y, p1.z}
		b := rl_Vector3{p2.x, p2.y, p2.z}
		c := rl_Vector3{p3.x, p3.y, p3.z}

		cross_bc := linalg.cross(b, c)
		cross_ca := linalg.cross(c, a)
		cross_ab := linalg.cross(a, b)

		denom := linalg.dot(a, cross_bc)

		if math.abs(denom) < 0.00001 {
			return rl_Vector3{0, 0, 0} // fallback
		}

		numerator := cross_bc * -p1.w + cross_ca * -p2.w + cross_ab * -p3.w;

		return numerator / denom
	}

	// Calculate corners
	corners[0] = PlaneIntersection(frustum.near, frustum.down, frustum.left)
	corners[1] = PlaneIntersection(frustum.near, frustum.down, frustum.right)
	corners[2] = PlaneIntersection(frustum.near, frustum.up,   frustum.left)
	corners[3] = PlaneIntersection(frustum.near, frustum.up,   frustum.right)

	corners[4] = PlaneIntersection(frustum.far, frustum.down, frustum.left)
	corners[5] = PlaneIntersection(frustum.far, frustum.down, frustum.right)
	corners[6] = PlaneIntersection(frustum.far, frustum.up,   frustum.left)
	corners[7] = PlaneIntersection(frustum.far, frustum.up,   frustum.right)

	// Draw edges between corners
	edges := [][2]int{
		{0, 1}, {1, 3}, {3, 2}, {2, 0}, // near face
		{4, 5}, {5, 7}, {7, 6}, {6, 4}, // far face
		{0, 4}, {1, 5}, {2, 6}, {3, 7}, // sides
	}

	for edge in edges {
		rl_DrawLine3D(corners[edge[0]], corners[edge[1]], color)
	}
}

camera_view_mat :: proc(camera: Camera) -> rl_Matrix {
	return rl_MatrixLookAt(camera.rl_matrix.position, camera.rl_matrix.target, camera.rl_matrix.up);
}

camera_proj_mat :: proc(camera: Camera, aspect: f32) -> rl_Matrix {
	return rl_MatrixPerspective(camera.rl_matrix.fovy * Deg2Rad, aspect, camera.near, camera.far);
}

// Returns the frustum in world space coordinates
CameraGetFrustum :: proc(camera: Camera, aspect: f32) -> Frustum {
	frustum: Frustum
	view := camera_view_mat(camera);
	proj := camera_proj_mat(camera, aspect);
	clip_rl := proj * view;
	clip := rl_mat_to_mat4(clip_rl);

	// Perspective projection
	frustum.left  = linalg.normalize(rl_Vector4{clip.m3 + clip.m0, clip.m7 + clip.m4,  clip.m11 + clip.m8,  clip.m15 + clip.m12})
	frustum.right = linalg.normalize(rl_Vector4{clip.m3 - clip.m0, clip.m7 - clip.m4,  clip.m11 - clip.m8,  clip.m15 - clip.m12})
	frustum.down  = linalg.normalize(rl_Vector4{clip.m3 + clip.m1, clip.m7 + clip.m5,  clip.m11 + clip.m9,  clip.m15 + clip.m13})
	frustum.up    = linalg.normalize(rl_Vector4{clip.m3 - clip.m1, clip.m7 - clip.m5,  clip.m11 - clip.m9,  clip.m15 - clip.m13})
	frustum.near  = linalg.normalize(rl_Vector4{clip.m3 + clip.m2, clip.m7 + clip.m6,  clip.m11 + clip.m10, clip.m15 + clip.m14})
	frustum.far   = linalg.normalize(rl_Vector4{clip.m3 - clip.m2, clip.m7 - clip.m6,  clip.m11 - clip.m10, clip.m15 - clip.m14})

	return frustum
}
