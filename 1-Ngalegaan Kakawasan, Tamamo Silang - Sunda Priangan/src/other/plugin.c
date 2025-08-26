#include "plugin_helper.h"
#include <dirent.h>

void handle_plugin_request(int client_fd, char* method, char* path) {
    const char* body_ptr = NULL;
    long body_len = 0;
    char* file_body_buffer = NULL;
    char random_buffer [16];
    char hello_buffer[256];

    if (strcmp(path, "/plugin/") == 0) {
        FILE* f = fopen("public/plugin/help.txt", "rb");
        if (f) {
            fseek(f, 0, SEEK_END);
            body_len = ftell(f);
            fseek(f, 0, SEEK_SET);

            file_body_buffer = malloc(body_len + 1);
            if (file_body_buffer) {
                fread(file_body_buffer, 1, body_len, f);
                file_body_buffer[body_len] = 0;
                body_ptr = file_body_buffer;
            }
            fclose(f);
        }
    } else if (strcmp(path, "/plugin/random") == 0) {
        srand(time(NULL));
        int random_num = (rand() % 10000) + 1;
        body_len = c_itoa(random_num, random_buffer);
        body_ptr = random_buffer;
    } else if (strncmp(path, "/plugin/hello", 13) == 0) {
        printf("HAHAHAHAHA\n");
        const char* name = "Guest";
        char name_buffer[64];
        const char* query = strchr(path, '?');
        if (query) {
            printf("HAHAHAHAHA\n");
            const char* name_val = get_query_param(query + 1, "name");
            if (name_val) {
                const char* end = strchr(name_val, '&');
                size_t len = end ? (size_t)(end - name_val) : strlen(name_val);
                if (len < 63) { // Sisakan ruang untuk null terminator
                    printf("HAHAHAHAHA\n");
                    strncpy(name_buffer, name_val, len);
                    name_buffer[len] = '\0';
                    name = name_buffer;
                }
            }
        }
        
        printf("HAHAHAHAHA\n");
        strcpy(hello_buffer, "Hello ");
        strcat(hello_buffer, name);
        strcat(hello_buffer, ", welcome to the server!");
        printf("%s\n", hello_buffer);
        body_len = strlen(hello_buffer);
        body_ptr = hello_buffer;
    }

    if (body_ptr) {
        char cl_buffer[16];
        int cl_len = c_itoa(body_len, cl_buffer);
        
        write_str(client_fd, "HTTP/1.1 200 OK\r\n");
        write_str(client_fd, "Content-Type: text/plain\r\n");
        write_str(client_fd, "Content-Length: ");
        write(client_fd, cl_buffer, cl_len);
        write_str(client_fd, "\r\n\r\n");
        write(client_fd, body_ptr, body_len);
    } else {
        const char* body = "Not Found";
        write_str(client_fd, "HTTP/1.1 404 Not Found\r\n");
        write_str(client_fd, "Content-Type: text/plain\r\n");
        write_str(client_fd, "Content-Length: 9\r\n\r\n");
        write_str(client_fd, body);
    }

    if (file_body_buffer) {
        free(file_body_buffer);
    }
}
