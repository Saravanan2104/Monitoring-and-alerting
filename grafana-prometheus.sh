#!/bin/bash

# ==============================
# UPDATE SYSTEM
# ==============================

sudo dnf update -y
sudo dnf install wget tar -y

# ==============================
# DOWNLOAD PROMETHEUS
# ==============================

cd /opt

wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz

tar -xvf prometheus-3.5.0.linux-amd64.tar.gz

mv prometheus-3.5.0.linux-amd64 prometheus

# ==============================
# PROMETHEUS CONFIG
# ==============================

sudo tee /opt/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'

    static_configs:
      - targets:
          - 'APP-SERVER-IP-1:9100'
          - 'APP-SERVER-IP-2:9100'

rule_files:
  - 'alert.rules.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'localhost:9093'
EOF

# ==============================
# ALERT RULES
# ==============================

sudo tee /opt/prometheus/alert.rules.yml > /dev/null <<EOF
groups:
  - name: production-alerts

    rules:

      - alert: HighCPUUsage

        expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100) > 80

        for: 1m

        labels:
          severity: critical

        annotations:
          summary: "High CPU Usage"
          description: "CPU usage above 80%"

      - alert: InstanceDown

        expr: up == 0

        for: 1m

        labels:
          severity: critical

        annotations:
          summary: "Instance Down"
          description: "Prometheus target is DOWN"
EOF

# ==============================
# PROMETHEUS SERVICE
# ==============================

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start prometheus

sudo systemctl enable prometheus

# ==============================
# DOWNLOAD ALERTMANAGER
# ==============================

cd /opt

wget https://github.com/prometheus/alertmanager/releases/download/v0.28.1/alertmanager-0.28.1.linux-amd64.tar.gz

tar -xvf alertmanager-0.28.1.linux-amd64.tar.gz

mv alertmanager-0.28.1.linux-amd64 alertmanager

# ==============================
# ALERTMANAGER CONFIG
# ==============================

sudo tee /opt/alertmanager/alertmanager.yml > /dev/null <<EOF
route:
  receiver: 'default'

receivers:
  - name: 'default'
EOF

# ==============================
# ALERTMANAGER SERVICE
# ==============================

sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=Alertmanager
After=network.target

[Service]
Type=simple
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start alertmanager

sudo systemctl enable alertmanager

# ==============================
# INSTALL GRAFANA
# ==============================

sudo dnf install -y https://dl.grafana.com/enterprise/release/grafana-enterprise-12.1.0-1.x86_64.rpm

sudo systemctl start grafana-server

sudo systemctl enable grafana-server

# ==============================
# STATUS CHECK
# ==============================

sudo systemctl status prometheus
sudo systemctl status alertmanager
sudo systemctl status grafana-server

echo "=================================="
echo "PROMETHEUS : 9090"
echo "ALERTMANAGER : 9093"
echo "GRAFANA : 3000"
echo "=================================="
