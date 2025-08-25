# $BTC
Simulasi ***Bitcoin Betwork*** sederhana.

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Block Structure and Hashing      | Wajib | ✅ |
| Mining  | Wajib | ✅ |
| Networking | Wajib | ✅ |
| Chain Synchronization| Wajib | ✅ |
| Data Persistence | Wajib | ✅ |

Youtube Video - [youtube.com]()

## Deskripsi
Proyek ini adalah implementasi sederhana dari jaringan blockchain yang ditulis dalam bahasa Python. Aplikasi ini mensimulasikan fungsionalitas inti dari blockchain, seperti mining, transaksi, dan mekanisme konsensus antar-node.

Jaringan ini berjalan secara lokal, setiap node adalah server API Flask yang independen. Saya juga membuat aplikasi klien berbasis CLI untuk mempermudah menggunakan jaringan ini.

*Source code* utama
- `api.py`
- `block.py`
- `blockchain.py`


Lainnya
- `cli.py` - program CLI untuk mempermudah testing dan demo 
- `testing.md` - panduan langkah-langkah untuk mengetes fitur pada *network*
- `API.md` - dokumentasi API 

---

## Cara Menggunakan

### Prerequisites

- Python 3
- `pip` (Python *package installer*)

Lakukan instalasi *dependency* Python dengan `pip install -r requirements.txt`

### Jalankan Node

Buka beberapa jendela terminal untuk menjalankan node di port yang berbeda.

**Terminal 1 (Node 1):**
```bash
python api.py -p 5000
```

**Terminal 2 (Node 2):**
```bash
python api.py -p 5001
```

**Terminal 3 (Node 3):**
```bash
python api.py -p 5002
```

### Menggunakan Client Admin

Buka terminal baru untuk menjalankan aplikasi CLI.

```bash
python cli.py
```

Anda akan disambut dengan menu interaktif. Berikut penjelasan masing-masing opsi:
```
====== Blockchain Network CLI ======
1. Mine a New Block                - melakukan mining sebuah block
2. Display Full Chain              - menampilkan chain dari node tertentu
3. Add a New Transaction           - menambahkan transaksi baru ke dalam pool
4. Display Transaction Pool        - melihat daftar transaksi yang sedang pending
5. Register New Nodes              - mendaftarkan satu atau beberapa node pada node tertentu
6. List Registered Nodes           - menampilkan semua node yang terdaftar pada node tertentu
7. Register All Nodes              - saling mendaftarkan semua node yang diinginkan
8. Resolve Conflicts (Sync)        - melakukan syncing chain secara manual
9. Set PoW Difficulty              - mengatur difficulty dari proof of work
10. Clear Screen
0. Exit
```

### Melakukan Request Manual
Jika ingin melakukan request manual menggunakan `curl` atau lainnya, sudah disediakan [dokumentasi API](./API.md")