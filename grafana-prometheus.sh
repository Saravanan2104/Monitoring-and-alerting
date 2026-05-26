#! /bin/bash
set -e

echo "++++++++++++++++++++++++++++++++++++++++++++"
echo " Installing Monitoring Stack"
echo "++++++++++++++++++++++++++++++++++++++++++++"

WORKDIR="/opt/monitoring"
mkdir -p $WORKDIR
cd $WORKDIR

# ==================== 1. Update ================================
sudo dnf update -y && sudo dnf upgrade -y

#===================== 2. Prometheus ============================
sudo useradd --no-create-home --shell /bin/false prometheus || true
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus


curl -LO https://github.com/prometheus/prometheus/releases/download/v2.55.1/prometheus-2.55.1.linux-amd64.tar.gz
tar xvf prometheus-2.55.1.linux-amd64.tar.gz
cd prometheus-2.55.1.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

sudo cp -r consoles console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus

#prometheus service
sudo tee /etc/systemd/system/prometheus.service >/dev/null <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.enable-lifecycle
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#========================== 3. Grafana ====================================
sudo dnf install -y gnupg
sudo tee /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=Grafana OSS
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo dnf update -y
sudo dnf install -y grafana
sudo systemctl enable --now grafana-server

#========================= 4. AlertManager ==================================
cd $WORKDIR
curl -L -O https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz
cd alertmanager-0.27.0.linux-amd64

sudo cp alertmanager amtool /usr/local/bin/
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo chown -R prometheus:prometheus /etc/alertmanager /var/lib/alertmanager

#Alertmanager congif
sudo tee /etc/alertmanager/alertmanager.yml >/dev/null << 'EOF'
route:
  receiver: pagerduty
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h

receivers:
  - name: pagerduty
  pagerduty_configs:
    - routing_key : <add key>
      severity: "critical"
  
EOF


#Alertmanager service
sudo tee /etc/systemd/system/alertmanager.service >/dev/null << 'EOF'
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#================== 5.Node Exporter ==========================
cd $WORKDIR
sudo useradd --no-create-home --shell /bin/false node_exporter || true

curl -L -O https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.11.1.linux-amd64.tar.gz
cd node_exporter-1.11.1.linux-amd64

sudo cp node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service >/dev/null << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
user=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ===================== 6. Alert Rules (fixed)  ========================
sudo tee /etc/prometheus/alert.rules.yml >/dev/null << 'EOF'
groups:
  - name: system-alerts
  rules:
    - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical

    - alert: HighCPUUsage
    expr: >
      100 - (
        sum by(instance) (rate(node_cpu_seconds_total{mode='idle}[1m]))
        /
        sum by(instance) (rate(node_cpu_seconds_total[1m]))
        ) * 100 > 10
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High cup usage on {{ $labels.instance}}"
      description: "CPU usage is above 10% for more than 2 minutes"

    - alert: HighDiskUsage
      expr: >
      (1 - (
      node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}
      /
      node filesystem size bytes{fstype!~"tmpfs|overlay"}
      )) * 100 > 50
      for: 2m
      labels:
        severity: warning
EOF

# ================== 7. Prometheus config ==============
sudo tee /etc/prometheus/prometheus.yml >/dev/null <<'EOF'
global:
  scrape_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]

rule_files:
  - "alert.rules.yml"

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "ec2-node-exporters"
    ec2_sd_configs:
      - region: us-south-1
        port: 9100
        filters:
          - name: "tag:Name"
            values: ["node_server"]

    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "$1:9100"

      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance

EOF

# ===================== 8. start service  ====================
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable prometheus --now
sudo systemctl enable alertmanager --now
sudo systemctl enable node_exporter --now

sudo systemctl restart prometheus

echo "================================================"
echo " Installation completed "
echo "================================================"
echo "Prometheus : http://<server-ip>:9090"
echo "Grafana : http://<server-ip>:3000"
echo "Alertmanager : http://<server-ip>:9093"
echo "================================================"
