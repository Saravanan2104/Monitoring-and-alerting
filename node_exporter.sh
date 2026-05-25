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

echo "[*] Installing alertmanager binaries....."
sudo cp alertmanager amtool /usr/local/bin/
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo cp alertmanager.yml /etc/alertmanager/
sudo chown -R nobody:nogroup /etc/alertmanager /var/lib/alertmanager

echo "[*] Creating systemd service for alertmanager..."
sudo tee /etc/systemd/system/alertmanager.service >/dev/null <<'EOF'
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager/
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable --now alertmanager

echo ">>> Alertmanager installed and running on port 9093"

# ========= 2. Install node exporter ====================
echo "[*] Creating node_exporter user..."
sudo useradd --no-create-home --shell /bin/false node_exporter || true

echo "[*] Downloading node exporter..."
cd /tmp
curl -LO <node exporter.tar.gz>
tar -xvf node.tar.gz
cd node

echo "[*] Installing node exporter bnary"
sudo cp node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

echo "[*] creating systemd service for node exporter..."
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable --now node_exporter

echo "[*] updating system packages..."
sudo apt update && sudo apt upgrade -y

echo ">>> node exporter installed and running on port 9100"

echo "======================================="
echo "   Installation Completed"
echo "======================================="

