package oengine

import "core:math"
import "core:fmt"
import rl "vendor:raylib"
import ecs "ecs"
import "fa"
import "core:encoding/json"
import od "object_data"

MASS_SCALAR :: 100
MAX_VEL :: 50

HeightMap :: [][]f32
HeightMapHandle :: struct {
    hmap: HeightMap,
    size: Vec3, 
}

Slope :: [2][2]f32

/*
Slope example

slope_def := oe.Slope {
    {0, 1},
    {0, 1},
};
slope := oe.ent_init();
oe.ent_add_component(slope, oe.rb_init(slope.starting, 1.0, 0.5, slope_def));
oe.ent_add_component(slope, oe.sm_init(
    oe.ent_get_component_var(slope, ^oe.RigidBody).shape_variant.(oe.Slope)));
oe.sm_set_texture(oe.ent_get_component_var(slope, ^oe.SimpleMesh), albedo);
oe.ent_set_pos(slope, {-2, 3, -10})
oe.ent_set_scale(slope, {5, 5, 5});

*/

RigidBody :: struct {
    id: u32,
    transform: Transform,
    starting: Transform,
    _difference: Transform,
    grounded: bool,
    _down: Raycast,

    acceleration, velocity, force: Vec3,
    mass, restitution, friction: f32,

    shape: ShapeType,

    shape_variant: union {
        u8,         // primitive
        HeightMapHandle,
        Slope,
    },

    is_static: bool,

    joints: fa.FixedArray(u32, MAX_JOINTS),

    collision_mask: [COLLISION_MASK_SIZE]i32,
}

rb_init :: proc {
    rb_init_def,
    rb_init_terrain,
    rb_init_slope,
}

@(private = "file")
rb_init_all :: proc(using rb: ^RigidBody, s_density, s_restitution: f32, s_static: bool, s_shape: ShapeType) {
    transform = {
        vec3_zero(),
        vec3_zero(),
        vec3_one(),
    };

    starting = transform;

    acceleration = {};
    velocity = {};
    force = {};

    vol: f32;
    #partial switch s_shape {
        case .BOX, .HEIGHTMAP:
            vol = transform.scale.x * transform.scale.y * transform.scale.z;
        case .SPHERE:
            vol = (4.0 / 3.0) * math.pow(transform.scale.x * 0.5, 3) * math.PI;
        case .CAPSULE:
            vol = (4.0 / 3.0 * transform.scale.x * 0.5 + transform.scale.y) * math.pow(transform.scale.x * 0.5, 3) * math.PI
        case .SLOPE:
            vol = (transform.scale.x * transform.scale.y * transform.scale.z) * 0.5;
    }

    mass = vol * s_density / MASS_SCALAR;
    restitution = s_restitution;
    shape = s_shape;

    is_static = s_static;
    friction = 0.7;

    shape_variant = 0;

    id = u32(ecs_world.physics.bodies.len);
    joints = fa.fixed_array(u32, MAX_JOINTS);

    for i in 1..<COLLISION_MASK_SIZE+1 {
        collision_mask[i - 1] = i32(i);
    }
}

rb_init_def :: proc(s_starting: Transform, s_density, s_restitution: f32, s_static: bool, s_shape: ShapeType) -> RigidBody {
    using rb: RigidBody;

    rb_init_all(&rb, s_density, s_restitution, s_static, s_shape);
    rb_starting_transform(&rb, s_starting);

    return rb;
}

rb_init_terrain :: proc(
    s_starting: Transform, 
    s_density, s_restitution: f32, 
    s_heightmap: HeightMap) -> RigidBody {
    using rb: RigidBody;

    rb_init_all(&rb, s_density, s_restitution, true, ShapeType.HEIGHTMAP);
    rb.shape_variant = HeightMapHandle{
        hmap = s_heightmap,
        size = {
            s_starting.scale.x / f32(len(s_heightmap[0])), 
            s_starting.scale.y,
            s_starting.scale.z / f32(len(s_heightmap)),
        }
    };
    rb_starting_transform(&rb, s_starting);

    return rb;
}

rb_init_slope :: proc(s_starting: Transform, s_density, s_restitution: f32, s_slope: Slope, reverse: bool = false) -> RigidBody {
    using rb: RigidBody;

    rb_init_all(&rb, s_density, s_restitution, true, ShapeType.SLOPE);
    rb.shape_variant = s_slope;
    rb_starting_transform(&rb, s_starting);

    if (reverse) {
        append(&ecs_world.physics.reverse_slopes, rb.id);
    }

    return rb;
}

