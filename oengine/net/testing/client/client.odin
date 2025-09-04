package main

import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"
import "core:sync"
import "core:mem"

Player :: struct {
    id: i32,
    x, y: f32,
}

InputEvent :: struct {
    seq: u32,
    key: u8,
}

players: [dynamic]Player;
players_mutex: sync.Mutex;
c_id: i32 = -1;
pending_inputs: [dynamic]InputEvent;
next_seq: u32;
SPEED :: 150.0
TICK_RATE :: 1.0 / 60.0

tcp_client :: proc(ip: string, port: i32) {
    local_address, ok := net.parse_ip4_address(ip);
    if (!ok) {
        fmt.println("Failed to parse IP address");
        return;
    }

    socket, err := net.dial_tcp_from_address_and_port(local_address, int(port));
    if (err != nil) {
        fmt.println("Failed to connect to server");
        return;
    }

    buffer: [256]u8;

    // --- Thread to continuously receive server updates ---
    thread.create_and_start_with_poly_data2(
        socket, &buffer, proc(socket: net.TCP_Socket, buffer: ^[256]u8) {
        for {
            bytes_recv, err_recv := net.recv_tcp(socket, buffer^[:]);
            if (err_recv != nil || bytes_recv == 0) {
                continue;
            }

            recieved := buffer^[:bytes_recv];
            lines := strings.split(string(recieved), "\n");

            sync.mutex_lock(&players_mutex);
            for line in lines {
                if (len(line) == 0) { continue; }

                if (strings.has_prefix(line, "YOU:")) {
                    id_val, ok := strconv.parse_int(strings.trim_prefix(line, "YOU:"));
                    if ok {
                        c_id = i32(id_val);
                        fmt.println("My player id is", c_id);
                    }
                    continue;
                }

                parts := strings.split(line, ":");
                if (len(parts) != 3) { continue; }

                id, ok_id := strconv.parse_int(parts[0]);
                x, ok_x := strconv.parse_f32(parts[1]);
                y, ok_y := strconv.parse_f32(parts[2]);
                last_ack: u32 = 0;
                if (len(parts) > 3) {
                    last_ack64, _ := strconv.parse_int(parts[3]);
                    last_ack = u32(last_ack64);
                }
                if (!ok_id || !ok_x || !ok_y) { continue; }

                found := false;
                for i in 0..<len(players) {
                    if (players[i].id == i32(id)) {
                        if (i32(id) == c_id) {
                            // --- Reconciliation for our player ---
                            players[i].x = x;
                            players[i].y = y;

                            // Remove acked inputs
                            new_pending := make([dynamic]InputEvent);
                            for ev in pending_inputs {
                                if ev.seq > last_ack {
                                    append(&new_pending, ev);
                                }
                            }
                            pending_inputs = new_pending;

                            // Reapply unacknowledged inputs
                            for ev in pending_inputs {
                                if ev.key == 'w' { players[i].y -= SPEED * TICK_RATE; }
                                if ev.key == 's' { players[i].y += SPEED * TICK_RATE; }
                                if ev.key == 'a' { players[i].x -= SPEED * TICK_RATE; }
                                if ev.key == 'd' { players[i].x += SPEED * TICK_RATE; }
                            }
                        } else {
                            // Other players: just accept server position
                            players[i].x = x;
                            players[i].y = y;
                        }
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    append(&players, Player{i32(id), x, y});
                }
            }
            sync.mutex_unlock(&players_mutex);
        }
    })

    rl.InitWindow(800, 600, "client");
    rl.SetTargetFPS(60);

    // --- Main loop: send input and render ---
    for (!rl.WindowShouldClose()) {
        move_input: u8 = 0;
        if (rl.IsKeyDown(.W)) { move_input = 'w'; }
        if (rl.IsKeyDown(.S)) { move_input = 's'; }
        if (rl.IsKeyDown(.A)) { move_input = 'a'; }
        if (rl.IsKeyDown(.D)) { move_input = 'd'; }

        if (move_input != 0 && c_id != -1) {
            // --- Send input with seq number ---
            buffer[0] = move_input;
            seq_bytes := mem.any_to_bytes(next_seq); // [4]u8
            for i in 0..<4 {
                buffer[1+i] = seq_bytes[i];
            }
            _, err_send := net.send_tcp(socket, buffer[:5]);
            if (err_send != nil) {
                fmt.println("Failed to send input");
                break;
            }

            // Store input
            append(&pending_inputs, InputEvent{next_seq, move_input});
            next_seq += 1;

            // --- Predict locally ---
            sync.mutex_lock(&players_mutex);
            for i in 0..<len(players) {
                if (players[i].id == c_id) {
                    if move_input == 'w' { players[i].y -= SPEED * TICK_RATE; }
                    if move_input == 's' { players[i].y += SPEED * TICK_RATE; }
                    if move_input == 'a' { players[i].x -= SPEED * TICK_RATE; }
                    if move_input == 'd' { players[i].x += SPEED * TICK_RATE; }
                }
            }
            sync.mutex_unlock(&players_mutex);
        }

        // --- Render ---
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        sync.mutex_lock(&players_mutex);
        for player in players {
            color := rl.BLUE;
            if (player.id == c_id) {
                color = rl.RED;
            }
            rl.DrawCircle(i32(player.x) + 400, i32(player.y) + 300, 10, color);
        }
        sync.mutex_unlock(&players_mutex);

        rl.EndDrawing();
    }

    rl.CloseWindow();
    net.close(socket);
}

main :: proc() {
    fmt.print("IP: ");
    buffer: [256]u8;
    n, err_read := os.read(os.stdin, buffer[:]);
    if (err_read != nil) {
        fmt.println("Failed to read IP");
        return;
    }
    ip := strings.trim_space(string(buffer[:n]));

    fmt.print("Port: ");
    buffer2: [256]u8;
    n2, err_read2 := os.read(os.stdin, buffer2[:]);
    if (err_read2 != nil) {
        fmt.println("Failed to read port");
        return;
    }
    port_str := strings.trim_space(string(buffer2[:n2]));
    port, ok := strconv.parse_int(port_str);
    if !ok {
        fmt.println("Invalid port");
        return;
    }

    tcp_client(ip, i32(port));
}
