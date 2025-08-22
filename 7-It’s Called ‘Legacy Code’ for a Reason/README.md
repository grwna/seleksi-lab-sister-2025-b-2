# It’s Called ‘Legacy Code’ for a Reason
Cobol-cobolan

## Daftar Isi
- [Perbaikan](#perbaikan)
- [Bonus](#bonus)

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Perbaikan Cobol      | Wajib | ✅ |
| Konversi Rai -> IDR  | Bonus | [Konversi](#konversi-rai-ke-idr) |
| Deploy Kubernetes       | Bonus | [Deploy](#kubernetes) |
| Bunga Otomatis        | Bonus | [Bunga](#perhitungan-bunga-otomatis) |
| Reverse Proxy       | Bonus | [Reverse Proxy](#reverse-proxy) |
| Domain     | Bonus | ❌ |


## Direktori
- `hasil` - menyimpan hasil pekerjaan (perbaikan kode)
- `sumber` - menyimpan sumber kode soal original (sebelum perbaikan)
- `manifest` - menyimpan file manifest untuk deployment kubernetes

<br>

## Perbaikan
### Dockerfile
- Tambah 2 line berikut.
```
    COPY requirements.txt ./
    RUN pip install --no-cache-dir -r requirements.txt
```
-  Tambah `gnucobol4` ke `apt-get-install` sebagai compiler Cobol.
- Ubah `EXPOSE` dari 5000 menjadi 8000 (karena `.html` menggunakan 8000)
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
- Ukuran buffer file diubah sesuai panjang format yang diinginkan (misal: 15 -> 18).
- Logika `PROCESS-RECORDS` berhenti ketika ada *match found*, ganti `PERFORM UNTIL MATCH-FOUND = "Y"`menjadi `PERFORM FOREVER`
Semua langkah diatas disertakan dengan pembuatan variabel baru jika dibutuhkan.

>[!note]
> Request yang dapat dilakaukan pada *banking app* sebagai berikut:
>NEW - membuat akun baru
>DEP - deposit (mengurangi balance)
>WDR - withdrawal (menambah balance)
>BAL - balance inquiry (melihat balance)

<br>
<br>

## Bonus
### Konversi Rai ke IDR
Data yang disimpan pada `input.txt` dan `accounts.txt` menggunakan mata uang Rai Stones, sedangkan yang disimpan pada `output.txt` telah dikonversi menjadi Rupiah. Karena hanya request BAL yang menghasilkan output nominal, maka saya hanya merubah kode bagian itu. Update ukuran variabel sehingga cukup untuk menyimpan angka maksimum Rai Stone (999,999.99 * 120,000,000.00 = 119,999,998,800,000, 15 digit),  lalu sebelum menyimpan ke `OUT-RECORD`, nominal dikalikan dengan *conversion rate*.

<br>

### Kubernetes
- Menggunakan Minikube


Untuk menjalankan secara lokal, dari dalam direktori root repo ini, jalankan perintah-perintah berikut sesuai urutan
```
    minikube start
    eval $(minikube -p minikube docker-env)
    docker build -t cobol-app ./hasil
    kubectl apply -f manifest/deployment.yaml -f manifest/service.yaml -f manifest/pvc.yaml
```
Kemudian masing-masing pada terminal berbeda
```
    minikube service cobol-service -> mengekspos service agar bisa dibuka
    kubectl port-forward service/cobol-service 8000:80 -> agar frontend bisa interaksi degnan backend (python)
```

**NOTE**: Untuk saat ini, deployment masih untuk lokal saja.

<br>

### Perhitungan Bunga Otomatis
Dibuat dalam bentuk infinite loop yang memanggil sleep(23) sebelum memproses ulang perhitungan bunga. <br>

#### Docker
Jalankan seperti biasa, program menghitung bunga akan berjalan sebagai *background task*. Pada Dockerfile dijalankan dengan perintah berikut:
`CMD  ./main --apply-interest & exec uvicorn app:app --host 0.0.0.0 --port 8000` 

#### Kubernetes
Jalankan kubernetes sesuai instruksi pada [Kubernetes](./README.md#L59) <br>

Untuk membandingkan file pada kedua *container*, gunakan *command* berikut
```
    kubectl exec <POD_NAME> -c webapp -- cat accounts.txt
    kubectl exec <POD_NAME> -c interest -- cat accounts.txt
```
Untuk memonitor keberjalanannya perhitungan *interest*, gunakan *command* berikut
```
    kubectl logs <POD_NAME> -c interest
```

Atau bisa menggunakan web app dengan meng-*query* BAL berkali-kali dan melihat perubahannya.

Cara saya mengerjakan untuk Kubernetes adalah dengan membuat dua *container* pada satu pod, yang masing-masing menjalankan webapp dan perhitungan bunga secara terpisah. Lalu kedua *container* ini akan mengakses satu file yang sama yang terhubung melalui *symbolic link*. Detailnya bisa dilihat pada `manifest/deployment.yaml` dan `manifest/pvc.yaml`

<br>

### Reverse Proxy 
Implementasinya pada Kubernetes adalah dengan membuat pod baru sebagai *proxy* server, yang akan meneruskan *traffic* eksternal ke *port* 8000 pada address webapp.

Deploy pod menggunakan
```
    kubectl apply -f manifest/nginx-deployment.yaml -f manifest/nginx-service.yaml -f manifest/nginx-config.yaml
```
Matikan *port forwarding* sebelumnya dan gunakan perintah berikut untuk menjalankan *port forwarding* IP *proxy* server.
```
    kubectl port-forward service/nginx-service 8000:80
```

Dan jalankan `kubectl get pods -o wide` untuk melihat IP address dari webapp dan proxy server.

**NOTE**: Sama seperti *deployment* Kubernetes, *reverse proxy* ini hanya bisa lokal.