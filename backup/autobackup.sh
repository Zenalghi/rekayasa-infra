#!/bin/bash
# =====================================================================
# Full Infrastructure Backup Script
# =====================================================================
# Script ini akan membackup:
# 1. Seluruh database MySQL (all-databases)
# 2. File konfigurasi Nginx Proxy Manager & SSL
# 3. File .env
# =====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env"

# Warna untuk output (aktif hanya di terminal interaktif, mati saat di-cron/file log)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo -e "${BLUE}=== Memulai Proses Backup Infrastruktur ===${NC}"
echo -e "Waktu: $(date)"

# Load secrets
if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
else
    echo -e "${RED}ERROR: File .env tidak ditemukan di ${ENV_FILE}${NC}"
    exit 1
fi

BACKUP_DIR="${BACKUP_DIR:-/mnt/data/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
DATE_TAG="$(date +%Y-%m-%d-%H%M%S)"
TARGET_FOLDER="${BACKUP_DIR}/infra-backup-${DATE_TAG}"

mkdir -p "${TARGET_FOLDER}"

# ---------------------------------------------------------
# 1. Backup MySQL (All Databases)
# ---------------------------------------------------------
echo -e "${YELLOW}-> [1/3] Membackup seluruh database MySQL...${NC}"
if docker ps --format '{{.Names}}' | grep -q "infra-mysql"; then
    DB_DUMP_FILE="${TARGET_FOLDER}/mysql_alldbs_${DATE_TAG}.sql.gz"
    
    # Gunakan exec langsung untuk menjalankan mysqldump di dalam container
    docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" infra-mysql mysqldump \
        -u root \
        --all-databases \
        --single-transaction \
        --routines --events | gzip > "${DB_DUMP_FILE}"

    DB_SIZE=$(du -sh "${DB_DUMP_FILE}" | cut -f1)
    echo -e "${GREEN}   ✓ Backup DB selesai (${DB_SIZE})${NC}"
else
    echo -e "${RED}   ✗ Container infra-mysql tidak berjalan! Skip backup DB.${NC}"
fi

# ---------------------------------------------------------
# 2. Backup NPM Config & SSL
# ---------------------------------------------------------
echo -e "${YELLOW}-> [2/3] Membackup konfigurasi NPM & SSL...${NC}"
NPM_ARCHIVE="${TARGET_FOLDER}/npm_data_${DATE_TAG}.tar.gz"
# Kita bisa membackup docker volumes dengan menjalankan container tar sementara
docker run --rm \
    -v infra_npm-data:/data \
    -v infra_npm-letsencrypt:/etc/letsencrypt \
    -v "${TARGET_FOLDER}:/backup" \
    alpine tar czf "/backup/npm_data_${DATE_TAG}.tar.gz" -C / data etc/letsencrypt

NPM_SIZE=$(du -sh "${NPM_ARCHIVE}" | cut -f1)
echo -e "${GREEN}   ✓ Backup NPM selesai (${NPM_SIZE})${NC}"

# ---------------------------------------------------------
# 3. Backup file .env
# ---------------------------------------------------------
echo -e "${YELLOW}-> [3/3] Membackup file .env...${NC}"
cp "${ENV_FILE}" "${TARGET_FOLDER}/env_${DATE_TAG}.backup"
echo -e "${GREEN}   ✓ Backup .env selesai${NC}"

# ---------------------------------------------------------
# 4. Arsipkan ke satu file & Cleanup
# ---------------------------------------------------------
echo -e "${YELLOW}-> Mengompresi seluruh file backup...${NC}"
cd "${BACKUP_DIR}"
tar czf "infra-backup-${DATE_TAG}.tar.gz" "infra-backup-${DATE_TAG}"
rm -rf "infra-backup-${DATE_TAG}"

FINAL_SIZE=$(du -sh "infra-backup-${DATE_TAG}.tar.gz" | cut -f1)
echo -e "${GREEN}✓ Arsip Final: infra-backup-${DATE_TAG}.tar.gz (${FINAL_SIZE})${NC}"

# ---------------------------------------------------------
# 5. Rotasi (Hapus backup lama)
# ---------------------------------------------------------
echo -e "${YELLOW}-> Membersihkan backup yang lebih tua dari ${RETENTION_DAYS} hari...${NC}"
find "${BACKUP_DIR}" -name "infra-backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

echo -e "${BLUE}=== Proses Backup Infrastruktur Selesai ===${NC}"
echo -e " "
