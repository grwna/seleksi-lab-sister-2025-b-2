%include "src/constants.inc"

section .data
    ; struct sockaddr_in untuk proses bind()
    ; C struct:
    ; struct sockaddr_in {
    ;   sa_family_t    sin_family;  (2 bytes)
    ;   in_port_t      sin_port;    (2 bytes)
    ;   struct in_addr sin_addr;    (4 bytes)
    ;   unsigned char  sin_zero[8]; (8 bytes)
    ; };
    server_address:
        .sin_family dw AF_INET
        .sin_port   dw ((PORT & 0xFF) << 8) | (PORT >> 8) ; Port dalam Big Endian (htons)
        .sin_addr   dd 0x00000000   ; menerima dari IP mana saja
        .sin_zero   dq 0            ; padding
    server_address_len equ $ - server_address

section .bss
    server_fd resq 1
    client_fd resq 1
    
    client_buffer resb REQUEST_BUFFER_SIZE

section .text
    global _start


_start:
    ; --- 1. Create Socket ---
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx                       ; default protocol
    syscall

    mov [server_fd], rax               ; save fd

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
    jg parent_process


parent_process:
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall

    jmp accept_loop


child_process:
    mov rax, SYS_CLOSE
    mov rdi, [server_fd]
    syscall


handle_client_loop:
    mov rax, SYS_READ
    mov rdi, [client_fd]
    lea rsi, [client_buffer]
    mov rdx, REQUEST_BUFFER_SIZE
    syscall

    cmp rax, 0
    jle client_disconnected

    mov rdx, rax

    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    lea rsi, [client_buffer]
    syscall

    jmp handle_client_loop

client_disconnected:
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall

    ; child exit
    mov rax, SYS_EXIT
    xor rdi, rdi ; Exit code 0 (sukses)
    syscall