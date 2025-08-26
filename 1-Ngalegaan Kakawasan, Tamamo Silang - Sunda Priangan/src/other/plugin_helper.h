#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

const char* get_query_param(const char* query_string, const char* key);
void write_str(int fd, const char* str);
int c_itoa(int num, char* buffer);