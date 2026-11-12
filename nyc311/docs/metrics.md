# Metric contract (draft for validation)

All measures show scope and observation date. Exclude rejected records but
surface their counts; do not silently discard them.

| Metric | Definition | Caveat |
| --- | --- | --- |
| Requests received | Distinct request IDs by created-date period | Publication delays and later corrections can revise counts |
| Recorded closures | Distinct request IDs by valid closed-date period | Not a claim that the underlying issue was fixed |
| Observed open requests | Requests mapped to an active status at observation time | Profile actual statuses before approving the mapping; unknowns separate |
| Age of open requests | Observation time minus created time | Initial cohort only; separate invalid/future timestamps |
| Time to recorded closure | Valid closed time minus created time; median and P90 | Closed cohort selection must be explicit; exclude negative durations |
| Backlog change | Comparable daily snapshot open count difference | History starts with first snapshot, fixed cohort scope |
| Aging threshold exceeded | Open requests older than configurable analysis threshold | Not an official SLA breach |
| Official due-date exceedance | Eligible requests beyond a populated, validated due date | Only publish after field coverage and due-date meaning are verified |
| New demand change | Current complete week versus previous complete week | Use America/New_York boundaries; avoid partial-week comparisons |

Do not treat all non-Closed statuses as active until actual values are profiled.
Due dates may be missing. Zip codes are text. Preserve source request IDs as text.
The public dataset contains agency assignments, not agent-level productivity.
