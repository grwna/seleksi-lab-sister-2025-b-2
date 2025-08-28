# It’s Called ‘Legacy Code’ for a Reason
Cobol-cobolan

## Spesifikasi
"Telah disediakan sebuah “[legacy code](https://drive.google.com/file/d/1sbb-t_i58x8zHaV5B-3ukWrgpWrqjej0/view?usp=sharing)” cobol suatu banking namun seorang intern telah merusak main.cob dan Dockerfile tanpa sengaja. Perbaiki main.cob serta Dockerfile agar program banking dapat berjalan dengan benar - input.txt, output.txt, dan accounts.txt boleh diubah formatnya dengan syarat nomor akun yang terdapat pada accounts.txt serta jumlah uangnya masih sama. DILARANG MENGUBAH FILE PYTHON SERTA HTML YANG DISEDIAKAN."

## Daftar Isi
- [Perbaikan](#perbaikan)
- [Bonus](#bonus)

## Tabel Spesifikasi
| Spesifikasi          | Sifat | Status |
| -------------------- | ----- | ------ |
| Perbaikan Cobol      | Wajib | ✅ |
| Konversi Rai -> IDR  | Bonus | ✅|
| Deploy Kubernetes       | Bonus | ✅ |
| Bunga Otomatis        | Bonus | ✅ |
| Reverse Proxy       | Bonus | ✅ |
| Domain     | Bonus | ❌ |


## Direktori
- `src` - menyimpan hasil pekerjaan (perbaikan kode)
- `original` - menyimpan sumber kode soal original (sebelum perbaikan)
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
>```
>   docker build -t cobol-app ./src
>   docker run --rm -p 8000:8000 cobol-app
>```

### main.cob
- Pada paragraf `APPLY-ACTION` logika withdrawal dan deposit terbalik.
- Pada paragraf `FINALIZE`, file output hanya dibuka lalu ditutup, tidak dituliskan. Tambah `WRITE OUT-RECORD` di antara line membuka dan line menutup
- Pada beberapa titik, ada kesalahan text slicing (ie. 1:5, 6:3), sesuaikan dengan panjang sebenarnya.
- Ukuran buffer file diubah sesuai panjang format yang diinginkan (misal: 15 -> 18).
- Logika `PROCESS-RECORDS` berhenti ketika ada *match found*, ganti `PERFORM UNTIL MATCH-FOUND = "Y"`menjadi `PERFORM FOREVER`

Semua langkah diatas disertakan dengan pembuatan variabel baru jika dibutuhkan.

Ini cukup untuk membuat aplikasi fungsional, namun ada perubahan lanjutan yang saya lakukan untuk implementasi fitur-fitur berikutnya.

>[!note]
> Request yang dapat dilakaukan pada *banking app* sebagai berikut: <br>
>NEW - membuat akun baru <br>
>DEP - deposit (mengurangi balance) <br>
>WDR - withdrawal (menambah balance) <br>
>BAL - balance inquiry (melihat balance) <br>

<br>
<br>

## Bonus
### Konversi Rai ke IDR
Data yang disimpan pada `input.txt` dan `accounts.txt` menggunakan mata uang Rai Stones, sedangkan yang disimpan pada `output.txt` telah dikonversi menjadi Rupiah. Karena hanya request BAL yang menghasilkan output nominal, maka saya hanya merubah kode bagian itu. Update ukuran variabel sehingga cukup untuk menyimpan angka maksimum Rai Stone (999,999.99 * 120,000,000.00 = 119,999,998,800,000, 15 digit),  lalu sebelum menyimpan ke `OUT-RECORD`, nominal dikalikan dengan *conversion rate*.

>[!note]
>Pada web, output balance ditampilkan dalam IDR, namun inputnya tetap dalam RAI.

<br>

### Deployment Kubernetes
Deployment dilakukan pada Microsoft Azure menggunakan k3s. 
Dapat diakses pada tautan berikut:
- [20.255.211.191:8000](20.255.211.191:8000)
- [grwna-app.eastasia.cloudapp.azure.com:8000](grwna-app.eastasia.cloudapp.azure.com:8000)

Ada dua pod pada cluster, satu untuk aplikasi utama, dan satu lagi untuk Nginx. Untuk pod aplikasi utama, ada dua containter, satu untuk aplikasi web, dan satu lagi untuk menjalankan perhitungan bunga.

Untuk detail lebih lanjut tentang deployment, dapat melihat file-file manifest pada direktori `manifest/`



#### Menjalankan lokal menggunakan k3d <br>
Install k3d dengan
```bash
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

Lalu jalankan perintah berikut:
```bash
    docker build -t cobol-app ./src
    k3d cluster create <nama_cluster> -p "8000:8000@loadbalancer"
    k3d image import cobol-app -c <nama_cluster>
    kubectl apply -f ./manifest
```

Lalu pada browser Anda, buka alamat `localhost:8000`


<br>

### Perhitungan Bunga Otomatis
Dibuat dalam bentuk infinite loop yang memanggil sleep(23) sebelum memproses ulang perhitungan bunga. <br>
Setelah bunga dihitung, transaksinya dicatat sebagai INT pada `accounts.txt`. *Interest rate* di-*hardcode* dengan nilai 0.25%

#### Docker
Jalankan seperti biasa, program menghitung bunga akan berjalan sebagai *background task*. Pada Dockerfile dijalankan dengan perintah berikut:
`CMD  ./main --apply-interest & exec uvicorn app:app --host 0.0.0.0 --port 8000` 

#### Kubernetes
Cara saya mengerjakan untuk Kubernetes adalah dengan membuat satu *container* tambahan pada pod untuk menjalankan perhitungan, sehingga webapp masih dapat berjalan bersamaan dengan perhitungan bunga. Kedua *container* ini akan mengakses satu file yang sama yang terhubung melalui *symbolic link*. Dua kontainer tersebut bisa mengakses satu file karena adanya PVC. Detailnya dapat dilihat pada `manifest/pvc.yaml` 

Jalankan kubernetes sesuai instruksi pada bagian [Deployment Kubernetes](#deployment-kubernetes) <br>
Gunakan `kubectl get pods` untuk mendapatkan `POD_NAME` 

Untuk membandingkan file pada kedua *container*, gunakan *command* berikut:
```
    kubectl exec <POD_NAME> -c webapp -- cat accounts.txt
    kubectl exec <POD_NAME> -c interest -- cat accounts.txt
```
Untuk memonitor keberjalanannya perhitungan bunga, gunakan *command* berikut:
```
    kubectl logs <POD_NAME> -c interest
```

Atau bisa menggunakan web app dengan meng-*query* BAL berkali-kali dan melihat perubahannya.


>[!note]
> Interest rate di-hardcode dengan 0.25% <br>
>Jika nilai RAI cukup kecil, interest akan terhitung menjadi 0.


<br>


### Reverse Proxy 
Implementasi *reverse proxy* saya lakukan dengan membuat satu pod baru yang bertindak sebagai *proxy* server, yang akan meneruskan *traffic* eksternal ke *port* 8000 pada address webapp. Ketika user mengakses alamat deployment, permintaannya akan diteruskan ke *service* Nginx. Nginx kemudian meneruskannya ke Service yang menjalankan webapp pada alamat `http://cobol-service:8000`, di mana alamat tersebut akan disesuaikan dengan alamat runtime sebenarnya secara otomatis.