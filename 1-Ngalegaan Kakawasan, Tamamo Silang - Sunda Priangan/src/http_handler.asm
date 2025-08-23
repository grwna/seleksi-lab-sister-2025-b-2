%include "src/constants.inc"

section .data

section .text
    ; global serve_static_file
    global find_body
    extern atoi

;FS
; RSI - start of body buffer
; RDX - Size of content
find_body:
    push rdi
    ; push rsi
    mov r14, rdi ; Save start of buffer
    mov rdx, 0   ; Default content length to 0

; --- First, find Content-Length ---
.find_cl_loop:
    cmp byte [rdi], 0
    je .find_body_start ; End of buffer, stop searching for CL

    ; A more robust, case-insensitive check for "Content-Length"
    cmp dword [rdi], 'Cont'
    je .check_rest
    cmp dword [rdi], 'cont'
    jne .next_char

.check_rest:
    cmp dword [rdi+4], 'ent-'
    je .check_len
    cmp dword [rdi+4], 'ENT-'
    jne .next_char
    
.check_len:
    cmp dword [rdi+8], 'Leng'
    je .found_cl_header
    cmp dword [rdi+8], 'LENG'
    jne .next_char

.found_cl_header:
    ; Move pointer past "Content-Length: "
    mov rsi, rdi
.find_colon_loop:
    cmp byte [rsi], ':'
    je .found_colon
    cmp byte [rsi], 0
    je .find_body_start ; Reached end of request without a colon
    inc rsi
    jmp .find_colon_loop
.found_colon:
    inc rsi ; Move past ':'
.skip_space_loop:
    cmp byte [rsi], ' ' ; Skip whitespace
    jne .convert_num
    inc rsi
    jmp .skip_space_loop
.convert_num:
    push rdi ; Save main search pointer
    mov rdi, rsi
    call atoi
    mov rdx, rax ; RDX = content length
    pop rdi
    jmp .find_body_start

.next_char:
    inc rdi
    jmp .find_cl_loop

; --- Second, find the start of the body ---
.find_body_start:
    mov rdi, r14 ; Restore start of buffer
.find_blank_line_loop:
    cmp byte [rdi], 0
    je .done
    ; Check for \r\n\r\n
    cmp dword [rdi], 0x0A0D0A0D
    je .body_start
    inc rdi
    jmp .find_blank_line_loop

.body_start:
    add rdi, 4 ; Move pointer past the \r\n\r\n
    mov rsi, rdi ; RSI = pointer to body start

.done:
    ; pop rsi
    pop rdi
    ret