#!/bin/bash
# =====================================================================
# Setup Auto-Start - Infrastruktur & Semua Aplikasi
# =====================================================================
# Script ini akan:
# 1. Enable Docker service agar otomatis menyala saat boot
# 2. Membuat systemd service yang menjalankan infra + semua app saat boot
#
# Jalankan SEKALI saja dengan: sudo bash setup-autostart.sh
# =====================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Setup Auto-Start (Infra + Aplikasi) ===${NC}"
echo ""

# =====================================================================
# 1. Enable Docker auto-start
# =====================================================================
echo -e "${BLUE}[1/3] Mengaktifkan Docker auto-start...${NC}"
if systemctl enable docker >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Docker auto-start enabled${NC}"
else
    echo -e "${RED}  ✗ FAILED${NC}"
fi
echo ""

# =====================================================================
# 2. Start Docker if not running
# =====================================================================
echo -e "${BLUE}[2/3] Memulai Docker service...${NC}"
if systemctl start docker >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Docker running${NC}"
else
    echo -e "${RED}  ✗ FAILED${NC}"
fi
echo ""

echo -e "${BLUE}=== Setup Selesai ===${NC}"
echo ""
echo "Catatan:"
echo "Karena semua container di konfigurasi dengan 'restart: always',"
echo "maka container infra maupun aplikasi akan otomatis berjalan"
echo "ketika Docker daemon menyala (saat PC booting)."
