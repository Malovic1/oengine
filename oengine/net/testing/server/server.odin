package main

import "core:fmt"
import "core:net"
import "core:thread"

handle_msg :: proc(socket: net.TCP_Socket) {
    buffer: [256]u8;

    for {
        bytes_recv, err_recv := net.recv_tcp(socket, buffer[:]);
        if (err_recv != nil) {
            fmt.println("Failed to recieve data");
        }

        recieved := buffer[:bytes_recv];

        if (len(recieved) == 0) {
            fmt.println("Disconnecting client");
            return;
        }

        fmt.printfln("Server recieved [ %d bytes ]: %s", len(recieved), recieved);

        bytes_sent, err_send := net.send_tcp(socket, recieved);
        if (err_send != nil) {
            fmt.println("Failed to send data");
        }

        sent := recieved[:bytes_sent];
        fmt.printfln("Server sent [ %d bytes ]: %s", len(sent), sent);
    }

    net.close(socket);
}

tcp_server :: proc(ip: string, port: i32) {
    local_address, ok := net.parse_ip4_address(ip);
    if (!ok) {
        fmt.println("Failed to parse IP address");
        return;
    }

    endpoint := net.Endpoint {
        address = local_address,
        port = int(port),
    };

    socket, err := net.listen_tcp(endpoint);
    if (err != nil) {
        fmt.println("Failed to listen on TCP");
        return;
    }

    fmt.printfln("Listening on TCP: %s", net.endpoint_to_string(endpoint));

    for {
        client, _, err_accept := net.accept_tcp(socket);
        if (err_accept != nil) {
            fmt.println("Failed to accept TCP connection");
        }

        thread.create_and_start_with_poly_data(client, handle_msg);
    }

    net.close(socket);
    fmt.println("Closed socket");
}

main :: proc() {
    tcp_server("127.0.0.1", 8080);
}
