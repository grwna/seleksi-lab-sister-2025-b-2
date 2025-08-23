section .data
    ; --- Content Types ---
    mime_html   db 'Content-Type: text/html; charset=utf-8', 13, 10
    len_html    equ $ - mime_html
    mime_css    db 'Content-Type: text/css', 13, 10
    len_css     equ $ - mime_css
    mime_js     db 'Content-Type: application/javascript', 13, 10
    len_js      equ $ - mime_js
    mime_png    db 'Content-Type: image/png', 13, 10
    len_png     equ $ - mime_png
    mime_jpg    db 'Content-Type: image/jpeg', 13, 10
    len_jpg     equ $ - mime_jpg
    mime_ico    db 'Content-Type: image/x-icon', 13, 10
    len_ico     equ $ - mime_ico
    mime_default db 'Content-Type: application/octet-stream', 13, 10
    len_default equ $ - mime_default

    ext_html    db '.html', 0
    ext_css     db '.css', 0
    ext_js      db '.js', 0
    ext_png     db '.png', 0
    ext_jpg     db '.jpg', 0
    ext_ico     db '.ico', 0

    mime_lookup_table:
        dq ext_html, mime_html, len_html
        dq ext_css,  mime_css,  len_css
        dq ext_js,   mime_js,   len_js
        dq ext_png,  mime_png,  len_png
        dq ext_jpg,  mime_jpg,  len_jpg
        dq ext_ico,  mime_ico,  len_ico
        dq 0 

section .text
    global get_mime_type


get_mime_type:
    push rdi
    mov r8, rdi
    mov r9, 0

    .find_dot_loop:
        cmp byte [r8], 0
        je .found_last_dot
        cmp byte [r8], '.'
        je .dot_seen
        inc r8
        jmp .find_dot_loop

    .dot_seen:                         ; found a dot
        mov r9, r8
        inc r8
        jmp .find_dot_loop

    .found_last_dot:
        cmp r9, 0
        je .set_default

        lea r10, [mime_lookup_table]

    .lookup_loop:
            mov rsi, [r10]
        cmp rsi, 0
        je .set_default

        mov rdi, r9
        .strcmp_loop:
            mov al, [rdi]
            mov bl, [rsi]
            cmp al, bl
            jne .next_entry
            cmp al, 0
            je .match_found
            inc rdi
            inc rsi
            jmp .strcmp_loop
        
    .next_entry:
        add r10, 24
        jmp .lookup_loop

    .match_found:
        mov rsi, [r10 + 8]
        mov rdx, [r10 + 16]
        pop rdi
        ret

    .set_default:
        lea rsi, [mime_default]
        mov rdx, len_default
        pop rdi
        ret