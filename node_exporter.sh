#!/bin/bash

# ==============================
# UPDATE SYSTEM
# ==============================

sudo dnf update -y
sudo dnf install wget tar -y

# ==============================
# CREATE NODE EXPORTER USER
# ==============================

sudo useradd --no-create-home --shell /bin/false node_exporter

# ==============================
# DOWNLOAD NODE EXPORTER
# ==============================

cd /opt

wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz

tar -xvf node_exporter-1.9.1.linux-amd64.tar.gz

# ==============================
# COPY BINARY
# ==============================

sudo cp node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/

sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# ==============================
# CREATE SYSTEMD SERVICE
# ==============================

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# ==============================
# START SERVICE
# ==============================

sudo systemctl daemon-reload

sudo systemctl start node_exporter

sudo systemctl enable node_exporter

# ==============================
# VERIFY
# ==============================

sudo systemctl status node_exporter

echo "=================================="
echo "NODE EXPORTER RUNNING ON :9100"
echo "=================================="
