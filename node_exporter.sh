#! /bin/bash
set -e

echo "++++++++++++++++++++++++++++++++++++++++++++"
echo " Installing AlertManager + Node exporter"
echo "++++++++++++++++++++++++++++++++++++++++++++"

# ==================== 1. Install AlertManager ================================
echo "[*] Downloading Alertmanager..."
cd /tmp

curl "<link>"
tar -xvf "alertmanager.tar.gz"
cd 'alermanager'

