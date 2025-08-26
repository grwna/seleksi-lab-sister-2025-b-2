#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

void write_str(int fd, const char* str) {
    write(fd, str, strlen(str));
}

void handle_plugin_request(int client_fd, char* method, char* path) {
    // Route based on the path
    if (strcmp(path, "/plugin/random") == 0) {
        write_str(client_fd, "HTTP/1.1 200 OK\r\n");
        write_str(client_fd, "Content-Type: text/plain\r\n\r\n");

        char buffer[16];
        srand(time(NULL));
        int random_num = (rand() % 100) + 1;
        snprintf(buffer, sizeof(buffer), "%d", random_num);
        write_str(client_fd, buffer);

    } else if (strcmp(path, "/plugin/hello") == 0) {
        // Handle /plugin/hello
        write_str(client_fd, "HTTP/1.1 200 OK\r\n");
        write_str(client_fd, "Content-Type: text/plain\r\n\r\n");
        write_str(client_fd, "Hello from the C plugin!");

    } else {
        // Handle unknown plugin routes
        write_str(client_fd, "HTTP/1.1 404 Not Found\r\n");
        write_str(client_fd, "Content-Type: text/plain\r\n\r\n");
        write_str(client_fd, "Plugin endpoint not found.");
    }
}