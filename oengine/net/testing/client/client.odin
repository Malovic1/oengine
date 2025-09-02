package main

import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"
import "core:sync"

Player :: struct {
    id: i32,
    x, y: f32,
}

players: [dynamic]Player;
players_mutex: sync.Mutex;

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

                parts := strings.split(line, ":");
                if (len(parts) != 3) { continue; }

                id, ok_id := strconv.parse_int(parts[0]);
                x, ok_x := strconv.parse_f32(parts[1]);
                y, ok_y := strconv.parse_f32(parts[2]);
                if (!ok_id || !ok_x || !ok_y) { continue; }

                found := false;
                for i in 0..<len(players) {
                    if (players[i].id == i32(id)) {
                        players[i].x = x;
                        players[i].y = y;
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

        if (move_input != 0) {
            buffer[0] = move_input;
            _, err_send := net.send_tcp(socket, buffer[:1]);
            if (err_send != nil) {
                fmt.println("Failed to send input");
                break;
            }
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        sync.mutex_lock(&players_mutex);
        for player in players {
            rl.DrawCircle(i32(player.x) + 400, i32(player.y) + 300, 10, rl.BLUE);
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
