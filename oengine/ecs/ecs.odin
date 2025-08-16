package ecs

import "core:fmt"
import rl "vendor:raylib"
import "../fa"

MAX_ENTS :: 2048
MAX_SYS :: 64

Context :: struct {
    entities: fa.FixedArray(^Entity, MAX_ENTS),
    removed_ents: [dynamic]i32,
    last_id: u32,
    _update_systems: fa.FixedArray(SystemFunc, MAX_SYS),
    _render_systems: fa.FixedArray(SystemFunc, MAX_SYS),
    _fixed_update_systems: fa.FixedArray(SystemFunc, MAX_SYS),
}

ecs_init :: proc() -> Context {
    return Context {
        entities = fa.fixed_array(^Entity, MAX_ENTS),
        removed_ents = make([dynamic]i32),
        _update_systems = fa.fixed_array(SystemFunc, MAX_SYS),
        _render_systems = fa.fixed_array(SystemFunc, MAX_SYS),
        _fixed_update_systems = fa.fixed_array(SystemFunc, MAX_SYS),
    };
}

register_system :: proc(ctx: ^Context, sys: SystemFunc, #any_int type: i32) {
    if (type == ECS_UPDATE) { 
        fa.append(&ctx._update_systems, sys); 
        return;
    } else if (type == ECS_RENDER) {
        fa.append(&ctx._render_systems, sys);
    } else if (type == ECS_FIXED) {
        fa.append(&ctx._fixed_update_systems, sys);
    }
}

ecs_update :: proc(ctx: ^Context) {
    using ctx;
    for i in 0..<fa.range(entities) {
        entity := entities.data[i];
        for j in 0..<fa.range(_update_systems) {
            system := _update_systems.data[j];
            system(ctx, entity);
        }
    }

    for id in removed_ents {
        fa.remove(&entities, id);
    }
    clear(&removed_ents);
}

ecs_render :: proc(ctx: ^Context) {
    using ctx;
    for i in 0..<fa.range(entities) {
        entity := entities.data[i];
        for j in 0..<fa.range(_render_systems) {
            system := _render_systems.data[j];

            system(ctx, entity);
        }
    }
}

ecs_fixed_update :: proc(ctx: ^Context) {
    using ctx;
    for i in 0..<fa.range(entities) {
        entity := entities.data[i];
        for j in 0..<fa.range(_fixed_update_systems) {
            system := _fixed_update_systems.data[j];
            system(ctx, entity);
        }
    }
}

ecs_remove :: proc(ctx: ^Context, ent: ^Entity) {
    if (ent.removing) { return; }

    ent.removing = true;
    append(&ctx.removed_ents, i32(ent.id));
}
