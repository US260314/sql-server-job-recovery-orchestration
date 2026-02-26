## 📌 Overview

This project implements a controlled, auditable, and prioritized SQL Agent job recovery framework designed for enterprise Power BI Report Server environments hosted on-premises.

The solution addresses a critical operational gap where scheduled SQL Agent jobs are missed during server maintenance windows (patching/reboots), potentially leading to missed report refreshes, delayed executive reporting, and downstream data inconsistencies.

Instead of relying on manual job restarts, this framework introduces a structured, configurable, and batch-controlled recovery mechanism.

---

## 🎯 Problem Statement

In enterprise Power BI Report Server environments:

* Each deployed report creates a corresponding SQL Agent job.
* Users define refresh schedules, email delivery, exports, and data refresh timing.
* Monthly patching requires SQL services to be stopped temporarily.
* During maintenance windows:

  * Scheduled jobs are skipped.
  * Execution windows are missed.
  * Manual intervention is required.
  * There is risk of missing critical reports.
  * Bulk re-execution may overload backend systems.

This creates:

* Operational risk
* Manual effort
* Business impact
* Potential performance bottlenecks

---

## 🏗️ Solution Architecture

A stored procedure-driven orchestration framework was developed to:

### 1️⃣ Detect Missed Job Windows

* Capture SQL Server service stop time
* Capture SQL Server service start time
* Identify jobs whose schedules fall within this window
* Generate candidate recovery list

---

### 2️⃣ Controlled Execution Mode

Supports dual-mode execution:

| Mode              | Behavior                           |
| ----------------- | ---------------------------------- |
| `@to_execute = 0` | Dry run – lists affected jobs only |
| `@to_execute = 1` | Executes missed jobs               |

This enables:

* Safe validation in testing
* Controlled production release
* Zero-risk preview mode

---

### 3️⃣ Batch-Based Execution Control

To prevent system overload:

* Jobs are executed in configurable batch sizes
* Next batch starts only after previous batch completes
* Prevents backend resource saturation
* Avoids performance bottlenecks

---

### 4️⃣ Priority-Based Release

Not all reports are equal.

The framework supports:

* Classification-based execution
* Critical reports first
* Executive dashboards prioritized
* Non-critical reports deferred

This aligns execution order with business value.

---

### 5️⃣ Audit Logging

Each invocation records:

* Job name
* Execution time
* Status (Success/Failure)
* Execution batch
* Timestamp
* Execution mode (Dry-run/Live)

Provides:

* Traceability
* Compliance evidence
* Operational transparency
* Historical review capability

---

## 🧠 Design Principles

### Reliability First

Designed to prevent missed executive reporting and operational blind spots.

---

### Controlled Resource Management

Batch processing prevents load spikes and protects backend systems.

---

### Safety by Design

Dry-run mode ensures risk-free validation before execution.

---

### Business-Aware Execution

Priority-based execution aligns with critical reporting requirements.

---

### Operational Maturity

Transforms reactive manual intervention into deterministic automation.

---

## 💼 Business Impact

This framework:

* Eliminated manual post-patching job recovery
* Reduced operational risk
* Improved reporting reliability
* Prevented performance bottlenecks
* Increased DBA productivity
* Ensured SLA compliance for executive reporting

---

## 📈 Design Maturity Level

| Level                            | Capability |
| -------------------------------- | ---------- |
| Manual restart of jobs           | ❌          |
| Scripted bulk execution          | ❌          |
| Intelligent missed-job detection | ✅          |
| Controlled batch replay          | ✅          |
| Priority-based release           | ✅          |
| Auditable execution logging      | ✅          |
| Safe dry-run testing mode        | ✅          |

This represents enterprise-grade operational automation.

---

## 🔒 Safety & Governance

* No modification to existing job schedules
* No schedule override
* Non-invasive recovery logic
* Fully auditable execution trail

---

## 🚀 Extensibility

The framework can be extended to support:

* Cross-server job recovery
* Distributed SQL instances
* Automated post-patch triggers
* Email summary reporting
* Centralized operational dashboard

---

## 👤 Author

Syamprasad Agiripalli
Principal Cloud Data & Reliability Engineer
Database Reliability | Automation | Operational Engineering



