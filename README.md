# Pompa Asia — Website Katalog Pompa Industri

Website statis (HTML + CSS + JavaScript murni, tanpa framework/build tools) untuk menampilkan katalog pompa industri.
Siap di-hosting di **Cloudflare Pages** dengan domain **https://pompa.my.id**.

---

## 1. Struktur Folder

```
pompa-asia/
├── index.html                 # Halaman utama (struktur & konten)
├── style.css                  # Seluruh tampilan (tema biru tua / industrial)
├── script.js                  # Logika: fetch JSON, search, filter, modal
├── favicon.svg                # Ikon situs di tab browser
├── robots.txt                 # Instruksi untuk mesin pencari
├── sitemap.xml                # Peta situs untuk Google
├── _headers                   # Header keamanan & cache (khusus Cloudflare Pages)
├── _redirects                 # Redirect www → apex (khusus Cloudflare Pages)
├── .gitignore                 # Jangan commit *.bak, .DS_Store, dll.
├── data/
│   └── pompa.json             # ← DATABASE katalog (edit file ini untuk tambah pompa)
├── tools/
│   ├── replace-domain.ps1     # Ganti domain otomatis (Windows / PowerShell)
│   └── replace-domain.sh      # Ganti domain otomatis (macOS / Linux)
└── assets/
    └── img/
        ├── og-cover.png       # Gambar preview saat link dibagikan (1200×630)
        ├── logo.png           # Logo untuk JSON-LD Organization (512×512)
        ├── placeholder-centrifugal.svg
        ├── placeholder-submersible.svg
        ├── placeholder-positive-displacement.svg
        ├── placeholder-booster.svg
        └── placeholder-pompa.svg   # Gambar cadangan bila gambar gagal dimuat
```

---

## 2. Menjalankan di Komputer Lokal

Karena data diambil dengan `fetch()`, halaman **tidak bisa** dibuka dengan double-click (`file://`).
Gunakan web server sederhana:

```bash
# Pilihan 1 — Python (biasanya sudah terpasang)
python -m http.server 8080

# Pilihan 2 — Node.js
npx serve .

# Pilihan 3 — VS Code
# Install ekstensi "Live Server" → klik kanan index.html → Open with Live Server
```

Lalu buka <http://localhost:8080>.

---

## 3. Cara Menambah / Mengubah Data Pompa

Semua data ada di **`data/pompa.json`** berupa array JSON. Cukup tambahkan satu objek baru:

```json
{
  "id": 9,
  "nama": "Pompa Centrifugal CP-300",
  "kategori": "Centrifugal",
  "kapasitas": "200 m³/h",
  "head": "55 m",
  "daya": "45 kW",
  "gambar": "assets/img/placeholder-centrifugal.svg",
  "deskripsi": "Pompa centrifugal kapasitas tinggi untuk kebutuhan industri besar.",
  "merek": "Asia Pump",
  "aplikasi": "Distribusi air industri, cooling tower"
}
```

### Aturan singkat

| Field        | Wajib | Keterangan                                                        |
|--------------|-------|-------------------------------------------------------------------|
| `id`         | ✅    | Angka unik, jangan dipakai ulang (misal lanjutkan dari nomor besar) |
| `nama`       | ✅    | Nama produk yang tampil di kartu dan modal                        |
| `kategori`   | ✅    | **Otomatis muncul** di dropdown filter (tidak perlu edit HTML)     |
| `kapasitas`  | ✅    | Contoh: `"50 m³/h"`                                               |
| `head`       | ✅    | Contoh: `"30 m"`                                                  |
| `daya`       | ✅    | Contoh: `"15 kW"`                                                 |
| `gambar`     | ✅    | Path lokal (`assets/img/...`) atau URL gambar eksternal           |
| `deskripsi`  | ✅    | Penjelasan singkat 1–2 kalimat                                    |
| `merek`      | ➖    | Opsional — disembunyikan otomatis bila kosong                     |
| `aplikasi`   | ➖    | Opsional — disembunyikan otomatis bila kosong                     |

**Tips aman saat mengedit JSON:**

1. Setiap objek dipisahkan **koma**, objek terakhir **tanpa** koma.
2. Gunakan tanda kutip ganda `"` (bukan kutip tunggal).
3. Simpan file sebagai **UTF-8** agar karakter `³` dan `·` tidak rusak.
4. Validasi cepat di <https://jsonlint.com> bila halaman menampilkan pesan error.
5. Gunakan format angka Indonesia dengan koma desimal di dalam string, misal `"7,5 kW"`.

