# Workflow: Post-maintenance SQL Agent Job Recovery Orchestration

## Objective
After monthly patching / service downtime, scheduled SQL Agent jobs created by Power BI Report Server subscriptions may be missed. This workflow detects the downtime window and replays missed jobs safely with audit logging.

---

## End-to-End Flow

### Step 1 — Capture maintenance window
- Identify SQL Server Agent service start time (post-reboot) and the maintenance start time (planned downtime start).
- These timestamps define the window of potential “missed schedules”.

### Step 2 — Discover impacted SSRS schedules
- Query ReportServer metadata (Catalog, Subscriptions, ReportSchedule, Schedule, Users).
- Determine which schedules should have triggered during the window.
- Load candidates into a control table (e.g., `ReportServer.dbo.Reports_Run`) for traceability.

### Step 3 — Safety mode decision
- `@to_execute = 0` (dry run): produce a list of job start commands without executing.
- `@to_execute = 1` (execute): run the recovery plan.

### Step 4 — Controlled replay (stability)
- Start missed jobs deterministically using `msdb.dbo.sp_start_job`.
- (Optional enhancement) Execute in batches to avoid overwhelming downstream systems.

### Step 5 — Auditability
- Log recovery actions:
  - what was selected
  - what was executed
  - timestamps
  - status / error details
- This enables operational validation and post-maintenance reporting.

---

## Outcomes
- Eliminates manual job restarts after patching
- Reduces risk of missed report refreshes
- Prevents “flooding” systems by enabling controlled replay patterns
- Provides traceability for audit and troubleshooting
