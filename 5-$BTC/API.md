# Dokumentasi API Blockchain

Berikut adalah dokumentasi untuk setiap endpoint API pada aplikasi blockchain ini.

---

## GET `/mine`

Endpoint ini digunakan untuk menjalankan proses mining, dengan membuat blok baru, dan menyebarkannya ke seluruh peer node dari node yang melakukan mining.

### Request

Tidak memerlukan request *body*.

### Response

-   **Kode Status:** `200 OK`
    -   **Deskripsi:** Berhasil menambang dan menyebarkan blok baru.
    -   **Body:**
        ```json
        {
            "message": "New Block mined and distributed succesfully!",
            "block": {
                "index": 0,
                "timestamp": "string",
                "transactions": [
                    {
                        "sender": "string",
                        "recipient": "string",
                        "amount": 1.0
                    }
                ],
                "merkle_root": "string",
                "nonce": 0,
                "previous_hash": "string",
                "hash": "string"
            },
            "nodes_responses": [
                {
                    "address": "string",
                    "response": {
                        "message": "string"
                    }
                }
            ]
        }
        ```
---

<br>

## GET `/chain`

Mengembalikan seluruh chain yang ada pada node saat ini.

-   **Endpoint:** `/chain`
-   **Metode:** `GET`

#### Request

Tidak memerlukan request *body*.

#### Response

-   **Kode Status:** `200 OK`
    -   **Deskripsi:** Berhasil mengambil data rantai.
    -   **Body:**
        ```json
        {
            "chain": [
                {
                    "index": 1,
                    "timestamp": "string",
                    "transactions": [],
                    "merkle_root": "string",
                    "nonce": 1,
                    "previous_hash": "string",
                    "hash": "string"
                }
            ],
            "length": 1
        }
        ```

<br>

## POST `/difficulty`

Mengubah *difficulty* untuk Proof of Work.


#### Request

-   **Header:** `Content-Type: application/json`
-   **Body:**
    ```json
    {
        "difficulty": 5
    }
    ```

#### Response

-   **Kode Status:** `200 OK`
    -   **Deskripsi:** Tingkat kesulitan berhasil diubah.
    -   **Body:**
        ```json
        {
            "message": "Difficulty changed succesfully",
            "new_difficulty": 5
        }
        ```
-   **Kode Status:** `400 Bad Request`
    -   **Deskripsi:** Request tidak valid (tidak ada data atau `difficulty` bukan integer).
    -   **Body:**
        ```json
        {
            "message": "Error: invalid data"
        }
        ```

---

<br>

## POST `transaction/new`
Menambahkan transaksi baru ke dalam pool transaksi yang sedang pending untuk dimasukkan ke blok berikutnya.

-   **Endpoint:** `/transaction/new`
-   **Metode:** `POST`

### Request

-   **Header:** `Content-Type: application/json`
-   **Body:**
    ```json
    {
        "sender": "sender_address",
        "recipient": "recipient_address",
        "amount": 1.0
    }
    ```

### Response

-   **Kode Status:** `201 Created`
    -   **Deskripsi:** Transaksi berhasil ditambahkan ke daftar tunggu.
    -   **Body:**
        ```json
        {
            "message": "Transaction will be added to Block {index}"
        }
        ```
-   **Kode Status:** `400 Bad Request`
    -   **Deskripsi:** Request tidak lengkap atau formatnya salah.
    -   **Body:**
        ```json
        {
            "message": "Error: invalid data"
        }
        ```

<br>

## GET `transaction/pool`

Mengembalikan seluruh transaksi yang sedang berada di dalam pool.

### Request

Tidak memerlukan request *body*.

### Response

-   **Kode Status:** `200 OK`
    -   **Deskripsi:** Berhasil mengambil daftar transaksi tertunda.
    -   **Body:**
        ```json
        [
            {
                "sender": "sender_address_1",
                "recipient": "recipient_address_1",
                "amount": 1.0
            },
            {
                "sender": "sender_address_2",
                "recipient": "recipient_address_2",
                "amount": 1.0
            }
        ]
        ```

---

<br>

## POST `/nodes/register` 

Mendaftarkan satu atau lebih node baru ke sambungan node dimana endpoint ini dipanggil .

