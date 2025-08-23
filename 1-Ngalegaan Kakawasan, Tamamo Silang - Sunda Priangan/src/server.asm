%include "src/constants.inc"

section .data
    server_address:
        .sin_family dw AF_INET
        .sin_port   dw ((PORT & 0xFF) << 8) | (PORT >> 8) ; Port dalam Big Endian (htons)
        .sin_addr   dd 0x00000000   ; menerima dari IP mana saja
        .sin_zero   dq 0            ; padding
    server_address_len equ $ - server_address

    
    msg_method      db "Method: "
    len_msg_method  equ $ - msg_method
    msg_path        db ", Path: "
    len_msg_path    equ $ - msg_path
    newline         db 0xA

    reuse_opt dd 1

    ; HTTP Status Lines
    http_200_ok         db 'HTTP/1.1 200 OK', 13, 10
    len_200_ok          equ $ - http_200_ok
    http_404_not_found  db 'HTTP/1.1 404 Not Found', 13, 10
    len_404_not_found   equ $ - http_404_not_found

    ; HTTP Headers
    header_content_type_html db 'Content-Type: text/html; charset=utf-8', 13, 10
    len_content_type_html    equ $ - header_content_type_html
    header_content_length db 'Content-Length: '
    len_content_length      equ $ - header_content_length

    crlf                db 13, 10 ; Karakter baris baru (CRLF) untuk akhir header
    len_crlf            equ $ - crlf

    ; Path ke file-file
    path_index          db './public/index.html', 0
    path_404            db './public/404.html', 0
    path_prefix         db './public'
    len_prefix          equ $ - path_prefix


    ; =================== METHODS ============================
    http_201_created    db 'HTTP/1.1 201 Created', 13, 10
    len_201_created     equ $ - http_201_created
    http_405_not_allowed db 'HTTP/1.1 405 Method Not Allowed', 13, 10
    len_405_not_allowed  equ $ - http_405_not_allowed
    http_409_conflict   db 'HTTP/1.1 409 Conflict', 13, 10
    len_409_conflict    equ $ - http_409_conflict
    http_500_error      db 'HTTP/1.1 500 Internal Server Error', 13, 10
    len_500_error       equ $ - http_500_error

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

section .text
    global _start
    global serve_static_file
    extern itoa
    extern atoi
    extern strcmp
    extern get_mime_type
    extern find_body


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

    call print_parsing
    call handle_route
    jmp client_disconnected

print_parsing:
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
    call strcmp
    cmp rax, 0
    je handle_get

    ; POST
    lea rsi, [method_post_str]
    mov rdi, [method_]
    call strcmp
    cmp rax, 0
    je handle_post

    ; PUT
    lea rsi, [method_put_str]
    mov rdi, [method_]
    call strcmp
    cmp rax, 0
    je handle_put

    ; DELETE
    lea rsi, [method_delete_str]
    mov rdi, [method_]
    call strcmp
    cmp rax, 0
    je handle_delete

    jmp handle_method_not_allowed

    
build_path:
    push rcx
    push rsi

    lea rsi, [path_prefix]
    mov rcx, len_prefix
    rep movsb

    mov rsi, [path_]
    mov rcx, [path_len]
    rep movsb

    pop rsi
    pop rcx
    ret

handle_get:
    mov rsi, [path_]
    cmp byte [rsi], '/'
    jne .serve_file

    mov rdx, [path_len]
    cmp rdx, 1
    je .serve_index                    ; Serve index.html if path is '/'

    jmp .serve_file

    .serve_index:
        lea rdi, [path_buffer]
        lea rsi, [path_index]
        mov rcx, 21                    ; Hardcoded length of index path cos im too lazy
        rep movsb                      ; copy string

        lea rdi, [path_buffer]
        call serve_static_file
        jmp client_disconnected

    .serve_file:
    ; appends ./public prefix then call to serve file
        lea rdi, [path_buffer]
        call build_path
        mov byte [rdi], 0

        lea rdi, [path_buffer]
        call serve_static_file
        jmp client_disconnected

    not_found:
        lea rdi, [path_404]
        call serve_404
        jmp client_disconnected
    ret


