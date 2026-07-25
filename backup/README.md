# Panduan Backup & Restore Infrastruktur

Dokumen ini menjelaskan alur backup otomatis serta panduan lengkap cara melakukan **Restore** dari file arsip yang telah dihasilkan oleh `autobackup.sh`.

---

## 📦 Apa Saja yang Di-Backup?

Script `autobackup.sh` akan menghasilkan 1 file kompresi lengkap di folder `/mnt/data/backups/` dengan format nama `infra-backup-<YYYY-MM-DD-HHMMSS>.tar.gz`.

Jika Anda mengekstrak file tersebut, terdapat 3 komponen utama di dalamnya:
1. `mysql_alldbs_*.sql.gz` — Dump seluruh database MySQL (termasuk user & privileges).
2. `npm_data_*.tar.gz` — Data reverse proxy NPM dan sertifikat SSL Let's Encrypt.
3. `env_*.backup` — Salinan file rahasia `.env` dari repositori infra.

---

## 🛠️ Cara Restore dari Backup (Langkah-demi-Langkah)

### 1. Ekstrak Arsip Backup
Masuk ke folder backup dan ekstrak file tar.gz yang ingin dimuat ulang:

```bash
cd /mnt/data/backups
# Ekstrak file ke folder temporary
tar -xvf infra-backup-2026-07-25-144334.tar.gz

# Masuk ke folder hasil ekstrak
cd infra-backup-2026-07-25-144334
```

---

### 2. Restore Database MySQL

Ada dua cara untuk mengembalikan data MySQL: melalui Terminal (untuk memulihkan seluruh server secara cepat) atau melalui GUI HeidiSQL (sangat cocok untuk memulihkan tabel atau 1 database spesifik).

#### 🔹 Metode A: Lewat Terminal (Sangat Cepat & Tanpa Warning Password)
Cara ini menginjeksi seluruh perintah SQL ke container MySQL secara langsung:

```bash
# 1. Decompress (ekstrak) file .sql.gz
gzip -d mysql_alldbs_*.sql.gz

# 2. Injeksi file SQL ke container (Gantikan PASSWORD_ROOT dengan password root asli dari .env Anda)
cat mysql_alldbs_*.sql | docker exec -i -e MYSQL_PWD="PASSWORD_ROOT" infra-mysql mysql -u root

# (Jika sukses, perintah akan selesai tanpa pesan error)
```

#### 🔹 Metode B: Lewat HeidiSQL (GUI)
Cara ini sangat ramah untuk developer jika ingin memonitor progress eksekusi query atau hanya ingin meninjau data tertentu:

1. **Download File**: Ambil file `mysql_alldbs_*.sql.gz` ke laptop/PC Anda, lalu ekstrak menggunakan **WinRAR** / **7-Zip** hingga berakhiran `.sql`.
2. **Koneksi SSH Tunnel**: Buka **HeidiSQL**, pilih sesi koneksi Anda (Metode SSH Tunnel -> MySQL Host `127.0.0.1` port `3306`), lalu klik **Open**.
3. **Load SQL File**: 
   - Pada menu bar atas di HeidiSQL, klik **File** → **Load SQL file...**
   - Pilih file `.sql` yang baru saja ditaruh di PC Anda.
   - Jika ada notifikasi *“File size is large. Read query directly from file?”*, pilih **Yes** agar memori komputer tidak terbebani.
4. **Eksekusi**:
   - Klik tombol **Run / Execute** (Ikon tombol Play biru atau tekan `F9` di keyboard).
   - Tunggu hingga proses berjalan. HeidiSQL akan membuatkan kembali seluruh struktur database dan mengimpor isinya!

---

### 3. Restore Konfigurasi Nginx Proxy Manager (NPM & SSL)

Jika konfigurasi domain, SSL, atau proxy NPM rusak/hilang, Anda bisa mematikannya sesaat dan menimpa volumenya dari file arsip:

```bash
# 1. Matikan sementara container NPM agar data aman ditimpa
docker stop infra-nginx-proxy-manager

# 2. Ekstrak data NPM (domain & sertifikat SSL Let's Encrypt) kembali ke Docker Volume
docker run --rm \
    -v infra_npm-data:/data \
    -v infra_npm-letsencrypt:/etc/letsencrypt \
    -v "$(pwd):/backup" \
    alpine tar xzf /backup/npm_data_2026-07-25-144334.tar.gz -C /

# 3. Nyalakan kembali container NPM
docker start infra-nginx-proxy-manager
```
*(Ganti nama file `npm_data_*.tar.gz` sesuai dengan file di folder backup Anda)*.

---

### 4. Restore File `.env`

Jika file konfigurasi rahasia Anda hilang, cukup saling kembali salinan file env:
```bash
cp env_*.backup /srv/workspace/infra/.env
```

---
> 💡 **Saran Opsional**: Setelah proses restore selesai dan terverifikasi aman, hapus kembali folder hasil ekstrak di `/mnt/data/backups/infra-backup-*` agar menghemat ruang penyimpan disk (file asal yang berakhiran `.tar.gz` biarkan saja tetap ada).