### Request

-   **Header:** `Content-Type: application/json`
-   **Body:**
    ```json
    {
        "nodes": ["node1_address", "node2_address", "nodeX_address"]
    }
    ```

### Response

-   **Kode Status:** `201 Created`
    -   **Deskripsi:** Node baru berhasil ditambahkan.
    -   **Body:**
        ```json
        {
            "message": "New node added",
            "total_nodes": ["node1_address", "node2_address", "nodeX_address"]
        }
        ```
-   **Kode Status:** `400 Bad Request`
    -   **Deskripsi:** Format request salah atau tidak ada daftar node yang diberikan.
    -   **Body:**
        ```json
        {
            "message": "Error: Invalid node list"
        }
        ```

<br>

## GET `/nodes/resolve`

Menjalankan algoritma konsensus untuk menyelesaikan konflik antar node dengan mengganti rantai lokal dengan rantai terpanjang dan valid di jaringan.

### Request

Tidak memerlukan request *body*.

### Response

-   **Kode Status:** `200 OK`
    -   **Deskripsi :** Rantai lokal telah diganti dengan rantai yang lebih otoritatif dari jaringan.
    -   **Body:**
        ```json
        {
            "message": "Our chain has been switched to the most authoritative chain",
            "new_chain": []
        }
        ```
    -   **Deskripsi:** Rantai lokal sudah merupakan yang paling otoritatif.
    -   **Body:**
        ```json
        {
            "message": "Our chain is already the most authoritative",
            "chain": []
        }
        ```

<br>

## GET `/nodes/list`

Mengembalikan daftar lengkap semua node yang saat ini terdaftar di node dimana endpoint ini dipanggil.

-   **Endpoint:** `/nodes/list`
-   **Metode:** `GET`

### Request

Tidak memerlukan request *body*.

### Response

-   **Kode Status:** `200 OK`
    -   **Deskripsi:** Berhasil mengambil daftar semua node yang terdaftar.
    -   **Body:**
        ```json
        {
            "message": "Showing all registered nodes",
            "nodes": [
                "127.0.0.1:5001",
                "127.0.0.1:5002"
            ]
        }
        ```

## POST `/nodes/receive_block`

Menerima block dari node lain. Endpoint ini akan dipanggil secara otomatis oleh node yang selesai melakukan mining block. Akan memanggil endpoint `/nodes/resolve` jika terjadi fork.


### Request

-   **Header:** `Content-Type: application/json`
-   **Body:** (Objek blok yang lengkap)
    ```json
    {
        "index": 3,
        "timestamp": "string",
        "transactions": ],
        "merkle_root": "string",
        "nonce": 1,
        "previous_hash": "string",
        "hash": "string"
    }
    ```

### Response

-   **Kode Status:** `201 Created`
    -   **Deskripsi:** Blok valid diterima dan berhasil ditambahkan.
    -   **Body:**
        ```json
        {
            "message": "New Block accepted and added to chain"
        }
        ```
-   **Kode Status:** `200 OK`
    -   **Deskripsi:** Konflik terdeteksi. Block yang diterima berasal dari fork dengan rantai lebih panjang, memicu proses konsensus, dan rantai diganti.
    -   **Body:**
        ```json
        {
            "message": "message': 'Conflict detected, switching chain"
        }
        ```
    -   **Deskripsi:** Konflik terdeteksi. Block yang diterima berasal dari fork yang lebih pendek, memicu proses konsensus, namun rantai lokal tetap dipertahankan karena lebih panjang.
    -   **Body:**
        ```json
        {
            "message": "message': 'Block accepted from shorter fork, chain is not switched."
        }
        ```
-   **Kode Status:** `400 Bad Request`
    -   **Deskripsi:** Blok ditolak karena berbagai alasan validasi.
    -   **Body (Hash Tidak Cocok):**
        ```json
        {
            "message": "message': 'Block rejected: invalid hash"
        }
        ```
    -   **Body (Proof of Work Tidak Valid):**
        ```json
        {
            "message": "message': 'Block rejected: invalid Proof of Work tidak"
        }
        ```
    -   **Body (Data Kosong):**
        ```json
        {
            "message": "message': 'Error: Block data not found"
        }
        ```
