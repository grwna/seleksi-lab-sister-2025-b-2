# $BTC
Simulasi ***Bitcoin Network*** sederhana.

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Block Structure and Hashing      | Wajib | ✅ |
| Mining  | Wajib | ✅ |
| Networking | Wajib | ✅ |
| Chain Synchronization| Wajib | ✅ |
| Data Persistence | Wajib | ✅ |

Youtube Video - [https://youtu.be/ihMj_ZLK--Q](https://youtu.be/ihMj_ZLK--Q)

## Deskripsi
Proyek ini adalah implementasi sederhana dari jaringan blockchain yang ditulis dalam bahasa Python. Aplikasi ini mensimulasikan fungsionalitas inti dari blockchain, seperti mining, transaksi, dan mekanisme konsensus antar-node.

Jaringan ini berjalan secara lokal, setiap node adalah server API Flask yang independen. Saya juga membuat aplikasi klien berbasis CLI untuk mempermudah menggunakan jaringan ini.

*Source code* utama
- `node.py`
- `block.py`
- `blockchain.py`

Lainnya
- `cli.py` - program CLI untuk mempermudah testing dan demo 
- `API.md` - dokumentasi API 

---

## Cara Kerja 
- Setiap node harus saling terdaftar dalam list tetangga agar dapat berkomunikasi
- Setelah berhasil mining, node akan menyebarkan chain baru yang ia miliki ke semua tetangganya 
- Ketika ada fork, akan ter-*resolve* otomatis ketika berhasil mining, atau bisa di-*resolve* manual
- *Chain* yang kalah (yang lebih pendek) akan dibuang, namun transaksi di dalamnya akan dikembalikan ke *pool*

**Struktur Blok**
```json
{
    "hash": "0000409740fbea24bd7...",
    "index": 1,
    "merkle_root": "03f3789de44fa6b5d55...",
    "nonce": 150898,
    "previous_hash": "000029bf2719186c885...",
    "timestamp": "2025-08-27 15:17:50",
    "transactions": [
      {
        "amount": 10.5,
        "recipient": "Bob",
        "sender": "Alice"
      }
    ]
  }
```

## Cara Menggunakan

### Prerequisites

- Python 3
- `pip` (Python *package installer*)

Lakukan instalasi *dependency* Python dengan `pip install -r requirements.txt`

### Jalankan Node

Buka beberapa jendela terminal untuk menjalankan node di port yang berbeda.

**Terminal 1 (Node 1):**
```bash
python src/api.py -p 5000
```

**Terminal 2 (Node 2):**
```bash
python src/api.py -p 5001
```

**Terminal 3 (Node 3):**
```bash
python src/api.py -p 5002
```

### Menggunakan Client Admin

Buka terminal baru untuk menjalankan aplikasi CLI.

```bash
python src/cli.py
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
Jika ingin melakukan request manual menggunakan `curl` atau lainnya, sudah disediakan [dokumentasi API](./API.md)