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
-`src` berisikan kode sumber server
-`public` berisikan contoh-contoh file yang dapat dilayani server 

Server dapat *serve* file berupa:
- HTML file
- PNG, JPG file

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

- MP3
- PDF

Jenis file dapat ditambahkan dengan menambah entri MIME pada file `mime.asm`
- Common MIME Types: [Mozilla](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types)

## Fitur

## Bonus

## Refleksi
- Kode tidak terlalu modular, saya mencoba 

## Referensi
- Searchable Syscall Table: https://filippo.io/linux-syscall-table
- Linux man-pages: https://man7.org/linux/man-pages