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

Buat folder workspace dan atur permission di server:
```bash
sudo mkdir -p /srv/workspace
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
- Default Email: `admin@example.com`
- Default Password: `changeme`

> Segera ganti password default setelah login pertama kali!

### 6. Setup Backup Otomatis

Sangat penting untuk memastikan infrastruktur Anda memiliki jadwal backup. Pasang cron job untuk mem-backup MySQL, konfigurasi NPM, dan SSL secara rutin:
```bash
(crontab -l 2>/dev/null; echo "0 12 * * * cd ~/infra && bash backup/autobackup.sh >> /var/log/infra-backup.log 2>&1") | crontab -
```
Verifikasi cron berjalan:
```bash
crontab -l
```

---

## Part 2: Instalasi Aplikasi

Langkah-langkah berikut dilakukan ketika Infrastruktur (Part 1) **sudah berjalan**, dan Anda ingin menambahkan aplikasi ke dalam server.

### 1. Clone Aplikasi ke Workspace

Clone repositori aplikasi (misalnya: `master-gambar`) ke folder `apps`:
```bash
cd /srv/workspace
mkdir -p apps
cd apps

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

### Auto-Start Saat Boot

Jalankan script berikut **SEKALI** agar Docker otomatis menyala saat PC/server di-restart:

```bash
cd /srv/workspace/infra
sudo bash setup-autostart.sh
```

Verifikasi:
```bash
sudo systemctl status docker
```



### Akses Database via HeidiSQL (SSH Tunnel)

Karena port MySQL **tidak di-expose ke host**, admin dapat mengakses database menggunakan SSH Tunnel:

1. Buka HeidiSQL → New Session → Pilih **SSH Tunnel**
2. Isi:
   - SSH Host: `<IP Server>`
   - SSH User: `<User SSH>`
   - MySQL Host: `infra-mysql`
   - MySQL Port: `3306`
   - User: `root`
   - Password: `<MYSQL_ROOT_PASSWORD>`
3. Connect