handle_put:
    lea rdi,  [path_buffer]
    call build_path
    mov byte [rdi], 0

    mov rax, SYS_OPEN
    lea rdi, [path_buffer]
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644o                     ; permission
    syscall

    cmp rax, 0
    jl .put_failed  

    mov r12, rax

    call find_and_calc_body
    jc .put_failed


    ; Write body to file
    mov rax, SYS_WRITE
    mov rdi, r12 ; file fd
    syscall

    mov rax, SYS_CLOSE
    mov rdi, r12
    syscall

    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [http_200_ok]
    mov rdx, len_200_ok
    syscall
    jmp client_disconnected

    .put_failed:
        mov rax, SYS_WRITE
        mov rdi, [client_fd]
        lea rsi, [http_500_error]
        mov rdx, len_500_error
        syscall
        jmp client_disconnected

handle_post:
    lea rdi,  [path_buffer]
    call build_path
    mov byte [rdi], 0

    mov rax, SYS_OPEN
    lea rdi, [path_buffer]
    mov rsi, O_WRONLY | O_CREAT | O_EXCL
    mov rdx, 0644o                     ; permission
    syscall

    cmp rax, 0
    jl .post_failed

    mov r12, rax

    call find_and_calc_body
    jc .post_failed

    ; Write body to file
    mov rax, SYS_WRITE
    mov rdi, r12 ; file fd
    syscall

    mov rax, SYS_CLOSE
    mov rdi, r12
    syscall

    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [http_201_created]
    mov rdx, len_201_created
    syscall
    jmp client_disconnected

    .post_failed:
        mov rax, SYS_WRITE
        mov rdi, [client_fd]
        lea rsi, [http_409_conflict]
        mov rdx, len_409_conflict
        syscall
        jmp client_disconnected

handle_delete:
    lea rdi, [path_buffer]
    call build_path
    mov byte [rdi], 0

    mov rax, SYS_UNLINK
    lea rdi, [path_buffer]
    syscall

    cmp rax, 0
    jl .delete_failed

    ; SUCCESS 200
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [http_200_ok]
    mov rdx, len_200_ok
    syscall
    jmp client_disconnected

    .delete_failed:
        ; Could be 404 Not Found, etc.
        mov rax, SYS_WRITE
        mov rdi, [client_fd]
        lea rsi, [http_404_not_found]
        mov rdx, len_404_not_found
        syscall
        jmp client_disconnected


handle_method_not_allowed:
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [http_405_not_allowed]
    mov rdx, len_405_not_allowed
    syscall
    jmp client_disconnected


client_disconnected:
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall






; Input: R15 = Total number of bytes read from the socket
; Output on Success:
;         RSI = pointer to the start of the body
;         RDX = length of the body
;         Carry Flag (CF) = 0
; Output on Failure:
;         Carry Flag (CF) = 1
find_and_calc_body:
    push rcx
    xor rcx, rcx ; Start search from the beginning of the buffer

.find_body_loop:
    ; Check if we've searched past the end of the read data
    cmp rcx, r15
    jge .not_found ; If so, the separator was not found

    ; Find the \r\n\r\n separator
    cmp dword [client_buffer + rcx], 0x0A0D0A0D
    je .found_body

    inc rcx
    jmp .find_body_loop

.found_body:
    ; Body starts 4 bytes after the separator
    lea rsi, [client_buffer + rcx + 4]

    ; Calculate body length: RDX = Total Size - Header Size - Separator Size
    mov rdx, r15
    sub rdx, rcx
    sub rdx, 4

    clc ; Clear Carry Flag to signal SUCCESS
    pop rcx
    ret

.not_found:
    stc ; Set Carry Flag to signal FAILURE
    pop rcx
    ret





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
        jmp not_found




serve_404:
    ; --- Kirim Header 404 Not Found ---
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [http_404_not_found]
    mov rdx, len_404_not_found
    syscall
    
    ; Di sini kita bisa langsung menyajikan file 404.html
    lea rdi, [path_404]
    call serve_static_file ; Panggil lagi serve_static_file untuk 404.html
    ret


