# Shared Infrastructure (Multi-App)

Repositori ini menyimpan infrastruktur pusat untuk seluruh aplikasi yang berjalan di server ini.

> **PENTING:** Panduan ini dibagi menjadi **2 Part Utama**:
> - **Part 1:** Instalasi Infrastruktur (MySQL Server & Proxy). Cukup dilakukan sekali saja pada server.
> - **Part 2:** Instalasi Aplikasi (misal: `master-gambar`). Dilakukan setiap kali Anda ingin menambah aplikasi baru ke dalam server.

## Komponen
1. **MySQL Server (v9.7.0)**: Berjalan secara internal tanpa membuka port ke publik demi keamanan.
2. **Nginx Proxy Manager**: Berfungsi mengatur domain, routing *traffic* ke aplikasi yang tepat, serta mengurus sertifikat SSL secara otomatis.

## Network
Network utama bernama `rekayasa-network`. Semua aplikasi harus menempel (attach) ke network ini di dalam `docker-compose.prod.yml` masing-masing agar bisa terhubung ke MySQL dan Nginx Proxy Manager.

---

## Part 1: Instalasi Infrastruktur

Langkah-langkah berikut hanya perlu dijalankan **satu kali** saat server baru pertama kali di-setup.

### 1. Persiapan Workspace

Buat struktur folder workspace utama (termasuk folder `apps` dan `logs`) dan atur permission-nya di server:
```bash
sudo mkdir -p /srv/workspace/apps
sudo mkdir -p /srv/workspace/logs
sudo chown -R "$(whoami)":"$(whoami)" /srv/workspace
ls -ld /srv/workspace
```

### 2. Clone Repositori Infra

Clone repositori infrastruktur ke dalam workspace:
```bash
cd /srv/workspace
git clone https://github.com/Zenalghi/rekayasa-infra infra
```

### 3. Copy & Edit Konfigurasi Infra

Masuk ke direktori infra dan siapkan konfigurasi password:
```bash
cd /srv/workspace/infra
cp .env.example .env
```
```bash
nano .env
```

Isi variabel berikut dengan password yang **kuat dan unik**:
- `MYSQL_ROOT_PASSWORD` — Password root MySQL
- `NPM_DB_PASSWORD` — Password internal untuk database Nginx Proxy Manager

### 4. Jalankan Infra

Setelah file `.env` dikonfigurasi, jalankan container infra:
```bash
docker compose up -d
```

### 5. Akses Nginx Proxy Manager

- URL Web Admin: `http://<IP-SERVER>:81`

> **Catatan:** Pada versi Nginx Proxy Manager terbaru, Anda tidak perlu lagi login dengan email/password default. Saat pertama kali mengakses halaman web admin, Anda akan langsung disuguhkan form pendaftaran untuk mengisi **Full Name, Email, dan New Password** akun Admin Anda.

### 6. Auto-Start & Setup Backup Otomatis

Jalankan script berikut **SEKALI** agar Docker otomatis menyala saat server di-restart, sekaligus memasang jadwal cron backup otomatis untuk infrastruktur:

```bash
cd /srv/workspace/infra
sudo bash setup-autostart.sh
```

Verifikasi Docker & Cron:
```bash
sudo systemctl status docker
sudo crontab -l
```

### 7. Update Infrastruktur (Maintenance)

Jika di masa depan terdapat update atau penambahan *service* baru di repositori `infra`, Anda bisa memperbarui *server* secara aman tanpa perlu me-restart semuanya secara manual.

Jalankan *script* berikut:
```bash
cd /srv/workspace/infra
bash update-safe.sh
```
*Script ini akan otomatis melakukan backup terlebih dahulu, menarik (pull) kode terbaru dari repositori Git, mengunduh image Docker terbaru (jika ada), dan menerapkan perubahan.*

---

## Part 2: Instalasi Aplikasi

Langkah-langkah berikut dilakukan ketika Infrastruktur (Part 1) **sudah berjalan**, dan Anda ingin menambahkan aplikasi ke dalam server.

### 1. Clone Aplikasi ke Workspace

Clone repositori aplikasi (misalnya: `master-gambar`) ke folder `apps`:
```bash
cd /srv/workspace/apps
git clone https://github.com/Zenalghi/master-gambar master-gambar
```

### 2. Membuat Database & User untuk Aplikasi

Setiap aplikasi harus memiliki database dan kredensialnya sendiri di dalam MySQL Infra:

```bash
# Masuk ke MySQL infra sebagai root
docker exec -it infra-mysql mysql -u root -p
```

Jalankan perintah SQL berikut:
```sql
-- Contoh untuk aplikasi master-gambar
CREATE DATABASE master_gambar_db;
CREATE USER 'master_gambar_user'@'%' IDENTIFIED BY 'PasswordAppKuat!';
GRANT ALL PRIVILEGES ON master_gambar_db.* TO 'master_gambar_user'@'%';
FLUSH PRIVILEGES;

-- (Ganti nama DB, User, dan Password sesuai aplikasi Anda)
```
Ketik `exit` untuk keluar dari MySQL.

### 3. Konfigurasi Environment Aplikasi

Masuk ke folder aplikasi dan sesuaikan konfigurasi environment dengan database yang baru saja dibuat:
```bash
cd /srv/workspace/apps/master-gambar
cp .env.example .env.production
```
Pastikan `DB_HOST=infra-mysql` dan sesuaikan kredensial `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`.

### 4. Deploy Aplikasi

Jalankan aplikasi menggunakan file konfigurasi production miliknya:
```bash
docker compose -f docker-compose.prod.yml up -d
```

Terakhir, daftarkan domain/IP aplikasi Anda di panel Nginx Proxy Manager (Port 81) agar bisa diakses dari browser.

---

## Maintenance Tambahan





### Akses Database via HeidiSQL (SSH Tunnel)

Karena port MySQL **hanya dibuka pada interface localhost (127.0.0.1)** dan tidak diekspos ke publik, admin dapat mengakses database dengan aman menggunakan metode SSH Tunnel:

1. Buka HeidiSQL → New Session → Pilih **SSH Tunnel**
2. Isi:
   - SSH Host: `<IP Server>`
   - SSH User: `<User SSH>`
   - MySQL Host: `127.0.0.1` (atau `localhost`)
   - MySQL Port: `3306`
   - User: `root`
   - Password: `<MYSQL_ROOT_PASSWORD>`
3. Connect
