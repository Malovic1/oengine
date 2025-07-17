package main

import "core:fmt"
import "core:bufio"
import "core:os"
import "core:io"
import str "core:strings"
import rl "vendor:raylib"
import oe "../oengine"
import ecs "../oengine/ecs"
import fa "../oengine/fa"
import "core:math"
import "core:math/linalg"
import "core:mem"
import "core:time"
import "core:thread"

main :: proc() {
    def_allocator := context.allocator;
    track_allocator: mem.Tracking_Allocator;
    mem.tracking_allocator_init(&track_allocator, def_allocator);
    context.allocator = mem.tracking_allocator(&track_allocator);

    reset_track_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
        err := false;

        for _, value in a.allocation_map {
            fmt.printf("%v: allocated %v bytes\n", value.location, value.size);
            err = true;
        }

        if (!err) {
            fmt.println("No memory allocated");
        }

        mem.tracking_allocator_clear(a);
        return err;
    }

    oe.OE_DEBUG = true;
    oe.PHYS_DEBUG = true;

    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);
    oe.w_set_trace_log_type(.USE_ALL);
    oe.w_set_trace_log_level(.WARNING);
    oe.window.debug_stats = true;

    start := time.now(); 
    oe.ew_init(oe.vec3_y() * 50);

    oe.loading_screen(
        text = "Loading registry...",
        bg_color = oe.BLACK,
        text_color = oe.WHITE,
        text_pos = {.LEFT, .BOTTOM},
    );
    oe.load_registry("../registry.od");
    fmt.println(time.since(start));

    camera := oe.cm_init(oe.vec3_zero());
    is_mouse_locked: bool = false;
    oe.ecs_world.camera = &camera;

    skybox_tex := oe.get_asset_var("skybox", oe.SkyBox);
    oe.set_skybox_filtering(skybox_tex);
    albedo := oe.get_asset_var("albedo", oe.Texture);
    orm := oe.get_asset_var("orm", oe.Texture);
    troll := oe.get_asset_var("troll", oe.Texture);
    water_tex := oe.get_asset_var("water", oe.Texture);
    jump_sfx := oe.get_asset_var("huh", oe.Sound);
    celsium := oe.get_asset_var("celsium_man", oe.Model);
    swat := oe.get_asset_var("swat", oe.Model);
    lara := oe.get_asset_var("lara", oe.Model);
    heightmap_tex := oe.get_asset_var("heightmap", oe.Texture);

    skybox := oe.gen_skybox(oe.gen_cubemap_texture(skybox_tex));

    floor := oe.aent_init("Floor");
    floor_tr := oe.get_component(floor, oe.Transform);
    floor_tr.scale = {50, 1, 50};
    floor_rb := oe.add_component(floor, oe.rb_init(floor_tr^, 1.0, 0.5, true, oe.ShapeType.BOX));
    floor_sm := oe.add_component(floor, oe.sm_init(orm));
    floor_sm.tiling = {5, 5};

    wall := oe.aent_init();
    wall_tr := oe.get_component(wall, oe.Transform);
    wall_tr.position = {10, 5, 0};
    wall_tr.scale = {1, 10, 10};
    wall_rb := oe.add_component(wall, oe.rb_init(wall_tr^, 1.0, 0.5, true, oe.ShapeType.BOX));
    wall_sm := oe.add_component(wall, oe.sm_init(albedo));

    wall2 := oe.aent_init();
    wall2_tr := oe.get_component(wall2, oe.Transform);
    wall2_tr.position = {-10, 5, 0};
    wall2_tr.scale = {1, 10, 10};
    wall2_rb := oe.add_component(wall2, oe.rb_init(wall2_tr^, 1.0, 0.5, true, oe.ShapeType.BOX));
    wall2_sm := oe.add_component(wall2, oe.sm_init(albedo));

    player := oe.aent_init("player");
    player_tr := oe.get_component(player, oe.Transform);
    player_tr.position = {0, 5, 0};
    player_rb := oe.add_component(
        player, oe.rb_init(
            {player_tr.position - {0, 0.5, 0}, player_tr.rotation, {1, 2, 1}}, 
            1.0, 0.5, false, oe.ShapeType.BOX)
    );
    player_sm := oe.add_component(player, oe.sm_init(oe.tex_flip_vert(troll)));
    player_sm.user_call = true;
    player_jump := oe.add_component(player, oe.sa_init(player_tr.position, jump_sfx));
    player_rb.collision_mask = oe.coll_mask(1);

    light := oe.aent_init("light");
    light_tr := oe.get_component(light, oe.Transform);
    light_tr.position.y = 5;
    light_lc := oe.add_component(light, oe.lc_init());

    water := oe.aent_init("water");
    water_tr := oe.get_component(water, oe.Transform);
    water_tr.position.z = 37.5;
    water_tr.scale = {25, 1, 25};
    water_f := oe.add_component(water, oe.f_init(water_tex));
    water_f.color.a = 125;
    water_f.user_call = true;

    sprite := oe.aent_init("sprite_test");
    sprite_tr := oe.get_component(sprite, oe.Transform);
    sprite_tr.position = {-5, 3, -10};
    sprite_sm := oe.add_component(sprite, oe.sm_init(troll, 0));
    sprite_path := oe.FollowPath {{-5, 3, -10}, {0, 3, -11}, {5, 3, -10}, {5, 3, -15}, {-5, 3, -15}, {-5, 3, -10}};

    ps := oe.aent_init("ParticleSystem");
    ps_tr := oe.get_component(ps, oe.Transform);
    ps_tr.position = {5, 3, -10};
    ps_ps := oe.add_component(ps, oe.ps_init({oe.default_behaviour, oe.gradient_beh}));
    t: oe.Timer;

    s := time.now();
    msc := oe.msc_init();
    // oe.msc_from_json(msc, "../assets/maps/test.json");
    oe.loading_screen(
        text = "Loading msc...",
        bg_color = oe.BLACK,
        text_color = oe.WHITE,
        text_pos = {.LEFT, .BOTTOM},
    );
    oe.load_msc(msc, "../assets/maps/test.od", load_dids = true);
    msc.atlas = oe.load_atlas("../assets/atlas");
    // msc.atlas = oe.am_texture_atlas();
    // oe.pack_atlas(msc.atlas, "../assets/atlas");
    fmt.println(time.since(s));

    msc2 := oe.msc_init();
    oe.msc_from_model(
        msc2, oe.load_model("../assets/maps/bowl.obj"), oe.vec3_z() * -35
    );

    oe.update_msc(msc, msc2);
    oe.msc_gen_mesh(msc);
    oe.remove_msc(msc2);

    light2 := oe.aent_init("light");
    light2_tr := oe.get_component(light2, oe.Transform);
    light2_tr.position = {0, 5, -35};
    light2_lc := oe.add_component(light2, oe.lc_init());

    animated := oe.aent_init("anim", false);
    animated_tr := oe.get_component(animated, oe.Transform);
    animated_tr.position = {-2.5, 4, -10};
    animated_tr.scale *= 3;
    animated_m := oe.model_clone(swat);
    animated_m.transform = rl.MatrixRotateY(-90 * oe.Deg2Rad);
    animated_sm := oe.add_component(animated, oe.sm_init(animated_m));
    animated_ma := oe.ma_load(animated_sm.tex.(oe.Model).path);

    lara_ent := oe.aent_init("lara", false);
    lara_tr := oe.get_component(lara_ent, oe.Transform);
    lara_tr.position = {2.5, 4, -10};
    lara_tr.scale *= 3;
    lara_sm := oe.add_component(lara_ent, oe.sm_init(oe.model_clone(swat)));
    lara_ma := oe.ma_load(lara_sm.tex.(oe.Model).path);
    lara_sm.offset.scale = {1.5, 0.75, 1.5};

    test_tri := [3]oe.Vec3{{-15, 10, -10}, {-12.5, 7.5, -7.5}, {-10, 12.5, -12.5}};
    test_aabb := oe.compute_aabb(test_tri[0], test_tri[1], test_tri[2]);
    test_subdivided := oe.split_aabb_8(test_aabb);

    flashlight := oe.aent_init("flashlight");
    flashlight_tr := oe.get_component(flashlight, oe.Transform);
    flashlight_lc := oe.add_component(flashlight, oe.lc_init(.Spot, oe.GREEN));
    oe.ray_light_cutoffs(oe.ecs_world.ray_ctx.shader, flashlight_lc.data, 12.5, 17.5);

    s_triangles := make([dynamic][3]oe.Vec3);
    oe.subdivide_triangle(test_tri.x, test_tri.y, test_tri.z, 2, &s_triangles);

    img := oe.load_image(rl.LoadImageFromTexture(heightmap_tex));
    heightmap := oe.load_model(rl.LoadModelFromMesh(rl.GenMeshHeightmap(img.data, {1, 1, 1})));
    heightmap.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = heightmap_tex;
    heightmap.materials[0].shader = oe.world().ray_ctx.shader;

    terrain := oe.aent_init("terrain");
    terrain_tr := oe.get_component(terrain, oe.Transform);
    terrain_tr.position = {-33, 0, 0};
    terrain_tr.scale = {16, 8, 16};
    terrain_rb := oe.add_component(terrain, oe.rb_init(terrain_tr^, 1.0, 0.5, oe.load_heights(img)));
    rl.UnloadImage(img.data);


    // reset_track_allocator(&track_allocator);
    for (oe.w_tick()) {
        oe.ew_update();

        // update
        mem.tracking_allocator_clear(&track_allocator);

        if (oe.key_pressed(oe.Key.ESCAPE)) {
            is_mouse_locked = !is_mouse_locked;
        }

        oe.cm_set_fps(&camera, 0.1, is_mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, is_mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);
        oe.cm_update(&camera);

        flashlight_tr.position = camera.position;
        flashlight_lc.data.target = camera.target;

        if (oe.key_pressed(oe.Key.RIGHT_SHIFT)) {
            player_rb.velocity.y = 15;

            oe.detach_sound_filter(.LOWPASS);
            oe.sa_play(player_jump);
            oe.attach_sound_filter(.LOWPASS);
        }

        if (oe.key_down(oe.Key.LEFT)) {
            player_rb.velocity.x = -7.5;
        } else if (oe.key_down(oe.Key.RIGHT)) {
            player_rb.velocity.x = 7.5;
        } else if (oe.key_down(oe.Key.UP)) {
            player_rb.velocity.z = -7.5;
        } else if (oe.key_down(oe.Key.DOWN)) {
            player_rb.velocity.z = 7.5;
        } else {
            player_rb.velocity.xz = {};
        }

        if (oe.key_pressed(.F5)) {
            oe.ew_remove_ent(player.id);
        }

        if (oe.key_down(oe.Key.F2)) {
            ent := oe.aent_init();
            ent_tr := oe.get_component(ent, oe.Transform);
            ent_tr.position = camera.position;
            ent_rb := oe.add_component(ent, oe.rb_init(ent_tr^, 1.0, 0.5, false, oe.ShapeType.BOX));
            ent_rb.collision_mask = oe.coll_mask(..oe.range_slice(2, oe.COLLISION_MASK_SIZE));
        }

        if (oe.key_pressed(.F3)) do oe.lc_toggle(light_lc);

        prtcl := oe.particle_init(
            oe.circle_spawn(1, true), 
            slf = 10,
            color = oe.RED,
        );
        prtcl.data.color1 = oe.RED;
        prtcl.data.color2 = oe.BLANK;
        speed: f32 = 100;
        prtcl.data.data = &speed;
        oe.ps_add_particle(ps_ps, prtcl, 0.1);

        oe.sm_apply_anim(animated_sm, &animated_ma, 0);

        lara_tr.rotation.y = -oe.look_at_vec2(lara_tr.position.xz, camera.position.xz) - 90;

        SPEED :: 10
        @static timer: f32 = oe.F32_MAX;
        if (oe.play_sequence(sprite_path, &timer, SPEED, oe.delta_time())) {
            animated_tr.position, animated_tr.rotation = oe.position_sequence(
                sprite_path, SPEED, timer
            );
        } else {
            if (oe.key_pressed(.ENTER)) {
                timer = 0;
                sprite_tr.position = {-5, 3, -10};
            }
        }

        // render
        oe.w_begin_render();
        rl.ClearBackground(rl.SKYBLUE);

        rl.BeginMode3D(camera.rl_matrix);
        oe.draw_skybox_mesh(skybox);
        oe.ew_render();

        coll, info := oe.rc_is_colliding_msc(camera.raycast, msc, true);
        if (coll) {
            rl.DrawLine3D(info.point, info.point + info.normal, oe.RED);

            rl.DrawSphere(info.point, 0.25, oe.RED);
            oe.draw_sprite(info.point, oe.vec2_one(), oe.look_at(info.point, info.point + info.normal), troll, oe.WHITE);
            if (oe.mouse_pressed(.LEFT)) {
                oe.new_decal(info.point, info.normal, oe.vec2_one(), "troll");
            }
        }

        oe.sm_custom_render(player_tr, player_sm);
        oe.f_custom_render(water_tr, water_f);

        rl.DrawTriangle3D(
            test_tri[0],
            test_tri[1],
            test_tri[2],
            oe.WHITE,
        );
        oe.draw_aabb_wires(test_aabb, oe.GREEN);
        for i in 0..<len(test_subdivided) {
            aabb := test_subdivided[i];
            oe.draw_aabb_wires(aabb, oe.ORANGE);
        }

        for i in 0..<len(s_triangles) {
            tri := s_triangles[i];
            rl.DrawTriangle3D(tri.x, tri.y, tri.z, {0, u8(i) * 50, 100, 255});
        }

        h_tr := terrain_tr^;
        h_tr.position = terrain_tr.position - terrain_tr.scale * 0.5;
        oe.draw_model(heightmap, h_tr, oe.WHITE);

        rl.EndMode3D();

        oe.w_end_render();
        if (oe.key_pressed(.F4)) do reset_track_allocator(&track_allocator);
    }

    // reset_track_allocator(&track_allocator);
    oe.w_close();
}
