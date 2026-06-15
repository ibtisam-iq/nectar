# Metrics‑based Monitoring with Prometheus, Grafana, and Alertmanager

## 1. Goal and scope

This stack provides **metrics‑based monitoring and alerting** for the platform and workloads.

- Focus: **metrics** (numeric time‑series) such as CPU, memory, request rate, error rate, latency.  
- It does **not** store or query raw application logs; a separate logging stack (e.g., Fluent Bit → CloudWatch, ECK/Elastic, Loki) handles logs.

Typical questions this stack answers:

- “Is the system healthy right now?”  
- “Are error rates or latency breaching SLOs?”  
- “Should we page someone via Slack or on‑call?”

---

## 2. High‑level process

At a process level, the metrics pipeline has three main stages:

1. **Collect & store metrics**  
   - A metrics engine **scrapes** metrics from targets and stores them as time‑series.  
2. **Visualize metrics**  
   - A dashboard/UI layer queries the metrics engine and renders charts and dashboards.  
3. **Alert on metrics**  
   - An alerting component evaluates alert rules and routes notifications to channels like Slack.

In the canonical open‑source Kubernetes stack, these roles are implemented by:

- **Prometheus** (metrics collection and storage)  
- **Grafana** (visualization)  
- **Alertmanager** (alert routing)

---

## 3. Components and responsibilities

### 3.1 Role overview

| Concern         | Component     | Primary responsibility                                | Notes                                    |
|-----------------|--------------|------------------------------------------------------|------------------------------------------|
| Metrics engine  | Prometheus   | Scrape, store, and query metrics time‑series        | Pulls from `/metrics` endpoints          |
| Visualization   | Grafana      | Dashboards and visual exploration of metrics        | Uses Prometheus as a data source         |
| Alert routing   | Alertmanager | Receive alerts from Prometheus and send notifications | Groups, deduplicates, routes             |


### 3.2 Prometheus – metrics engine

**Responsibility:** Collect, store, and evaluate metrics.

Key characteristics:

- Pull‑based model: Prometheus regularly scrapes `/metrics` HTTP endpoints exposed by:  
  - Application services (instrumented with Prometheus client libraries)  
  - Kubernetes components (kube‑state‑metrics, cAdvisor, node exporters, etc.)  
- Data model: time‑series, identified by metric name + labels (e.g. `http_requests_total{service="orders-api",status="500"}`).  
- Storage: embedded time‑series database optimized for metrics; no external DB required.  
- Query language: PromQL, used both for dashboards and for alert expressions.

Examples of what Prometheus does:

- Scrapes CPU/memory usage for each node and pod.  
- Scrapes application metrics like request count, latency histograms, and error rates.  
- Evaluates alert rules such as:  
  - “Page if error rate > 5% for 5 minutes.”  
  - “Warn if p95 latency > 500 ms for 10 minutes.”

Prometheus **does not** store log lines; it only stores numerical metrics.

---

### 3.3 Grafana – visualization layer

**Responsibility:** Visualize metrics and expose dashboards.

Key characteristics:

- Grafana treats Prometheus as a **data source**.  
- It does not store metrics itself; all data is pulled from Prometheus (or other sources).  
- You build dashboards that query Prometheus using PromQL and render time‑series graphs, gauges, tables, etc.  
- Can combine multiple data sources (e.g., Prometheus for metrics, Loki/Elasticsearch/CloudWatch for logs) into one UI.

Typical usage:

- Kubernetes cluster health dashboards (nodes, pods, workloads).  
- Service‑level dashboards (RPS, error rate, latency for each microservice).  
- SLO dashboards (availability, latency budgets).

In this stack, Grafana is purely a **visual layer** over Prometheus metrics.

---

### 3.4 Alertmanager – alert routing and notifications

**Responsibility:** Receive alerts from Prometheus and deliver them to humans/systems.

How it works:

- Prometheus evaluates alerting rules; when a rule fires, Prometheus sends an alert object to Alertmanager.  
- Alertmanager de‑duplicates and groups alerts, then routes them according to configuration (routes, receivers, inhibition rules).  
- Common receivers: Slack, email, PagerDuty, Opsgenie, webhooks, etc.

Typical configuration:

- Route all `severity="critical"` alerts to an on‑call Slack channel.  
- Route `severity="warning"` alerts to a lower‑priority channel.  
- Silence or inhibit noisy alerts during planned maintenance windows.

In the “Prometheus + Grafana + Alertmanager + Slack” setup, this is the component that actually **sends messages** to Slack when something breaks.

---

## 4. Variations and alternative tools

The **process** (collect → visualize → alert) is stable; tools can change. For example:

### 4.1 Metrics engine alternatives

| Role           | Common OSS / SaaS options                          | Notes                                               |
|----------------|----------------------------------------------------|-----------------------------------------------------|
| Metrics engine | Prometheus, Cortex, Mimir, VictoriaMetrics         | All expose Prometheus‑compatible APIs               |
| Vendor suites  | Datadog, New Relic, CloudWatch Metrics, etc.       | Bundle metrics collection + storage + alerting      |

### 4.2 Visualization alternatives

| Role          | Options                               | Notes                                                 |
|---------------|----------------------------------------|-------------------------------------------------------|
| Dashboards/UI | Grafana, vendor dashboards, some Kibana views | Grafana is the de‑facto OSS standard                 |

### 4.3 Alerting alternatives

| Role        | Options                                            | Notes                                               |
|-------------|----------------------------------------------------|-----------------------------------------------------|
| Alerting    | Alertmanager, Datadog alerts, CloudWatch alarms, Opsgenie, PagerDuty rules | Some tools evaluate rules; some just receive alerts |

In cloud‑native/Kubernetes ecosystems, the combination of:

- **Prometheus** for metrics  
- **Grafana** for dashboards  
- **Alertmanager** for notifications  

is the de‑facto standard open‑source monitoring stack.

---

## 5. Monitoring vs logging in this stack

Important separation of concerns:

- **This stack handles metrics only.**  
  - Numeric measurements, trends, SLOs, health indicators.  
  - Answers “Is something wrong?” and “How bad is it?”.

- **It does not provide log collection or log search.**  
  - For logs, a separate process and stack is used, such as:  
    - Fluent Bit → CloudWatch Logs  
    - Beats → Elasticsearch → Kibana (Elastic Stack)  
    - Promtail → Loki → Grafana

In practice, both metrics and logs are needed for full observability:

- Metrics + alerts tell you **that** something is wrong.  
- Logs (and traces) help you understand **why** it is wrong.
