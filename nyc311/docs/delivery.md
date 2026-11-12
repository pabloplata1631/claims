# Delivery plan and review evidence

## Milestones

1. Confirm connections; extract and profile the cohort.
2. Implement SQL layers, raw load, observed history, and validation.
3. Schedule daily execution and prove safe reruns and recovery from failure.
4. Build and validate the initial Power BI model and report in DEV.
5. Complete a documented enhancement through DEV → UAT → PROD → app.
6. Add and evaluate the read-only analytics agent.

## Example enhancement: CR-001 Aging analysis

Scenario: a simulated operations stakeholder requests aging buckets and a weekly
change comparison to support review of long-waiting requests.

Acceptance criteria:

- Agreed active-status mapping and cohort scope are displayed.
- Buckets 0–2, 3–7, 8–14, 15–30, 31+ days are exclusive and exhaustive for valid ages.
- Bucket totals reconcile to the scoped open count; invalid records are visible.
- Filters and drillthrough produce the same counts as SQL validation queries.
- Last successful refresh time and analysis threshold are visible.
- Historical comparisons use only available comparable snapshots.

## Promotion gates

| Stage | Evidence required before moving forward |
| --- | --- |
| DEV | Reviewed diff, Python checks, SQL reconciliation, repeat-load and history checks |
| UAT | Expected-versus-actual scenarios, filter checks, metric review, recorded reviewer decision |
| PROD | Exact approved revision, SQL migration, correct bindings, gateway/refresh checks, smoke test |
| App | App update confirmed, consumer-view check, release note and screenshots |

CI checks code; it does not substitute for SQL execution or stakeholder testing.
Label self-run UAT as a simulation. Record actual dates and outcomes only after
execution, never prefill successful sign-off. Record workspace and report IDs only
when known. Git branches and Power BI workspaces are separate concepts.

Rollback plan: retain the previous reviewed report/model revision and database
migration rollback approach. Prefer additive schema changes and compatibility
views. Verify rollback in DEV before relying on it for PROD.

Power BI deployment pipelines require suitable workspace licensing/capacity and
permissions. If unavailable, use explicitly documented manual workspace promotion
and label it manual; do not claim Fabric automation occurred.
