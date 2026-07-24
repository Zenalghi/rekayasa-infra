# Shared Infrastructure (Multi-App)

Repositori ini menyimpan infrastruktur pusat untuk seluruh aplikasi yang berjalan di server ini.

## Komponen
1. **MySQL Server (v9.7.0)**: Berjalan secara internal tanpa membuka port ke publik demi keamanan.
2. **Nginx Proxy Manager**: Berfungsi mengatur domain, routing *traffic* ke aplikasi yang tepat, serta mengurus sertifikat SSL secara otomatis.

## Network
Network utama bernama `rekayasa-network`. Semua aplikasi harus menempel (attach) ke network ini di dalam `docker-compose.prod.yml` masing-masing agar bisa terhubung ke MySQL dan Nginx Proxy Manager.

---

## Cara Menjalankan

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

Masuk ke direktori infra dan siapkan konfigurasi:
```bash
cd /srv/workspace/infra
cp .env.example .env.production
nano .env.production
```

Isi variabel berikut dengan password yang **kuat dan unik**:
- `MYSQL_ROOT_PASSWORD` — Password root MySQL
- `NPM_DB_PASSWORD` — Password internal untuk database Nginx Proxy Manager

### 4. Jalankan Infra

Setelah file `.env.production` dikonfigurasi, jalankan container infra:
```bash
docker compose up -d
```

### 5. Clone dan Deploy Aplikasi

Setelah infrastruktur berjalan, Anda bisa meng-clone aplikasi ke folder `apps`:
```bash
cd /srv/workspace
mkdir apps
cd apps

# Clone app nya, misal:
git clone https://github.com/Zenalghi/master-gambar master-gambar
```

Hasil akhirnya, struktur direktori workspace akan seperti ini:
```text
/srv/workspace/
│
├── infra/
│
└── apps/
    └── master-gambar/
```

Selanjutnya masuk ke direktori aplikasi dan deploy menggunakan `docker-compose.prod.yml`:
```bash
cd master-gambar
docker compose -f docker-compose.prod.yml up -d
```

### 6. Akses Nginx Proxy Manager
- URL: `http://<IP-SERVER>:81`
- Default Email: `admin@example.com`
- Default Password: `changeme`

> Segera ganti password default setelah login pertama kali!

---

## Membuat Database & User untuk Aplikasi Baru

Setelah infra berjalan, buat database dan user untuk setiap aplikasi:

```bash
# Masuk ke MySQL sebagai root
docker exec -it infra-mysql mysql -u root -p
```

```sql
-- Contoh untuk aplikasi master-gambar
CREATE DATABASE master_gambar_db;
CREATE USER 'master_gambar_user'@'%' IDENTIFIED BY 'PasswordAppKuat!';
GRANT ALL PRIVILEGES ON master_gambar_db.* TO 'master_gambar_user'@'%';
FLUSH PRIVILEGES;

-- Contoh untuk aplikasi inventory (di masa depan)
-- CREATE DATABASE inventory_db;
-- CREATE USER 'inventory_user'@'%' IDENTIFIED BY 'PasswordLain!';
-- GRANT ALL PRIVILEGES ON inventory_db.* TO 'inventory_user'@'%';
-- FLUSH PRIVILEGES;
```

---

## Auto-Start Saat Boot

Jalankan script berikut **SEKALI** agar Docker dan semua compose project otomatis menyala saat PC/server dinyalakan:

```bash
cd /srv/workspace/infra
sudo bash setup-autostart.sh
```

Verifikasi:
```bash
sudo systemctl status docker-compose-apps
```

---

## Backup

### Backup Infrastruktur (All Databases + NPM + SSL)
```bash
bash backup/autobackup.sh
```

### Setup Cron Otomatis (Setiap Hari Jam 12:00 Siang)

Cron backup akan terpasang secara otomatis ketika Anda menjalankan script `setup-autostart.sh` pada langkah Auto-Start sebelumnya.

### Verifikasi Cron

Karena script `setup-autostart.sh` dijalankan dengan `sudo`, maka cron terpasang pada user root. Untuk memverifikasinya, jalankan:
```bash
sudo crontab -l
```

---

## Akses Database via HeidiSQL (SSH Tunnel)

Karena port MySQL **tidak di-expose ke host**, gunakan SSH Tunnel:

1. Buka HeidiSQL → New Session → Pilih **SSH Tunnel**
2. Isi:
   - SSH Host: `192.168.100.17` (IP server)
   - SSH User: `<user-ssh-anda>`
   - MySQL Host: `infra-mysql`
   - MySQL Port: `3306`
   - User: `root`
   - Password: `<MYSQL_ROOT_PASSWORD>`
3. Connect
