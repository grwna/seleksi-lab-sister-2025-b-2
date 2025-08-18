# 4-bit fisherman
Simulasi koputer 4-bit pada Logisim.

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Block Structure and Hashing      | Wajib | ✅ |
| Mining  | Wajib | ✅ |
| Networking | Wajib | ✅ |
| Chain Synchronization| Wajib | ✅ |
| Data Persistence | Wajib | ✅ |

## Link
How to test:
Run server with 
```bash
python api.py
```
atau

```bash
python api.py --port <PORT_NUMBER>
```

Jika berjalan pada port 5000    

- Mining blok
```bash
curl http://127.0.0.1:5000/mine
```
- Send Transaction
```bash
curl -X POST -H "Content-Type: application/json" -d '{"sender": "budi", "recipient": "siti", "amount": 5}' http://127.0.0.1:5000/transactions/new
```

- Mine again to insert transaction to blobk
```bash
curl http://127.0.0.1:5000/mine
```

- View Chain
```bash
curl http://127.0.0.1:5000/chain
```

- Mendaftarkan Nodes
Mendaftarkan node pada port 5001 ke node port 5000
```bash
curl -X POST -H "Content-Type: application/json" -d '{"nodes": ["http://127.0.0.1:5001"]}' http://127.0.0.1:5000/nodes/register
```