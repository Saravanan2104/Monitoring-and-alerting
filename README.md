🚀 Prometheus + Grafana + Alertmanager + Node Exporter Setup

📌 Architecture

Application Servers
        ↓
Node Exporter (9100)
        ↓
Prometheus (9090)
        ↓
Alertmanager (9093)
        ↓
PagerDuty Alerts
        ↓
Grafana Dashboards (3000)

---

🖥️ Server Setup

Server| Purpose
App Server| Node Exporter
Monitoring Server| Prometheus + Grafana + Alertmanager

---

📦 Components Used

Tool| Purpose
Node Exporter| Collect system metrics
Prometheus| Scrape and store metrics
Alertmanager| Send alerts
PagerDuty| Incident notifications
Grafana| Dashboard visualization

---

⚙️ Ports Used

Port| Service
9100| Node Exporter
9090| Prometheus
9093| Alertmanager
3000| Grafana

---

🔥 STEP 1 — Node Exporter Setup

Create Script

nano node_exporter_setup.sh

Paste node exporter setup script.

---

Give Execute Permission

chmod +x node_exporter_setup.sh

---

Run Script

./node_exporter_setup.sh

---

Verify

systemctl status node_exporter

---

Test Metrics

curl localhost:9100/metrics

---

🔥 STEP 2 — Monitoring Server Setup

Create Script

nano monitoring_setup.sh

Paste monitoring setup script.

---

Give Execute Permission

chmod +x monitoring_setup.sh

---

Run Script

./monitoring_setup.sh

---

🔥 STEP 3 — Security Group Configuration

Application Server

Allow:

Port| Source
9100| Monitoring Server IP

---

Monitoring Server

Allow:

Port| Purpose
9090| Prometheus
9093| Alertmanager
3000| Grafana

---

🔥 STEP 4 — Verify Prometheus

Open:

http://SERVER-IP:9090

---

Check Targets

http://SERVER-IP:9090/targets

Expected:

UP

---

🔥 STEP 5 — Verify Alerts

Open:

http://SERVER-IP:9090/alerts

---

🔥 STEP 6 — Verify Alertmanager

Open:

http://SERVER-IP:9093

---

🔥 STEP 7 — Verify Grafana

Open:

http://SERVER-IP:3000

Default Login:

username: admin
password: admin

---

🔥 STEP 8 — Add Prometheus Datasource

Grafana:

Connections
→ Data Sources
→ Add Data Source
→ Prometheus

URL:

http://localhost:9090

Click:

Save & Test

---

🔥 STEP 9 — Import Dashboard

Grafana:

Dashboards
→ Import

Dashboard ID:

1860

This imports Node Exporter Full dashboard.

---

🔥 Alert Rules Configured

1️⃣ High CPU Usage

Triggers when CPU usage > 80%.

---

2️⃣ Instance Down

Triggers when Prometheus target becomes DOWN.

---

3️⃣ High Memory Usage

Triggers when memory usage > 80%.

---

🔥 PagerDuty Integration

Configured inside:

/opt/alertmanager/alertmanager.yml

---

Update Routing Key

Replace:

PASTE-YOUR-PAGERDUTY-ROUTING-KEY

with actual PagerDuty integration key.

---

🔥 EC2 Auto Discovery

Prometheus uses:

ec2_sd_configs

with EC2 tag filtering.

---

Tag Requirement

EC2 instances should contain:

Name=node-server

---

Benefit

Whenever new EC2 instance created with:

Name=node-server

Prometheus automatically discovers and monitors it.

---

🔥 Useful Commands

Prometheus

systemctl status prometheus
systemctl restart prometheus

---

Alertmanager

systemctl status alertmanager
systemctl restart alertmanager

---

Grafana

systemctl status grafana-server
systemctl restart grafana-server

---

Node Exporter

systemctl status node_exporter
systemctl restart node_exporter

---

🔥 Prometheus Config Validation

./promtool check config prometheus.yml

---

🔥 Final URLs

Service| URL
Prometheus| http://SERVER-IP:9090
Alertmanager| http://SERVER-IP:9093
Grafana| http://SERVER-IP:3000

---

✅ Final Outcome

✔ Real-time monitoring
✔ Auto EC2 discovery
✔ CPU/RAM alerts
✔ PagerDuty integration
✔ Multi-server monitoring
✔ Grafana dashboards
✔ Production-style observability setup
