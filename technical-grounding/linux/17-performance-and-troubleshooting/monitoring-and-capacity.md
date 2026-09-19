# Monitoring and Capacity

Monitoring turns one-off checks into continuous signals, and capacity planning uses those signals to add resources before they run out. This page covers the vocabulary and the host-level checks; fleet dashboards and alerting live under [Observability and Security](../../../observability-security/index.md).

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| SLI | A measured indicator: latency, error rate, availability | dashboards, logs |
| SLO | The target for an SLI, for example 99.9% success | agreed internally |
| SLA | The contract with consequences if the SLO is missed | contract |
| Error budget | The allowed failure under the SLO (0.1% for 99.9%) | derived from SLO |
| Health check | A cheap probe of liveness and readiness | `curl`, `systemctl is-active` |
| Liveness vs readiness | Alive means the process runs; ready means it can serve | probe endpoints |
| Agent | A collector runs on each host (node_exporter, the Datadog agent) | on-host service |
| Agentless | A central poller scrapes or SSHes in | central config |
| Baseline | The normal value a metric is judged against | `sar` history |
| Headroom | Spare capacity kept for spikes and failures | capacity plan |
<!-- --8<-- [end:facts] -->

---

## SLI, SLO and SLA

These three terms nest. An SLI is a number you measure, an SLO is the target you hold that number to, and an SLA is the external contract that adds consequences if the SLO is missed.

| Term | What it is | Example |
|---|---|---|
| **SLI** | A measured indicator | 99.95% of requests under 300ms |
| **SLO** | The internal target | 99.9% under 300ms per month |
| **SLA** | The external contract | credits if availability drops below 99.5% |

The gap between the SLO and 100% is the error budget: the amount of failure the service may spend on risk, such as deploys, before it must slow down and stabilise.

!!! note "Set the SLO from user impact, not from convenience"
    An SLO copied from a round number (99.9% everywhere) rarely matches what users need. Derive it from the impact of failure on the people relying on the service, then size the error budget from there.

---

## Host Health Checks

The cheapest monitoring is a health check: a probe that confirms a service is alive and able to serve. On one host, `systemctl is-active` and a local `curl` answer both questions in a second.

```bash
systemctl is-active nginx sshd
systemctl is-system-running
curl -s -o /dev/null -w 'code=%{http_code} time=%{time_total}s\n' http://127.0.0.1/
```

Output:

```text
active
inactive
degraded
code=200 time=0.000535s
```

`is-system-running` returns `degraded` here because one unit failed, a single signal that something needs attention. A liveness probe checks the process is up; a readiness probe checks it can actually serve requests, which is the `curl` returning 200.

!!! tip "Alert on saturation and symptoms, not on raw utilization"
    A CPU at 100% is not an incident if latency is fine; a growing queue is. Alert on user-facing symptoms (latency, error rate) and on saturation that predicts failure, rather than on utilization alone.

---

## Agent versus Agentless

Monitoring collects metrics in one of two shapes: an agent on each host that pushes or exposes metrics, or a central poller that scrapes hosts, often over SSH or an exposed endpoint.

| | Agent | Agentless |
|---|---|---|
| **Collection** | On-host collector (node_exporter, vendor agent) | Central poller scrapes or connects in |
| **Strength** | Rich local detail, per-process metrics | Nothing to install on the host |
| **Cost** | An extra service to deploy and update | Network reach and credentials to every host |

---

## Capacity and Thresholds

Capacity planning compares current usage against a baseline and a growth trend, then adds resources before headroom runs out. A threshold without a baseline is a guess, because acceptable usage varies by workload.

The `sar` archive supplies the history: peak load per day, memory trend, disk growth. From those, a threshold is set with headroom for spikes and for the loss of a node, not at the point of failure.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between an SLI, an SLO and an SLA?"
    **Say first:** an SLI is the measured indicator, an SLO is the internal target for it, and an SLA is the external contract with consequences.

    **Proof:** latency is the SLI, 99.9% under 300ms is the SLO, and service credits below 99.5% is the SLA.

    **Follow-up:** what is an error budget? (the allowed failure under the SLO.)

??? question "L1: What is the difference between a liveness and a readiness check?"
    **Say first:** liveness confirms the process is running; readiness confirms it can actually serve requests.

    **Proof:** `systemctl is-active` for liveness; a `curl` to the endpoint returning 200 for readiness.

    **Follow-up:** why can a process be alive but not ready? (still warming up, or a dependency is down.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show a one-command health summary of a host's services."
    **Say first:** `systemctl` reports overall state and per-service status.

    **Proof:**

    ```bash
    systemctl is-system-running; systemctl --failed
    ```

    **Follow-up:** what does `degraded` mean here? (the system is up but at least one unit failed.)

??? question "L2: Why alert on saturation rather than utilization?"
    **Say first:** utilization can sit at 100% while service is fine, but saturation (a growing queue) predicts user-facing failure.

    **Proof:** `iostat` `aqu-sz` rising, or `vmstat` `r` above the core count, ahead of latency climbing.

    **Follow-up:** which user-facing signals make the best alerts? (latency and error rate.)

??? question "L3: A dashboard shows CPU at 100% and pages the on-call, but users report no problem. What is wrong with the alert?"
    **Say first:** the alert fires on utilization, which is not itself a fault; a busy CPU with low latency and a short queue is healthy.

    **Proof:** compare `mpstat` utilization against request latency and `vmstat` `r`; only a growing queue or rising latency is user-facing.

    **Follow-up:** what would a better alert measure? (saturation and latency, tied to the SLO.)

??? question "L4: How do you set a capacity threshold when the workload varies by host?"
    **Say first:** derive it from each host's own baseline and growth trend, with headroom for spikes and the loss of a node, rather than a single fixed number.

    **Proof:** `sar` history gives the per-host baseline; the threshold sits below the failure point with margin.

    **Don't say:** that one global threshold (for example load above 1.0) fits every host.

---

## Related

- [Methodology](methodology.md): the metrics worth monitoring
- [Observability and Security](../../../observability-security/index.md): fleet dashboards and alerting
- [journalctl](../09-logging/journalctl.md): logs as a monitoring source
- [systemctl](../08-systemd-and-services/systemctl.md): service state and `--failed`

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
