section .data
    ; --- Content Types ---
    mime_html   db 'Content-Type: text/html; charset=utf-8', 13, 10
    len_html    equ $ - mime_html

    mime_css    db 'Content-Type: text/css', 13, 10
    len_css     equ $ - mime_css

    mime_js     db 'Content-Type: application/javascript', 13, 10
    len_js      equ $ - mime_js

    mime_json   db 'Content-Type: application/json', 13, 10
    len_json    equ $ - mime_json

    mime_png    db 'Content-Type: image/png', 13, 10
    len_png     equ $ - mime_png

    mime_jpg    db 'Content-Type: image/jpeg', 13, 10
    len_jpg     equ $ - mime_jpg

    mime_gif    db 'Content-Type: image/gif', 13, 10
    len_gif     equ $ - mime_gif

    mime_ico    db 'Content-Type: image/x-icon', 13, 10
    len_ico     equ $ - mime_ico

    mime_txt    db 'Content-Type: text/plain', 13, 10
    len_txt     equ $ - mime_txt

    mime_pdf    db 'Content-Type: application/pdf', 13, 10
    len_pdf     equ $ - mime_pdf
    mime_mp3    db 'Content-Type: audio/mp3', 13, 10
    len_mp3     equ $ - mime_mp3

    mime_mp4    db 'Content-Type: video/mp4', 13, 10
    len_mp4     equ $ - mime_mp4

    mime_md    db 'Content-Type: text/markdown', 13, 10
    len_md      equ $ - mime_md
    
    mime_default db 'Content-Type: application/octet-stream', 13, 10
    len_default equ $ - mime_default


    ext_html    db '.html', 0
    ext_htm     db '.htm',  0
    ext_css     db '.css',  0
    ext_js      db '.js',   0
    ext_json    db '.json', 0
    ext_png     db '.png',  0
    ext_jpg     db '.jpg',  0
    ext_jpeg    db '.jpeg', 0
    ext_gif     db '.gif',  0
    ext_ico     db '.ico',  0
    ext_txt     db '.txt',  0
    ext_pdf     db '.pdf',  0
    ext_mp3     db '.mp3',  0 
    ext_mp4     db '.mp4',  0
    ext_md      db '.md',  0

    mime_lookup_table:
        dq ext_html, mime_html, len_html
        dq ext_htm, mime_html, len_html
        dq ext_css,  mime_css,  len_css
        dq ext_js,   mime_js,   len_js
        dq ext_json,   mime_json,   len_json
        dq ext_png,  mime_png,  len_png
        dq ext_jpg,  mime_jpg,  len_jpg
        dq ext_jpeg,  mime_jpg,  len_jpg
        dq ext_gif,  mime_gif,  len_gif
        dq ext_ico,  mime_ico,  len_ico
        dq ext_txt,  mime_txt,  len_txt
        dq ext_pdf,  mime_pdf,  len_pdf
        dq ext_mp3,  mime_mp3,  len_mp3
        dq ext_mp4,  mime_mp4,  len_mp4
        dq ext_md,  mime_md,  len_md
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