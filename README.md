# Shared Infrastructure (Multi-App)

Repositori ini menyimpan infrastruktur pusat untuk seluruh aplikasi yang berjalan di server ini.

## Komponen
1. **MySQL Server (v9.7.0)**: Berjalan secara internal tanpa membuka port ke publik demi keamanan.
2. **Nginx Proxy Manager**: Berfungsi mengatur domain, routing *traffic* ke aplikasi yang tepat, serta mengurus sertifikat SSL secara otomatis.

## Network
Network utama bernama `rekayasa-network`. Semua aplikasi harus menempel (attach) ke network ini di dalam `docker-compose.prod.yml` masing-masing agar bisa terhubung ke MySQL dan Nginx Proxy Manager.

---

## Cara Menjalankan

### 1. Copy file konfigurasi
```bash
cp .env.example .env.production
nano .env.production
```

Isi variabel berikut dengan password yang **kuat dan unik**:
- `MYSQL_ROOT_PASSWORD` — Password root MySQL
- `NPM_DB_PASSWORD` — Password internal untuk database Nginx Proxy Manager

### 2. Jalankan
```bash
docker compose up -d
```

### 3. Akses Nginx Proxy Manager
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
```bash
(crontab -l 2>/dev/null; echo "0 12 * * * cd ~/infra && bash backup/autobackup.sh >> /var/log/infra-backup.log 2>&1") | crontab -
```

### Verifikasi Cron
```bash
crontab -l
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
