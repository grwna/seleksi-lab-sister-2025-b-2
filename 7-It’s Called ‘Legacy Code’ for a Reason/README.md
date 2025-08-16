# It’s Called ‘Legacy Code’ for a Reason
Cobol-cobolan

## Daftar Isi
- [Perbaikan](perbaikan)

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Perbaikan Cobol      | Wajib | ✅ |
| Konversi Rai -> IDR  | Wajib | ❌ |
| Kubernetes       | Bonus | ✅ |
| Automatic Interest        | Bonus | ✅ |
| Reverse Proxy       | Bonus | ❌ |
| Domain     | Bonus | ❌ |


## Perbaikan
### Dockerfile
- Tambah 2 line berikut.
```
    COPY requirements.txt ./
    RUN pip install --no-cache-dir -r requirements.txt
```
-  Tambah `gnucobol4` ke `apt-get-install` sebagai compiler Cobol.
- Ubah `EXPOSE` dari 5000 menjadi 8000
- Kompilasi `main.cob`, dengan command
```
    RUN cobc -x -o main main.cob
```

>[!note]
> Jalankan Docker dengan
>docker build -t cobol-app ./hasil <br>
>docker run --rm -p 8000:8000 cobol-app <br>

### main.cob
- Pada paragraf `APPLY-ACTION` logika withdrawal dan deposit terbalik.
- Pada paragraf `FINALIZE`, file output hanya dibuka lalu ditutup, tidak dituliskan. Tambah `WRITE OUT-RECORD` di antara line membuka dan line menutup
- Pada beberapa titik, ada kesalahan text slicing (ie. 1:5, 6:3), sesuaikan dengan panjang sebenarnya.
- Ukuran buffer file diubah 15 -> 18 (harus persis 18 karena data input panjangnya 18).
- Logika `PROCESS-RECORDS` berhenti ketika ada *match found*, ganti `PERFORM UNTIL MATCH-FOUND = "Y"`menjadi `PERFORM FOREVER`


BARU
- ganti . ke v di beberapa

NEW - membuat akun baru
DEP - deposit (mengurangi balance)
WDR - withdrawal (menambah balance)
BAL - balance inquiry (melihat balance)


## Bonus
### Kubernetes
- Menggunakan Minikube 

Dari dalam direktori root repo ini
`minikube start`
`docker build -t cobol-app ./hasil`
`eval $(minikube -p minikube docker-env)`
`kubectl apply -f manifest/deployment.yaml -f manifest/service.yaml -f manifest/pvc.yaml`
`kubectl port-forward service/cobol-service 8000:80` pada terminal berbeda
`minikube service cobol-service` pada terminal berbeda

### Interest Rate
Dibuat dalam bentuk infinite loop yang memanggil sleep(23) sebelum memproses ulang perhitungan bunga. <br>
Hanya bisa dijalankan bersama dengan aplikasi biasa menggunakan kubernetes sebagai dua *container* dalam satu pod. <br>
Untuk mengeceknya, pertama jalankan `kubectl get pods` untuk mendapatkan nama pod, kemudian jalankan
```
    kubectl exec <POD_NAME> -c webapp -- cat accounts.txt
    kubectl exec <POD_NAME> -c interest -- cat accounts.txt
```
Untuk membandingkan file pada kedua *container*, serta
```
    kubectl logs <POD_NAME> -c interest
```
Untuk memonitor keberjalanannya perhitungan *interest*.