### Mengganti gambar asli

1. Simpan foto produk ke `assets/img/` (disarankan `.webp` atau `.jpg`, lebar ±800 px, ukuran < 150 KB).
2. Ubah nilai `"gambar"` menjadi `"assets/img/nama-file.webp"`.

---

## 4. Deploy ke Cloudflare Pages

### 4.1 Upload proyek ke GitHub

```bash
cd "pompa asia"
git init
git add .
git commit -m "Website katalog Pompa Asia"
git branch -M main
git remote add origin https://github.com/USERNAME/pompa-asia.git
git push -u origin main
```

> `_headers` dan `robots.txt` ikut ter-upload — keduanya memang harus berada di root.

### 4.2 Buat project di Cloudflare Pages

1. Login ke <https://dash.cloudflare.com> → menu **Workers & Pages** → **Create** → tab **Pages** → **Connect to Git**.
2. Pilih repository **pompa-asia** → **Begin setup**.
3. Isi konfigurasi build:

   | Pengaturan              | Nilai                     |
   |-------------------------|---------------------------|
   | Project name            | `pompa-asia`              |
   | Production branch       | `main`                    |
   | Framework preset        | **None**                  |
   | Build command           | *(kosongkan)*             |
   | Build output directory  | `/`  *(root proyek)*      |

4. Klik **Save and Deploy**. Setelah selesai, situs tersedia di
   `https://pompa-asia.pages.dev`.

> **Alternatif tanpa Git:** menu **Create → Pages → Upload assets**, lalu drag-and-drop seluruh isi folder
> (kecuali folder `.git`). Cocok untuk update cepat, tapi setiap perubahan harus di-upload manual.

### 4.3 Setiap kali data berubah

Cukup edit `data/pompa.json` → `git commit` → `git push`.
Cloudflare Pages otomatis build & deploy ulang dalam ±30 detik.

---

## 5. Menghubungkan Domain `pompa.my.id`

### Langkah A — Tambahkan domain di project Pages

1. Buka project **pompa-asia** → tab **Custom domains** → **Set up a custom domain**.
2. Masukkan `pompa.my.id` → **Continue**.
3. Ulangi untuk `www.pompa.my.id` (opsional tetapi disarankan).

### Langkah B — Konfigurasi DNS

**Kasus 1 — Domain sudah memakai nameserver Cloudflare (paling mudah):**
Cloudflare otomatis membuat record DNS yang diperlukan. Cukup klik **Activate domain**.

**Kasus 2 — Domain masih di registrar lain (misal Namecheap, Rumahweb, Domainesia):**

- Untuk `www` → tambahkan record **CNAME**:
  `www` → `pompa-asia.pages.dev`
- Untuk domain utama `pompa.my.id` (apex) → banyak registrar tidak mendukung CNAME di apex.
  Solusi paling rapi: **pindahkan nameserver domain ke Cloudflare** (gratis):
  1. Di dashboard Cloudflare: **Add a site** → masukkan `pompa.my.id` → pilih paket **Free**.
  2. Cloudflare memberi 2 nameserver, contoh: `ada.ns.cloudflare.com` dan `bob.ns.cloudflare.com`.
  3. Di panel registrar, ganti nameserver domain ke dua alamat tersebut.
  4. Tunggu propagasi (5 menit – 24 jam), lalu ulangi Langkah A.

### Langkah C — Verifikasi

- Status domain di tab **Custom domains** harus **Active** (sertifikat SSL diterbitkan otomatis, ±5–15 menit).
- Buka `https://pompa.my.id` → pastikan gembok SSL muncul dan katalog tampil.
- Aktifkan **Always Use HTTPS** di menu **SSL/TLS → Edge Certificates**.

### Langkah D — Redirect `www` → apex

File `_redirects` sudah disiapkan berisi:

```
https://www.pompa.my.id/*  https://pompa.my.id/:splat  301
```

Aktif hanya setelah `www.pompa.my.id` ditambahkan sebagai custom domain.
Tanpa redirect ini, `www` dan non-`www` menyajikan konten yang sama (duplikat);
`<link rel="canonical">` tetap menolong, tetapi 301 jauh lebih rapi.

### Jika suatu saat domain berubah lagi

Jangan edit manual satu per satu — pakai skrip yang sudah ada:

```bash
# DRY-RUN dulu (tidak menulis apa pun)
.\tools\replace-domain.ps1                 # Windows
./tools/replace-domain.sh                  # macOS / Linux

# Setelah yakin, eksekusi (otomatis membuat backup .bak)
.\tools\replace-domain.ps1 -Execute
./tools/replace-domain.sh --execute
```

Skrip hanya mengganti string persis `pompa.<domain>` (case-sensitive), jadi nama brand
"Pompa Asia" tidak tersentuh. Jangan lupa perbarui `<lastmod>` di `sitemap.xml`.

---

## 6. Tips SEO Dasar

### Sudah diterapkan di `index.html`

- `<title>` unik & mengandung kata kunci utama ("Katalog Pompa Industri").
- `<meta name="description">` ±155 karakter yang menjelaskan isi halaman.
- `<link rel="canonical">` mencegah konten duplikat (`www` vs non-`www`).
- Open Graph + Twitter Card → link terlihat menarik saat dibagikan di WhatsApp/LinkedIn.
- Structured data **JSON-LD** (`WebSite` + `Organization`) → membantu rich result Google.
- Gambar memakai atribut `width`/`height` + `loading="lazy"` → mencegah layout shift.
- Heading hierarkis (`h1` → `h2` → `h3`), `alt` pada gambar, dan `aria-label` untuk aksesibilitas.

### Yang perlu Anda lakukan setelah live

1. **Google Search Console** — tambahkan properti `https://pompa.my.id`, verifikasi via DNS Cloudflare,
   lalu submit `https://pompa.my.id/sitemap.xml`.
2. **Bing Webmaster Tools** — bisa impor langsung dari Google Search Console.
3. **Perbarui `lastmod` di `sitemap.xml`** setiap kali katalog berubah.
4. **Isi kontak asli** (`info@pompa.my.id`, nomor WhatsApp, alamat) di `index.html` dan JSON-LD.
5. **Percepat loading**: konversi foto ke `.webp`, targetkan skor Lighthouse > 90.
6. **Tambah konten teks** bila ingin peringkat lebih baik — mesin pencari menyukai halaman dengan
   penjelasan teknis (misal panduan memilih pompa berdasarkan head & kapasitas).
7. **Jangan** mengisi `keywords` dengan spam; meta keywords sudah diabaikan Google (aman dibiarkan).

### Analitik ringan (opsional)

Cloudflare Web Analytics (gratis, tanpa cookie): **Analytics & Logs → Web Analytics → Add a site**,
lalu tempel snippet `<script defer src='https://static.cloudflareinsights.com/beacon.min.js' ...></script>`
sebelum `</body>`.

---

## 7. Kustomisasi Cepat

| Ingin mengubah           | Lokasi                                                                 |
|--------------------------|------------------------------------------------------------------------|
| Warna tema               | `style.css` bagian **1. VARIABEL DESAIN** (`:root`)                    |
| Teks hero & tagline      | `index.html` elemen `.hero__title` dan `.hero__tagline`                |
| Email / WhatsApp / alamat| `index.html` (section `#kontak`, footer, dan JSON-LD di `<head>`)      |
| Judul & deskripsi SEO    | `<title>` dan `<meta name="description">` di `index.html`              |
| Teks footer              | `index.html` elemen `.site-footer`                                     |
| Urutan kartu             | Urutan objek di `data/pompa.json`                                      |

### Cara kerja pencarian

Kata kunci dicocokkan (tidak case-sensitive) terhadap `nama`, `kategori`, `merek`, `deskripsi`, dan `aplikasi`.
Filter kategori dan kata kunci bisa dikombinasikan. URL ikut diperbarui
(`?q=centrifugal&kategori=Booster`) sehingga hasil pencarian bisa dibagikan atau di-bookmark.

---

## 8. Catatan Teknis

- **Tanpa backend**: seluruh data berasal dari `data/pompa.json` via `fetch()`.
- **Escape HTML**: semua teks dari JSON di-escape sebelum dirender (`escapeHtml()`), mencegah HTML injection.
- **Aksesibilitas modal**: `role="dialog"`, `aria-modal`, focus trap, tutup dengan `Esc`, dan fokus kembali ke tombol asal.
- **Fallback gambar**: jika `gambar` gagal dimuat, otomatis memakai `assets/img/placeholder-pompa.svg`.
- **`_headers`** hanya berlaku di Cloudflare Pages; di hosting lain file ini diabaikan (tidak error).
- Lisensi gambar placeholder: dibuat sendiri (SVG), bebas dipakai dan dimodifikasi.
