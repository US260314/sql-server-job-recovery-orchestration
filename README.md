## 📌 Overview

This repository implements an **enterprise-grade SQL Server Agent job recovery orchestration framework** designed for **Power BI Report Server environments running on SQL Server**.

In many enterprise reporting platforms, scheduled report refresh jobs are tied to **SQL Server Agent jobs**. During **planned maintenance windows (patching, server reboot, service restarts)**, scheduled executions may be skipped, resulting in missed report refreshes and potential reporting gaps.

This framework introduces a **controlled, auditable, and prioritized recovery mechanism** that automatically detects missed job executions and safely replays them in a **batch-controlled, resource-aware manner**.

The solution was designed and implemented to **eliminate manual job recovery processes and improve operational reliability for enterprise reporting systems**.

---

# 🎯 Problem Statement

In large **Power BI Report Server environments**:

* Each report deployment generates a **corresponding SQL Server Agent job**
* These jobs control:

  * Report refresh schedules
  * Email subscriptions
  * Data exports
  * Data refresh pipelines

During **monthly patching cycles or infrastructure maintenance**:

* SQL Server services are temporarily stopped
* Scheduled job execution windows are missed
* Critical report refreshes fail to run
* Manual DBA intervention becomes necessary

Common risks include:

* Missed executive reporting
* Delayed dashboards
* Inconsistent downstream data
* Operational overhead for DBAs
* Potential system overload when manually replaying jobs

This creates both **operational risk and business impact**.

---

# 🏗️ Solution Architecture

A **stored-procedure driven orchestration framework** was implemented to intelligently detect and recover missed job executions.

The framework operates through the following phases:

---

## 1️⃣ Missed Job Window Detection

The system automatically identifies jobs whose scheduled execution window occurred during the SQL Server downtime.

Detection logic:

* Capture **SQL Server service stop timestamp**
* Capture **SQL Server service restart timestamp**
* Evaluate job schedules during the outage window
* Generate a **candidate recovery list**

This ensures only relevant jobs are replayed.

---

## 2️⃣ Safe Execution Modes

The framework supports **dual execution modes** to ensure safe operational rollout.

| Mode              | Description                                          |
| ----------------- | ---------------------------------------------------- |
| `@to_execute = 0` | Dry-run mode – lists impacted jobs without executing |
| `@to_execute = 1` | Live execution mode – executes missed jobs           |

This allows:

* Risk-free validation
* Controlled testing
* Safe production deployments

---

## 3️⃣ Batch-Based Recovery Execution

To prevent system overload, jobs are executed in **configurable batches**.

Key behavior:

* Jobs are grouped into execution batches
* Next batch starts only after the previous batch completes
* Prevents excessive backend resource consumption
* Protects database and ETL infrastructure

This ensures **controlled workload replay instead of uncontrolled spikes**.

---

## 4️⃣ Priority-Based Job Recovery

Not all reports have equal business importance.

The framework supports **priority-based execution**, allowing critical reports to run first.

Examples:

* Executive dashboards
* Regulatory reports
* Operational monitoring reports

Lower priority reports are replayed afterward.

This aligns system behavior with **business reporting priorities**.

---

## 5️⃣ Comprehensive Audit Logging

Every execution is recorded for operational transparency.

Captured metadata includes:

* Job name
* Execution batch
* Execution timestamp
* Execution status (Success / Failure)
* Execution mode (Dry-Run / Live)
* Recovery invocation ID

Benefits:

* Operational traceability
* Audit compliance
* Incident review capability
* Historical analysis

---

# 🧠 Design Principles

### Reliability First

Ensures that **critical enterprise reports are never permanently missed due to maintenance operations**.

---

### Controlled Resource Management

Batch-controlled execution prevents load spikes and protects backend systems.

---

### Safety by Design

Dry-run mode ensures **zero-risk validation before production execution**.

---

### Business-Aware Execution

Priority-based recovery aligns execution with **organizational reporting importance**.

---

### Operational Automation

Transforms a **manual DBA recovery process into deterministic automation**.

---

# 💼 Operational Impact

After implementation, this framework:

* Eliminated manual SQL Agent job recovery after patching
* Reduced DBA operational effort
* Improved reliability of enterprise reporting
* Prevented resource spikes caused by bulk job restarts
* Improved SLA compliance for executive reporting

---

# 📈 Operational Maturity Model

| Capability                  | Traditional Approach | This Framework |
| --------------------------- | -------------------- | -------------- |
| Manual job restart          | ✔                    | ❌              |
| Scripted bulk restart       | ✔                    | ❌              |
| Missed job detection        | ❌                    | ✔              |
| Batch-controlled recovery   | ❌                    | ✔              |
| Priority-aware execution    | ❌                    | ✔              |
| Auditable execution logging | ❌                    | ✔              |
| Safe dry-run validation     | ❌                    | ✔              |

This represents **enterprise-grade operational automation for SQL Server environments**.

---

# 🔒 Safety & Governance

The framework was designed to be **non-invasive and operationally safe**:

* Does **not modify existing job schedules**
* No changes to SQL Agent configuration
* Executes only missed jobs
* Fully auditable execution trail

---

# 🚀 Future Enhancements

Potential extensions include:

* Cross-server job recovery
* Multi-instance orchestration
* Automated post-patch triggers
* Email summary reporting
* Centralized monitoring dashboard

---

# 👤 Author

**Syamprasad Agiripalli**
Principal Cloud Data & Reliability Engineer

Specializing in:

* Database Reliability Engineering
* Cloud Database Platforms
* Operational Automation
* Enterprise Data Infrastructure

---

