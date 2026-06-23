package oengine

import "core:fmt"

import "fa"

/* 
EXAMPLE

car := oe.aent_init("car");
car_tr := oe.get_component(car, oe.Transform);
car_tr^ = {
    position = {15, 5, 0},
    rotation = {},
    scale = {2, 0.5, 2},
};
car_rb := oe.add_component(car, oe.rb_init(car_tr^, 1.0, 0.5, false, oe.ShapeType.BOX));

for i in 0..<4 {
    wheel := oe.aent_init("wheel");
    wheel_tr := oe.get_component(wheel, oe.Transform);

    if (i == 0) do wheel_tr.position = {car_tr.position.x - 1.5, car_tr.position.y, car_tr.position.z + 1.5};
    if (i == 1) do wheel_tr.position = {car_tr.position.x + 1.5, car_tr.position.y, car_tr.position.z + 1.5};
    if (i == 2) do wheel_tr.position = {car_tr.position.x - 1.5, car_tr.position.y, car_tr.position.z - 1.5};
    if (i == 3) do wheel_tr.position = {car_tr.position.x + 1.5, car_tr.position.y, car_tr.position.z - 1.5};

    wheel_rb := oe.add_component(wheel, oe.rb_init(wheel_tr^, 1.0, 0.5, false, oe.ShapeType.BOX));

    wheel_joint := oe.fj_init(
        car_rb,
        wheel_rb,
        wheel_tr.position,
    );
}

*/

@(private)
add_car :: proc(pos: Vec3) {
    car := aent_init("car");
    car_tr := get_component(car, Transform);
    car_tr^ = {
        position = pos,
        rotation = {},
        scale = {2, 0.5, 2},
    };
    car_rb := add_component(car, rb_init(car_tr^, 1.0, 0.5, false, ShapeType.BOX));

    for i in 0..<4 {
        wheel := aent_init("wheel");
        wheel_tr := get_component(wheel, Transform);

        if (i == 0) do wheel_tr.position = {car_tr.position.x - 1.5, car_tr.position.y, car_tr.position.z + 1.5};
        if (i == 1) do wheel_tr.position = {car_tr.position.x + 1.5, car_tr.position.y, car_tr.position.z + 1.5};
        if (i == 2) do wheel_tr.position = {car_tr.position.x - 1.5, car_tr.position.y, car_tr.position.z - 1.5};
        if (i == 3) do wheel_tr.position = {car_tr.position.x + 1.5, car_tr.position.y, car_tr.position.z - 1.5};

        wheel_rb := add_component(wheel, rb_init(wheel_tr^, 1.0, 0.5, false, ShapeType.BOX));

        wheel_joint := fj_init(
            car_rb,
            wheel_rb,
            wheel_tr.position,
        );
    }
}

FixedJoint :: struct {
    parent, child: ^RigidBody,
    parent_starting: Transform,
    starting_pos: Vec3,
}

fj_init :: proc(s_parent, s_child: ^RigidBody, starting_p: Vec3) -> ^Joint {
    res := new(Joint);
    res.id = u32(ecs_world.physics.joints.len);
    res.variant = new(FixedJoint);

    using fj := res.variant.(^FixedJoint);
    parent = s_parent;
    child = s_child;

    parent_starting = parent.transform;
    starting_pos = starting_p;

    res.update = fj_update;

    fa.append(&parent.joints, res.id);
    fa.append(&child.joints, res.id);

    fa.append(&ecs_world.physics.joints, res);
    return res;
}

fj_update :: proc(joint: ^Joint) {
    using self := joint.variant.(^FixedJoint);

    pDeltaPos := parent.transform.position - parent_starting.position;
    child.transform.position = starting_pos + pDeltaPos;

    pDeltaRot := parent.transform.rotation - parent_starting.rotation;
    child.transform.rotation = child.starting.rotation + pDeltaRot;
}
