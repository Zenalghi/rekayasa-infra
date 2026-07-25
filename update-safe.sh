#!/bin/bash
# =====================================================================
# Update Safe - Infrastruktur
# =====================================================================
# Script ini akan:
# 1. Menjalankan full backup infrastruktur terlebih dahulu
# 2. Melakukan git pull untuk mengambil konfigurasi docker-compose terbaru
# 3. Menerapkan perubahan (docker compose up -d)
# =====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Safe Update Infrastruktur ===${NC}"
echo ""

# 1. Backup
echo -e "${YELLOW}[1/3] Memulai proses backup sebelum update...${NC}"
bash backup/autobackup.sh
echo -e "${GREEN}  ✓ Backup selesai${NC}"
echo ""

# 2. Git Pull
echo -e "${YELLOW}[2/3] Mengambil konfigurasi terbaru dari Git...${NC}"
git pull origin main || git pull origin master
echo -e "${GREEN}  ✓ Git pull selesai${NC}"
echo ""

# 3. Docker Compose Update
echo -e "${YELLOW}[3/3] Menerapkan update ke container...${NC}"
docker compose pull
docker compose up -d --remove-orphans
echo -e "${GREEN}  ✓ Update container selesai${NC}"
echo ""

echo -e "${BLUE}=== Update Infrastruktur Berhasil Selesai ===${NC}"
