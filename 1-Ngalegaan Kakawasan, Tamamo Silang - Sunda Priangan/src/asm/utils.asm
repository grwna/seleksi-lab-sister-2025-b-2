section .text
    global itoa
    global atoi
    global asm_strcmp
    global append

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

; int atoi(char* digits)
atoi:
    xor rax, rax
    
    .loop:
        movzx ecx, byte [rdi]

        ; IF 0 > char and 9 < char, finish
        cmp cl, '0'
        jb .done
        cmp cl, '9'
        ja .done

        sub cl, '0'
        imul rax, 10
        add rax, rcx
        inc rdi
        jmp .loop

    .done:
        ret

asm_strcmp:
    .loop:
        mov al, [rdi]
        mov bl, [rsi]
        cmp al, bl
        jne .done
        cmp al, 0
        je .done
        inc rdi
        inc rsi
        jmp .loop
    .done:
        sub al, bl
        movsx rax, al
        ret

;   rdi - Pointer to the destination buffer (must have enough space).
;   rsi - Pointer to the null-terminated source string to append.
;
;   rdi - Points to the new null terminator of the concatenated string.
append:
    push    rcx
    push    rax

    ; Find  null terminator
    mov     rcx, -1                 ; Max possible length
    xor     al, al
    repne   scasb 
    dec     rdi                     ; Go back one byte to overwrite the original null

.copy_loop:
    lodsb 
    stosb 
    test    al, al
    jnz     .copy_loop              ; If not null byte, continue copying

    pop     rax                     ; Restore registers
    pop     rcx
    ret
