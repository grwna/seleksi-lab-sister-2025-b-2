#include "plugin_helper.h"

const char* get_query_param(const char* query_string, const char* key) {
    if (!query_string || !key) return NULL;
    const char* p = query_string;
    size_t key_len = strlen(key);
    while (*p) {
        if (strncmp(p, key, key_len) == 0 && p[key_len] == '=') {
            return p + key_len + 1;
        }
        p = strchr(p, '&');
        if (!p) break;
        p++;
    }
    return NULL;
}

void write_str(int fd, const char* str) {
    if (str) {
        write(fd, str, strlen(str));
    }
}

int c_itoa(int num, char* buffer) {
    char* p = buffer;
    if (num == 0) {
        *p++ = '0';
    } else {
        char* start = p;
        if (num < 0) {
            num = -num;
        }
        while (num > 0) {
            *p++ = (num % 10) + '0';
            num /= 10;
        }
        char* end = p - 1;
        while (start < end) {
            char temp = *start;
            *start++ = *end;
            *end-- = temp;
        }
    }
    *p = '\0'; // Null-terminate
    return p - buffer; // Mengembalikan panjang string
}