# 2ndtele

Monitoring and alerting stack that forwards Prometheus alerts to **Telegram**.

## What's inside

- `prometheus.yml` — Prometheus scrape configuration
- `alert.rules.yml` — alerting rules evaluated by Prometheus
- `alert_dispatcher.sh` — shell dispatcher that delivers fired alerts to a Telegram chat
- `grafana-dashboard.json` — ready-to-import Grafana dashboard
- `docker-compose.yml` — brings the whole stack up together
- `app/` — supporting application code

## Quick start

```bash
docker compose up -d
```

Configure your Telegram bot token and chat ID for the dispatcher (see `alert_dispatcher.sh`), then import `grafana-dashboard.json` into Grafana to view the dashboards. When an alert rule fires, the dispatcher pushes a message to your Telegram.

## Stack

Prometheus · Grafana · Docker Compose · Shell
