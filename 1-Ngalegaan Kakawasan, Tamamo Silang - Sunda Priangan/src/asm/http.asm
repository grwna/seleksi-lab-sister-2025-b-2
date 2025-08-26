%include "src/asm/constants.inc"

section .data
    ; =================== METHODS ============================
    ; HTTP Status Lines
    global http_200_ok, len_200_ok

    http_200_ok         db 'HTTP/1.1 200 OK', 13, 10
    len_200_ok          equ $ - http_200_ok
    http_404_not_found  db 'HTTP/1.1 404 Not Found', 13, 10
    len_404_not_found   equ $ - http_404_not_found
    http_201_created    db 'HTTP/1.1 201 Created', 13, 10
    len_201_created     equ $ - http_201_created
    http_405_not_allowed db 'HTTP/1.1 405 Method Not Allowed', 13, 10
    len_405_not_allowed  equ $ - http_405_not_allowed
    http_409_conflict   db 'HTTP/1.1 409 Conflict', 13, 10
    len_409_conflict    equ $ - http_409_conflict
    http_500_error      db 'HTTP/1.1 500 Internal Server Error', 13, 10
    len_500_error       equ $ - http_500_error

    ; dont know why it has to be this way, but it works
    status_lookup_table:
        dw 200
        dq http_200_ok
        dq len_200_ok

        dw 201
        dq http_201_created
        dq len_201_created

        dw 404
        dq http_404_not_found
        dq len_404_not_found

        dw 405
        dq http_405_not_allowed
        dq len_405_not_allowed

        dw 409
        dq http_409_conflict
        dq len_409_conflict

        dw 500
        dq http_500_error
        dq len_500_error
        
    dw 0

    ; Path ke file-file
    path_index          db './public/index.html', 0
    path_404            db './public/404.html', 0
    path_prefix         db './public'
    len_prefix          equ $ - path_prefix

    ; plugin
    plugin_path db '/plugin/', 0

section .bss
    extern client_buffer
    extern client_fd
    extern path_, path_len, path_buffer, method_


section .text
    ; global serve_static_file
    global find_and_calc_body
    global handle_get, handle_delete, handle_post, handle_put, handle_method_not_allowed
    global not_found, send_status

    extern atoi, strcmp
    extern client_disconnected, serve_static_file
    extern handle_plugin_request

; Input: Total number of bytes read from the socket
; Output
; RSI = pointer to the start of the body
; RDX = length of the body
find_and_calc_body:
    push rcx
    xor rcx, rcx ; Start search from the beginning of the buffer

    .find_body_loop:
        ; Check if we've searched past the end of the read data
        cmp rcx, r15
        jge .not_found

        cmp dword [client_buffer + rcx], 0x0A0D0A0D
        je .found_body

        inc rcx
        jmp .find_body_loop

    .found_body:
        lea rsi, [client_buffer + rcx + 4]

        mov rdx, r15
        sub rdx, rcx
        sub rdx, 4

        clc
        pop rcx
        ret

    .not_found:
        stc
        pop rcx
        ret

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
    ; push rdi
    ; push rsi
    ; push rcx

    ; ; handle plugin
    ; mov rdi, [path_]
    ; mov rsi, plugin_path
    ; mov rcx, 8

    ; cld
    ; repe cmpsb
    ; je .call_plugin

    ; pop rdi
    ; pop rsi
    ; pop rcx

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

    ; .call_plugin:
    ;     mov rdi, [client_fd]
    ;     mov rsi, [method_]
    ;     mov rdx, [path_]
    ;     call handle_plugin_request

    ;     jmp client_disconnected
    ; ret

not_found:
    lea rdi, [path_404]
    call serve_404
    jmp client_disconnected


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

    mov rdi, 200
    call send_status
    jmp client_disconnected

    .put_failed:
        mov rdi, 500
        call send_status
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

    mov rdi, 201
    call send_status
    jmp client_disconnected

    .post_failed:
        mov rdi, 409
        call send_status
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
    mov rdi, 200
    call send_status
    jmp client_disconnected

    .delete_failed:
        ; Could be 404 Not Found, etc.
        mov rdi, 404
        call send_status
        jmp client_disconnected


handle_method_not_allowed:
    mov rdi, 405
    call send_status
    jmp client_disconnected

serve_404:
    ; --- Kirim Header 404 Not Found ---
    mov rdi, 404
    call send_status
    
    lea rdi, [path_404]
    call serve_static_file
    ret

; RDI - status code
send_status:
    push rdi
    push rbx
    push rcx

    lea rbx, [status_lookup_table]

    .lookup_loop:
        mov cx, [rbx]
        cmp cx, 0           ; end of table check
        je .not_found

        cmp cx, di          ; compare code with table entry
        je .found

        add rbx, 18
        jmp .lookup_loop

    .found:
        mov rsi, [rbx + 2]  ; load message
        mov rdx, [rbx + 10] ; load length of message
        jmp .send

    .not_found:
        ; If code not found, default to 500 Internal Server Error
        lea rsi, [http_500_error]
        mov rdx, len_500_error

    .send:
        mov rax, SYS_WRITE
        mov rdi, [client_fd]
        syscall

        pop rcx
        pop rbx
        pop rdi
        ret