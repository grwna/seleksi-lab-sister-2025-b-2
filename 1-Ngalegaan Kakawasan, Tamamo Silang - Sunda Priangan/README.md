# Ngalegaan Kakawasan, Tamamo Silang - Sunda Priangan
HTTP Server yang ditulis menggunakan x86-64 Assembly, 

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Listening to Port      | Wajib | ✅ |
| Child Process for each Requests   | Wajib | ✅ |
| Parse HTTP Methods    | Wajib | ✅ |
| Serves File           | Wajib | ✅ |
| Routing/Path          | Wajib | ✅ |
| Domain                | Wajib | ✅ |
| Linking Binary                | Bonus | ❌ |
| Port Forwarding                | Bonus | ❌ |
| Backend Framework                | Bonus | ❌ |
| Deploy                | Bonus | ❌ |
| Kreativitas                | Bonus | ❌ |

## Daftar Isi
- [Deskripsi](#deskripsi)
- [Fitur](#fitur)
- [Bonus](#bonus)
- [Refleksi](#refleksi)
- [Referensi](#referensi)

## Deskripsi
Proyek ini adalah sebuah web server sederhana yang ditulis dalam bahasa Assembly x86-64. Server ini mampu menangani beberapa koneksi secara bersamaan menggunakan model forking untuk setiap koneksi dan dapat melayani berbagai jenis file statis serta mendukung metode HTTP dasar seperti GET, POST, PUT, dan DELETE.

- `src` berisikan kode sumber server
- `public` berisikan contoh-contoh file yang dapat dilayani server 

Jenis file yang dapat dilayani:
- HTML
- CSS
- Javascript
- Json
- PNG
- JPG/JPEG
- GIF
- Textfile
- MP4

Jenis file dapat ditambahkan dengan menambah entri MIME pada file `mime.asm`
- Common MIME Types: [Mozilla](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types)

 <br>

> [!tip]
> Jalankan server dengan command `make run`

## Requirements
- NASM
- ld
- GNU Make



## Fitur Utama/Wajib
### 1. Listening to Port
Fitur ini bekerja dengan memanggil syscall `socket`, `bind`, dan `listen`. <br>

**Cara menggunakan** <br>
Cukup jalankan saja server seperti biasa, fitur ini adalah hal pertama yang akan dilakukan server. 

**Cuplikan Kode**
```nasm
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
```

### 2. 


## Refleksi
- Kode tidak terlalu modular, saya mencoba 

## Referensi
- Searchable Syscall Table: https://filippo.io/linux-syscall-table
- Linux man-pages: https://man7.org/linux/man-pages