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
