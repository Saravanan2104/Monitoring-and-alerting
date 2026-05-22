#!/bin/bash

# ============================================
# UPDATE SYSTEM
# ============================================

sudo dnf update -y
sudo dnf install wget tar -y

# ============================================
# DOWNLOAD PROMETHEUS
# ============================================

cd /opt

wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz

tar -xvf prometheus-3.5.0.linux-amd64.tar.gz

mv prometheus-3.5.0.linux-amd64 prometheus

# ============================================
# PROMETHEUS CONFIGURATION
# ============================================

sudo tee /opt/prometheus/prometheus.yml > /dev/null <<EOF

global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'localhost:9093'

rule_files:
  - "alert.rules.yml"

scrape_configs:

  - job_name: 'node_exporter'

    ec2_sd_configs:
      - region: ap-south-1
        port: 9100

        filters:
          - name: tag:Name
            values:
              - node-server

    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: address
        replacement: \$1:9100

EOF

# ============================================
# ALERT RULES
# ============================================

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
          summary: "High CPU Usage Detected"
          description: "CPU usage is above 80% for more than 1 minute"

      - alert: InstanceDown

        expr: up == 0

        for: 1m

        labels:
          severity: critical

        annotations:
          summary: "Instance Down"
          description: "Prometheus target instance is DOWN"

      - alert: HighMemoryUsage

        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80

        for: 1m

        labels:
          severity: critical

        annotations:
          summary: "High Memory Usage"
          description: "Memory usage is above 80%"

EOF

# ============================================
# PROMETHEUS SERVICE
# ============================================

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF

[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
ExecStart=/opt/prometheus/prometheus \
--config.file=/opt/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl daemon-reload

sudo systemctl start prometheus

sudo systemctl enable prometheus

# ============================================
# DOWNLOAD ALERTMANAGER
# ============================================

cd /opt

wget https://github.com/prometheus/alertmanager/releases/download/v0.28.1/alertmanager-0.28.1.linux-amd64.tar.gz

tar -xvf alertmanager-0.28.1.linux-amd64.tar.gz

mv alertmanager-0.28.1.linux-amd64 alertmanager

# ============================================
# ALERTMANAGER CONFIGURATION
# ============================================

sudo tee /opt/alertmanager/alertmanager.yml > /dev/null <<EOF

route:
  receiver: 'pagerduty'

  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h

receivers:

  - name: 'pagerduty'

    pagerduty_configs:

      - routing_key: 'PASTE-YOUR-PAGERDUTY-ROUTING-KEY'

        severity: 'critical'

EOF

# ============================================
# ALERTMANAGER SERVICE
# ============================================

sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF

[Unit]
Description=Alertmanager
After=network.target

[Service]
Type=simple
ExecStart=/opt/alertmanager/alertmanager \
--config.file=/opt/alertmanager/alertmanager.yml

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl daemon-reload

sudo systemctl start alertmanager

sudo systemctl enable alertmanager

# ============================================
# INSTALL GRAFANA
# ============================================

sudo dnf install -y https://dl.grafana.com/enterprise/release/grafana-enterprise-12.1.0-1.x86_64.rpm

sudo systemctl start grafana-server

sudo systemctl enable grafana-server

# ============================================
# RESTART SERVICES
# ============================================

sudo systemctl restart prometheus

sudo systemctl restart alertmanager

sudo systemctl restart grafana-server

# ============================================
# STATUS CHECK
# ============================================

sudo systemctl status prometheus

sudo systemctl status alertmanager

sudo systemctl status grafana-server

echo "========================================="
echo "PROMETHEUS   : http://SERVER-IP:9090"
echo "ALERTMANAGER : http://SERVER-IP:9093"
echo "GRAFANA      : http://SERVER-IP:3000"
echo "========================================="