load_heights :: proc(img: Image) -> HeightMap {
    res := make(HeightMap, img.data.height);
    for i in 0..<len(res) {
        res[i] = make([]f32, img.data.width);
    }

    colors_len := img.data.width * img.data.height;
    colors := rl.LoadImageColors(img.data);

    for i in 0..<colors_len {
        row := i / img.data.width;
        col := i % img.data.width;

        c := colors[i];
        // Convert RGB to grayscale float between 0 and 1
        gray := (f32(c.r) + f32(c.g) + f32(c.b)) / (3 * 255.0);

        res[row][col] = gray;
    }

    return res;
}

rb_starting_transform :: proc(using self: ^RigidBody, trans: Transform) {
    transform = trans;
    starting = transform;
}

@(private = "package")
rb_fixed_update :: proc(using self: ^RigidBody, dt: f32) {
    if (is_static) do return;

    _down = {
        position = transform.position,
        target = transform.position - {0, transform.scale.y * 0.5 + 0.5, 0},
    }
    
    if (!grounded) {
        acceleration.y = -ecs_world.physics.gravity.y;
    } else {
        acceleration.y = 0;
    }

    grounded = false;

    velocity.x = math.clamp(velocity.x, -MAX_VEL, MAX_VEL);
    velocity.y = math.clamp(velocity.y, -MAX_VEL, MAX_VEL);
    velocity.z = math.clamp(velocity.z, -MAX_VEL, MAX_VEL);

    velocity += acceleration * dt * DAMPING_VEL_FACTOR;
    transform.position += velocity * dt;
    force = acceleration * mass;
}

rb_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, rb := ecs.get_components(ent, Transform, RigidBody);
    if (is_nil(t, rb)) do return;

    t^ = transform_add(rb.transform, rb._difference);
}

rb_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    rb := ecs.get_component(ent, RigidBody);
    if (is_nil(rb)) do return;
    using rb;

    if (!PHYS_DEBUG) do return;

    if (shape == .BOX) {
        draw_cube_wireframe(transform.position, transform.rotation, transform.scale, PHYS_DEBUG_COLOR);
    } else if (shape == .SPHERE) {
        draw_sphere_wireframe(transform.position, transform.rotation, transform.scale.x * 0.5, PHYS_DEBUG_COLOR);
    } else if (shape == .CAPSULE) {
        draw_capsule_wireframe(transform.position, transform.rotation, transform.scale.x * 0.5, transform.scale.y * 0.5, PHYS_DEBUG_COLOR);
    } else if (shape == .SLOPE) {
        draw_slope_wireframe(shape_variant.(Slope), transform.position, transform.rotation, transform.scale, PHYS_DEBUG_COLOR);
    } else if (shape == .HEIGHTMAP) {
        // draw_heightmap_wireframe(shape_variant.(HeightMapHandle), transform.position, transform.rotation, transform.scale, PHYS_DEBUG_COLOR);
    }
}

rb_clear :: proc(using self: ^RigidBody) {
    acceleration = {};
    velocity = {};
    force = {};
}

rb_inverse_mass :: proc(using self: RigidBody) -> f32 {
    return 1 / mass;
}

rb_apply_impulse :: proc(using self: ^RigidBody, s_impulse: Vec3) {
    if (is_static) do return;

    delta := s_impulse * rb_inverse_mass(self^);
    velocity += delta * ecs_world.physics.delta_time;
}

rb_apply_force :: proc(using self: ^RigidBody, s_force: Vec3) {
    if (is_static) do return;

    add := s_force * rb_inverse_mass(self^);
    acceleration += add * ecs_world.physics.delta_time;
}

rb_shape :: proc(using self: ^RigidBody, $T: typeid) -> T {
    return shape_variant.(T);
}

