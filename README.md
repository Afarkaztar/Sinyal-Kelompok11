# Projek Akhir: Ekstraksi Denyut Jantung (BPM) dari Sinyal ECG

**Mata Kuliah:** Sinyal dan Sistem Kontrol Elektronik (Semester 3)  
**Platform:** MATLAB  

---

## 1. Struktur File Projek (Ringkas & Modular)

Seluruh kode dirancang agar **tidak terpecah ke banyak subfolder** dan cukup dijalankan dari **satu file utama** (`main_ecg.m`), namun tetap rapi secara fungsi:

```text
Projek/
├── main_ecg.m       # [SKRIP UTAMA] Klik "Run" -> Input Nama & BPM -> Otomatis proses & simpan
├── generate_ecg.m   # Fungsi pembangkit sinyal ECG sintetis (P-Q-R-S-T) + 3 jenis noise biomedis
├── filter_ecg.m     # Fungsi Band-Pass Filter (0.5-40 Hz), Notch Filter (50 Hz), FFT, & hitung SNR
├── detect_bpm.m     # Fungsi deteksi puncak R (R-Peak), RR-Interval, BPM, Error (%), & Klasifikasi
├── results/         # Folder hasil yang otomatis terpisah per Nama Penguji/Pasien
│   ├── <Nama_1>/    # Berisi 4 grafik (.png) & ringkasan_hasil.txt milik Nama_1
│   └── <Nama_2>/    # Berisi 4 grafik (.png) & ringkasan_hasil.txt milik Nama_2
└── README.md        # Panduan projek, rumus inti, dan pembagian tugas 4 anggota
```

### Cara Menjalankan
1. Buka MATLAB dan arahkan *Current Folder* ke direktori `Projek` ini.
2. Buka file `main_ecg.m` lalu klik tombol **Run** (atau ketik `main_ecg` di *Command Window*).
3. Di *Command Window*, ketikkan input yang diminta:
   - **Masukkan Nama Pasien / Penguji** (contoh: `Afarik` atau `Budi`)
   - **Masukkan Detak Jantung / BPM** (contoh: `85`, `55`, `115`, atau tekan *Enter* untuk default `75`)
   - **Masukkan Durasi Rekaman (detik)** (contoh: `10`, atau tekan *Enter* untuk default `10`)
4. Program akan otomatis:
   - Membuat folder khusus sesuai nama penguji di dalam `results/<Nama>/`.
   - Menampilkan hasil evaluasi SNR, RR-Interval, BPM, dan Tabel Evaluasi di *Command Window*.
   - Menyimpan 4 gambar grafik resolusi tinggi (`.png`) beserta file laporan `ringkasan_hasil.txt` ke dalam folder `results/<Nama>/`.

---

## 2. Substansi Materi Sinyal & Sistem yang Tercakup

1. **Pembangkitan Sinyal & Kriteria Sampling (`generate_ecg.m`)**
   - Menggunakan frekuensi sampling $f_s = 500\text{ Hz}$ (Frekuensi Nyquist $f_N = 250\text{ Hz}$), jauh di atas komponen frekuensi maksimum ECG ($\approx 40\text{ Hz}$) dan interferensi jala-jala listrik ($50\text{ Hz}$).
   - Gelombang **P-Q-R-S-T** dimodelkan dengan superposisi fungsi Gaussian:
     $$x_{\text{ECG}}(t) = \sum_{k} \sum_{i \in \{P,Q,R,S,T\}} a_i \exp\left(-\frac{(t - (t_k + \tau_i))^2}{2 b_i^2}\right)$$
   - Tiga komponen gangguan (*noise*) realistis:
     - **Baseline Wander ($0.3\text{ Hz}$):** Akibat pergerakan dada saat respirasi/bernapas.
     - **Powerline Interference ($50\text{ Hz}$):** Akibat induksi elektromagnetik jala-jala listrik PLN.
     - **White Gaussian Noise (AWGN):** Akibat derau termal sensor elektronik dan aktivitas otot (EMG).

