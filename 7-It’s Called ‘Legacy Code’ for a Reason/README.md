# It’s Called ‘Legacy Code’ for a Reason
Cobol-cobolan

## Tabel Spesifikasi

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