rb_get_height_terrain_at :: proc(using self: ^RigidBody, x, z: f32) -> f32 {
    handle := shape_variant.(HeightMapHandle);
    
    half_width := (f32(len(handle.hmap[0])) - 1) * handle.size.x / 2.0;
    half_depth := (f32(len(handle.hmap)) - 1) * handle.size.z / 2.0;

    terrain_x := x - (transform.position.x - half_width);
    terrain_z := z - (transform.position.z - half_depth);

    grid_x := i32(math.floor(terrain_x / handle.size.x));
    grid_z := i32(math.floor(terrain_z / handle.size.z));

    if (grid_x >= i32(len(handle.hmap[0])) - 1 ||
        grid_z >= i32(len(handle.hmap)) - 1 ||
        grid_x < 0 || grid_z < 0) {
        return transform.position.y;
    }

    x_coord := (math.mod(terrain_x, handle.size.x)) / handle.size.x;
    z_coord := (math.mod(terrain_z, handle.size.z)) / handle.size.z;

    local_height: f32;
    if (x_coord <= (1 - z_coord)) {
        local_height = barry_centric(
            {0, handle.hmap[grid_z][grid_x], 0},
            {1, handle.hmap[grid_z][grid_x + 1], 0},
            {0, handle.hmap[grid_z + 1][grid_x], 1},
            {x_coord, z_coord},
        );
    } else {
        local_height = barry_centric(
            {1, handle.hmap[grid_z][grid_x + 1], 0},
            {1, handle.hmap[grid_z + 1][grid_x + 1], 1},
            {0, handle.hmap[grid_z + 1][grid_x], 1},
            {x_coord, z_coord},
        );
    }

    return transform.position.y + 
    local_height * handle.size.y - transform.scale.y * 0.5;
}

rb_slope_get_height_at :: proc(slope: Slope, s_x: f32) -> f32{
    x1 := slope[0][0];
    y1 := slope[0][1];

    x2 := slope[1][0];
    y2 := slope[1][1];

    x := -s_x;

    if (x1 == x2 && x1 > y1 && x2 > y2) {
        x1 = slope[1][0];
        y1 = slope[0][0];

        x2 = slope[1][1];
    }

    if (x1 == x2 && x1 < y1 && x2 < y2) {
        y1 = slope[1][0];

        x2 = slope[1][1];
        y2 = slope[0][1];
    }

    if (x1 == y1 && x1 > x2 && y1 > y2) {
        x = s_x;
    }

    t := (x - x1) / (x2 - x1);
    h := y1 + t * (y2 - y1);
    return h;
}

rb_slope_max :: proc(slope: Slope) -> f32 {
    maxi := slope[0][0];

    if (slope[0][1] > maxi) {
        maxi = slope[0][1];
    } else if (slope[1][0] > maxi) {
        maxi = slope[1][0];
    } else if (slope[1][1] > maxi) {
        maxi = slope[1][1];
    }

    return maxi;
}

SlopeOrientation :: enum {
    X,
    Z
}

slope_orientation :: proc(slope: Slope) -> SlopeOrientation {
    return SlopeOrientation(slope[0][0] == slope[1][0]);
}

slope_negative :: proc(slope: Slope) -> bool {
    return (slope[0][0] == slope[1][0] &&
            slope[0][0] > slope[0][1]) ||
            (slope[0][0] == slope[0][1] &&
            slope[0][0] > slope[1][0]);
}

rb_slope_orientation :: proc(using self: ^RigidBody) -> SlopeOrientation {
    return SlopeOrientation(shape_variant.(Slope)[0][0] == shape_variant.(Slope)[1][0]);
}

rb_slope_negative :: proc(using self: ^RigidBody) -> bool {
    return (shape_variant.(Slope)[0][0] == shape_variant.(Slope)[1][0] &&
            shape_variant.(Slope)[0][0] > shape_variant.(Slope)[0][1]) ||
            (shape_variant.(Slope)[0][0] == shape_variant.(Slope)[0][1] &&
            shape_variant.(Slope)[0][0] > shape_variant.(Slope)[1][0]);
}

rb_parse :: proc(asset: od.Object) -> rawptr {
    pos_h := od_vec3(asset["position"].(od.Object));
    rot_h := od_vec3(asset["rotation"].(od.Object));
    sc_h := od_vec3(asset["scale"].(od.Object));

    t := Transform {
        position = pos_h,
        rotation = rot_h,
        scale = sc_h,
    };

    density := asset["density"].(f32);
    restitution := asset["restitution"].(f32);
    shape := ShapeType(od.target_type(asset["shape"], i32));
    is_static := asset["is_static"].(bool);

    rb := rb_init(t, density, restitution, is_static, shape);
    return new_clone(rb);
}

rb_loader :: proc(ent: AEntity, tag: string) {
    ent_tr := get_component(ent, Transform);

    comp := get_component_data(tag, RigidBody);
    comp.id = u32(ecs_world.physics.bodies.len);
    comp.starting = transform_add(comp.starting, ent_tr^);
    comp.transform = comp.starting;
    add_component(ent, comp^);
}