2. **Analisis Spektrum FFT & Desain Filter Digital (`filter_ecg.m`)**
   - **Fast Fourier Transform (FFT):** Memetakan sinyal dari domain waktu ke domain frekuensi untuk melihat lonjakan frekuensi gangguan di $0.3\text{ Hz}$ dan $50\text{ Hz}$.
   - **Band-Pass Filter (BPF) Butterworth ($0.5\text{ Hz} - 40\text{ Hz}$):** Membuang *baseline wander* di bawah $0.5\text{ Hz}$ serta derau frekuensi tinggi di atas $40\text{ Hz}$.
   - **Notch Filter / Band-Stop ($48.5\text{ Hz} - 51.5\text{ Hz}$):** Meredam tajam frekuensi listrik PLN $50\text{ Hz}$.
   - **Zero-Phase Filtering (`filtfilt`):** Pemfilteran dilakukan maju-mundur agar tidak terjadi pergeseran fasa (*zero phase distortion*), sehingga posisi waktu puncak R tetap presisi.

3. **Deteksi Puncak R & Ekstraksi Denyut Jantung (`detect_bpm.m`)**
   - Menggunakan *adaptive thresholding* ($45\%$ dari puncak maksimum sinyal terfilter) dan jarak minimum antar puncak (*refractory period* $0.25\text{ detik}$ atau $250\text{ ms}$) menggunakan `findpeaks`.
   - Rumus **RR-Interval** dan **BPM (Beats Per Minute)**:
     $$\text{RR}_n = t_{R(n+1)} - t_{R(n)}, \qquad \text{BPM} = \frac{60}{\overline{\text{RR}}}$$
   - Klasifikasi klinis:
     - **Bradikardia:** $< 60\text{ BPM}$
     - **Normal:** $60 - 100\text{ BPM}$
     - **Takikardia:** $> 100\text{ BPM}$

---

## 3. Pembagian Tugas Kelompok (4 Orang — 1 Coder + 3 Tim Laporan & Analisis)

Karena seluruh pemrograman sudah disatukan agar konsisten, berikut pembagian peran yang adil untuk 4 anggota:

| Anggota | Peran Utama | Detail Tugas |
| :--- | :--- | :--- |
| **Anggota 1** | **Lead Programmer & Demo MATLAB** | Menjalankan, memelihara, dan mendemokan kode MATLAB (`main_ecg.m` dkk.) saat presentasi. Menjelaskan alur algoritma kode dan menjawab pertanyaan teknis kodingan. |
| **Anggota 2** | **Teori Dasar & Pemodelan Sinyal (Bab 1 & Bab 2)** | Menyusun Latar Belakang, Tujuan, serta Landasan Teori di laporan: fisiologi gelombang ECG (P-Q-R-S-T), teorema sampling Nyquist, dan karakteristik 3 jenis *noise* ECG (mengacu pada `generate_ecg.m`). |
| **Anggota 3** | **Metodologi Sistem & Desain Filter (Bab 3)** | Menyusun diagram blok sistem, menjelaskan cara kerja FFT, pemilihan frekuensi *cutoff* Band-Pass Filter ($0.5-40\text{ Hz}$), Notch Filter ($50\text{ Hz}$), alasan pemakaian `filtfilt`, dan algoritma deteksi R-Peak (`filter_ecg.m` & `detect_bpm.m`). |
| **Anggota 4** | **Analisis Hasil, Evaluasi & Slide PPT (Bab 4 & Bab 5)** | Memasukkan ke-4 grafik dari folder `results/` dan tabel pengujian 3 skenario (Bradikardia, Normal, Takikardia) ke dalam laporan. Menganalisis peningkatan SNR & akurasi BPM, menyusun Kesimpulan, serta mendesain slide presentasi (PPT). |
