# Monitoring Documentation - AcademiaNovit

## Architecture Overview

```
+------------------+    +----------------+    +----------------+
|  Node Exporter   |    |   cAdvisor     |    |  Application   |
|  (Host Metrics)  |    |  (Containers)  |    |  (Containers)  |
+------------------+    +----------------+    +----------------+
        |                   |                    |
        v                   v                    v
+----------------------------------------------------------------+
|                                                                |
|  Prometheus                                                    |
|  - Scrapes metrics from all sources                            |
|  - Stores time-series data                                     |
|  - Evaluates alerting rules                                    |
|                                                                |
+----------------------------------------------------------------+
        |
        v
+----------------------------------------------------------------+
|                                                                |
|  Grafana                                                       |
|  - Visualizes metrics from Prometheus                          |
|  - Provides dashboards for monitoring                          |
|  - Configures alerts                                           |
|                                                                |
+----------------------------------------------------------------+
```

## Prometheus Configuration

### File: `prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]

  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
```

### Verification

1. Access Prometheus at `http://<host-ip>:9090`
2. Go to Status > Targets
3. Verify all targets are `UP`

## Grafana Configuration

### Data Sources

- **Name**: Prometheus
- **Type**: Prometheus
- **URL**: `http://prometheus:9090`
- **Access**: Proxy

### Recommended Dashboards

1. **Node Exporter Full** (ID: 1860)

   - Comprehensive host metrics (CPU, memory, disk, network)
   - Essential for monitoring server health and resource usage

2. **Docker & Host Monitoring** (ID: 193)

   - Container and host metrics
   - Shows running containers, resource usage, and performance metrics

3. **Prometheus 2.0 Overview** (ID: 3662)
   - Monitors the Prometheus server itself
   - Shows scrape health, rule evaluation, and storage metrics
   - Essential for ensuring the monitoring system is healthy

### Alerting

1. **CPU Usage**

   - Alert when CPU usage > 80% for 5 minutes

   ```
   - alert: HighCpuUsage
     expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80)
     for: 5m
     labels:
       severity: warning
     annotations:
       summary: "High CPU usage on {{ $labels.instance }}"
       description: "CPU usage is {{ $value }}%"
   ```

2. **Memory Usage**
   - Alert when memory usage > 80%
   ```
   - alert: HighMemoryUsage
     expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
     for: 5m
     labels:
       severity: warning
     annotations:
       summary: "High memory usage on {{ $labels.instance }}"
       description: "Memory usage is {{ $value }}%"
   ```

## Access

| Service       | URL                           | Port | Purpose                              |
| ------------- | ----------------------------- | ---- | ------------------------------------ |
| Grafana       | http://<host-ip>:3000         | 3000 | Metrics visualization and dashboards |
| Prometheus    | http://<host-ip>:9090         | 9090 | Metrics collection and querying      |
| cAdvisor      | http://<host-ip>:8080         | 8080 | Container metrics and visualization  |
| Node Exporter | http://<host-ip>:9100/metrics | 9100 | Host-level metrics                   |

**Default Grafana Credentials**:

- Username: `admin`
- Password: `admin` (change on first login)

## Deployment

### Prerequisites

- Docker Swarm initialized
- Docker Compose v3.8+
- Ports 3000, 9090, 8080, 9100 accessible

### Deploy Stack

```bash
# Copy configuration files to VM
cat docker-swarm.yml | ssh -p 2025 fverdus@<vm-ip> "cat > ~/docker-swarm.yml"

# Deploy the stack
ssh -p 2025 fverdus@<vm-ip> "docker stack deploy -c ~/docker-swarm.yml academia-novit"

# Verify services are running
ssh -p 2025 fverdus@<vm-ip> "docker service ls | grep -E 'prometheus|grafana|cadvisor|node-exporter'"
```

## Troubleshooting

### Common Issues

1. **Grafana not starting**

   - Check logs: `docker service logs academia-novit_grafana`
   - Verify volume permissions: `chmod -R 777 ~/grafana`

2. **Prometheus targets down**

   - Check target status: `http://<host-ip>:9090/targets`
   - Verify network connectivity between services

3. **No data in Grafana**
   - Verify Prometheus is scraping targets
   - Check data source configuration in Grafana
   - Ensure time range is set correctly

### Useful Commands

```bash
# View service status
docker service ls

# View service logs
docker service logs academia-novit_<service-name>

# Scale application
docker service scale academia-novit_web=5

# View running containers
docker ps

# View service details
docker service inspect academia-novit_<service-name>

# Force update service (after config changes)
docker service update --force academia-novit_<service-name>
```

## Backup and Restore

### Backup Configuration

```bash
# Create backup directory
mkdir -p ~/backup/grafana

# Backup Grafana data
ssh -p 2025 fverdus@<vm-ip> "docker run --rm -v academia-novit_grafana_data:/var/lib/grafana -v $(pwd)/backup:/backup alpine sh -c 'cd /var/lib/grafana && tar cf /backup/grafana/grafana-backup-$(date +%Y%m%d).tar .'"

# Backup Prometheus data
ssh -p 2025 fverdus@<vm-ip> "docker run --rm -v academia-novit_prometheus_data:/prometheus -v $(pwd)/backup:/backup alpine sh -c 'cd /prometheus && tar cf /backup/prometheus-backup-$(date +%Y%m%d).tar .'"
```

### Restore Configuration

```bash
# Restore Grafana data
ssh -p 2025 fverdus@<vm-ip> "docker run --rm -v academia-novit_grafana_data:/var/lib/grafana -v $(pwd)/backup:/backup alpine sh -c 'cd /var/lib/grafana && tar xf /backup/grafana/grafana-backup-<date>.tar'"

# Restart services
ssh -p 2025 fverdus@<vm-ip> "docker service update --force academia-novit_grafana"
```
