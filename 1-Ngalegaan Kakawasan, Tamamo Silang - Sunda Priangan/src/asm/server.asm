%include "src/asm/constants.inc"

section .data
    server_address:
        .sin_family dw AF_INET
        .sin_port   dw ((PORT & 0xFF) << 8) | (PORT >> 8) ; Port dalam Big Endian (htons)
        .sin_addr   dd 0x00000000   ; menerima dari IP mana saja
        .sin_zero   dq 0            ; padding
    server_address_len equ $ - server_address
    msg_listening db 'Listening on port 8080...', 0xA
    len_listening equ $ - msg_listening

    
    msg_method      db "Method: "
    len_msg_method  equ $ - msg_method
    msg_path        db ", Path: "
    len_msg_path    equ $ - msg_path
    newline         db 0xA

    reuse_opt dd 1

    ; HTTP Headers
    header_content_type_html db 'Content-Type: text/html; charset=utf-8', 13, 10
    len_content_type_html    equ $ - header_content_type_html
    header_content_length db 'Content-Length: '
    len_content_length      equ $ - header_content_length

    crlf                db 13, 10 ; Karakter baris baru (CRLF) untuk akhir header
    len_crlf            equ $ - crlf

    html_ext            db '.html', 0           ; to force mime type to html

    ; Method strings for comparison
    method_get_str      db 'GET', 0
    method_post_str     db 'POST', 0
    method_put_str      db 'PUT', 0
    method_delete_str   db 'DELETE', 0

section .bss
    server_fd resq 1
    client_fd resq 1

    client_buffer resb REQUEST_BUFFER_SIZE
    
    method_     resq 1
    method_len  resq 1
    path_       resq 1
    path_len    resq 1

    path_buffer resb 256

    global client_fd
    global client_buffer
    global path_, path_len, path_buffer, method_

section .text
    global _start
    global serve_static_file
    global client_disconnected

    extern itoa, atoi, asm_strcmp, append
    extern get_mime_type
    extern find_and_calc_body
    extern handle_get, handle_delete, handle_post, handle_put, handle_method_not_allowed
    extern not_found

    extern http_200_ok
    extern len_200_ok
    extern exit


_start:
    ; --- 1. Create Socket ---
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx                       ; default protocol
    syscall

    mov [server_fd], rax               ; save fd

    ; --- Set SO_REUSEADDR Option ---
    mov rax, SYS_SETSOCKOPT
    mov rdi, [server_fd]
    mov rsi, SOL_SOCKET
    mov rdx, SO_REUSEADDR
    lea r10, [reuse_opt]
    mov r8, 4
    syscall
    ; =================================

    ; --- 2. Bind Socket --- 
    mov rax, SYS_BIND
    mov rdi, [server_fd]
    lea rsi, [server_address]
    mov rdx, server_address_len
    syscall

    ; --- 3. Listen for connection  ---
    mov rax, SYS_LISTEN
    mov rdi, [server_fd]
    mov rsi, 10                        ; Connection queue
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [msg_listening]
    mov rdx, len_listening
    syscall

accept_loop:
    mov rax, SYS_ACCEPT
    mov rdi, [server_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall

    mov [client_fd], rax               ; Client FD

    mov rax, SYS_FORK
    syscall

    cmp rax, 0                         ; retval of FORK
    je child_process

    ; --- Parent Process ---
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall

    jmp accept_loop


child_process:
    and rsp, -16        ; align stack for plugin

    mov rax, SYS_CLOSE
    mov rdi, [server_fd]
    syscall

    ; --- Read Requests ---
    mov rax, SYS_READ
    mov rdi, [client_fd]
    lea rsi, [client_buffer]
    mov rdx, REQUEST_BUFFER_SIZE
    syscall

    mov r15, rax                       ; read data

    ; --- Parse Method ---
    lea rsi, [client_buffer]
    mov [method_], rsi
    .parse_method_loop:
        cmp byte [rsi], ' '            ; First space
        je .method_found
        inc rsi
        jmp .parse_method_loop

    .method_found:
        mov rdx, rsi
        sub rdx, [method_]
        mov [method_len], rdx

        mov byte [rsi], 0              ; Null terminate method
        inc rsi

    mov [path_], rsi
    .parse_path_loop:
        cmp byte [rsi], ' '            ; First space
        je .path_found
        inc rsi
        jmp .parse_path_loop
    
    .path_found:
        mov byte [rsi], 0

        ; path length
        mov rdx, rsi
        sub rdx, [path_]
        mov [path_len], rdx

    call print_logging
    call handle_route
    jmp client_disconnected

print_logging:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [msg_method]
    mov rdx, len_msg_method
    syscall
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, [method_]
    mov rdx, [method_len]              ; Length of method 
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [msg_path]
    mov rdx, len_msg_path
    syscall
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, [path_]
    mov rdx, [path_len]
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    ret


handle_route:
    mov rdi, [method_]

    ; GET
    lea rsi, [method_get_str]
    call asm_strcmp
    cmp rax, 0
    je handle_get

    ; POST
    lea rsi, [method_post_str]
    mov rdi, [method_]
    call asm_strcmp
    cmp rax, 0
    je handle_post

    ; PUT
    lea rsi, [method_put_str]
    mov rdi, [method_]
    call asm_strcmp
    cmp rax, 0
    je handle_put

    ; DELETE
    lea rsi, [method_delete_str]
    mov rdi, [method_]
    call asm_strcmp
    cmp rax, 0
    je handle_delete

    jmp handle_method_not_allowed


client_disconnected:
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall

    ; mov rax, SYS_EXIT
    xor rdi, rdi
    ; syscall
    call exit


serve_static_file:
    ; --- Open File ---
    mov rax, SYS_OPEN
    mov rsi, 0
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl .file_open_error

    mov r12, rax                       ; store fd

    ; Get file size
    sub rsp, 144
    mov rdi, r12
    mov rsi, rsp
    mov rax, SYS_FSTAT
    syscall

    ; size is att offset 48
    mov r13, [rsp + 48]
    add rsp, 144

    ; -- Header 200 OK
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [http_200_ok]
    mov rdx, len_200_ok
    syscall

    ; --- Content Type ---
    lea rdi, [path_buffer]
    call get_mime_type                 ; RSI dan RDX are set here

    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    ; lea rsi, [header_content_type_html]
    ; mov rdx, len_content_type_html
    syscall

    ; Content-Length
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [header_content_length]
    mov rdx, len_content_length
    syscall

    ; --- Convert Filesize to String
    mov rdi, r13
    sub rsp, 20
    mov rsi, rsp
    call itoa
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    mov rsi, rsp
    syscall

    add rsp, 20

    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [crlf]
    mov rdx, len_crlf
    syscall

    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [crlf]
    mov rdx, len_crlf
    syscall

    ; --- Send file content ---
    .send_loop:
        ; --- Reads up to 4096 bytes at a time
        mov rax, SYS_READ
        mov rdi, r12 
        lea rsi, [client_buffer]
        mov rdx, REQUEST_BUFFER_SIZE
        syscall

        cmp rax, 0                     ; Size read, 0 means EOF
        jle .send_finished

        ; --- Write to Client --- 
        mov rdx, rax
        mov rax, SYS_WRITE
        mov rdi, [client_fd]
        lea rsi, [client_buffer]
        syscall
        jmp .send_loop

    .send_finished:
        mov rax, SYS_CLOSE
        mov rdi, r12
        syscall
        ret
    
    .file_open_error:
        lea rdi, [path_buffer]
        lea rsi, [html_ext]
        call append


        jmp not_found
