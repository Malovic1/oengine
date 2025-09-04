package main

import "core:fmt"
import "core:net"
import "core:thread"
import "core:sync"
import "core:os"
import "core:strings"
import "core:strconv"

MAX_CLIENTS :: 8
TICK_RATE :: 60.0

SocketID :: struct {
    socket: net.TCP_Socket,
    id: i32,
}

Client :: struct {
    socket: net.TCP_Socket,
    id: i32,
    x, y: f32,
    input: u8,
}

clients: [dynamic]Client;
clients_mutex: sync.Mutex;

add_client :: proc(socket: net.TCP_Socket) {
    sync.mutex_lock(&clients_mutex);

    if (len(clients) >= MAX_CLIENTS) {
        fmt.println("Server full");
        return;
    }

    id := i32(len(clients));
    append(&clients, Client{socket, id, 0.0, 0.0, 0});
    fmt.println("Client connected: ", id);

    data := fmt.aprintf("YOU:%d\n", id);
    net.send_tcp(socket, transmute([]u8)data);

    for j in 0..<len(clients) {
        other := clients[j]
        data := fmt.aprintf("%d:%0.1f:%0.1f\n", other.id, other.x, other.y)
        net.send_tcp(socket, transmute([]u8)data)
    }

    thread.create_and_start_with_poly_data(id, handle_client_input);

    sync.mutex_unlock(&clients_mutex);
}

handle_client_input :: proc(client_id: i32) {
    buffer: [1]u8;

    for {
        bytes_recv, err := net.recv_tcp(clients[client_id].socket, buffer[:]);
        if (err != nil || bytes_recv == 0) {
            continue;
        }

        sync.mutex_lock(&clients_mutex);
        clients[client_id].input = buffer[0];
        sync.mutex_unlock(&clients_mutex);
    }
}


update_game :: proc(dt: f32) {
    sync.mutex_lock(&clients_mutex);

    for i in 0..<len(clients) {
        client := &clients[i];

        SPEED :: 150.0
        switch client.input {
        case 'd': client.x += dt * SPEED;
        case 'a': client.x -= dt * SPEED;
        case 's': client.y += dt * SPEED;
        case 'w': client.y -= dt * SPEED;
        }

        client.input = 0;
    }

    sync.mutex_unlock(&clients_mutex);
}

broadcast_state :: proc() {
    sync.mutex_lock(&clients_mutex);

    for i in 0..<len(clients) {
        client := clients[i];

        for j in 0..<len(clients) {
            other := clients[j];
            data := fmt.aprintf("%d:%0.1f:%0.1f\n", other.id, other.x, other.y);
            net.send_tcp(client.socket, transmute([]u8)data);
        }
    }
    sync.mutex_unlock(&clients_mutex);
}

game_loop :: proc() {
    dt: f32 = 1.0 / TICK_RATE;

    for {
        update_game(dt);
        broadcast_state();
        thread.yield();
    }
}

tcp_server :: proc(ip: string, port: i32) {
    local_address, ok := net.parse_ip4_address(ip);
    if (!ok) {
        fmt.println("Failed to parse IP address", ip);
        return;
    }

    endpoint := net.Endpoint { address = local_address, port = int(port) };
    socket, err := net.listen_tcp(endpoint);
    if (err != nil) {
        fmt.println("Failed to listen on TCP");
        return;
    }

    fmt.printfln("Listening on TCP: %s", net.endpoint_to_string(endpoint));

    // Accept clients in a separate thread
    thread.create_and_start_with_poly_data(socket, proc(socket: net.TCP_Socket) {
        for {
            client_socket, _, err_accept := net.accept_tcp(socket);
            if (err_accept != nil) {
                fmt.println("Failed to accept TCP connection");
                continue;
            }
            add_client(client_socket);
        }
    })

    game_loop();

    net.close(socket);
    fmt.println("Server closed");
}

main :: proc() {
    fmt.print("IP: ");
    buffer: [256]u8;
    n, err_read := os.read(os.stdin, buffer[:]);
    if (err_read != nil) {
        fmt.println("Failed to read data");
        return;
    }

    ip := strings.trim_space(string(buffer[:n]));

    fmt.print("Port: ");
    buffer2: [256]u8;
    n2, err_read2 := os.read(os.stdin, buffer2[:]);
    if (err_read2 != nil) {
        fmt.println("Failed to read data");
        return;
    }

    port_str := strings.trim_space(string(buffer2[:n2]));
    port, ok := strconv.parse_int(port_str);
    tcp_server(ip, i32(port));
}
