section .text
    global itoa

; itoa(int num, char* buffer)
itoa:
    mov rax, rdi
    mov r10, 10                        ; Divisor
    mov rcx, rsi

.conversion_loop:
    xor rdx, rdx
    div r10
    add rdx, '0'                       ; Convert to ASCII
    mov [rcx], dl
    inc rcx
    cmp rax, 0
    jne .conversion_loop

    ; Reverse string
    mov rdx, rcx
    sub rdx, rsi
    mov rax, rdx                       ; Length of string

.reverse_loop:
    dec rcx
    cmp rcx, rsi
    jle .finished
    mov r8b, [rsi]
    mov bl, [rcx]
    mov [rsi], bl
    mov [rcx], r8b
    inc rsi
    jmp .reverse_loop

.finished:
    ret