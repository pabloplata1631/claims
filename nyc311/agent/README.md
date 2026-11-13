# Agent implementation (last phase)

Planned read-only tools: compare periods, decompose request-volume changes,
retrieve oldest open requests, inspect load health, and retrieve metric definitions.
Use the same analytics views and definitions as Power BI. Tool results must
include filters, observation date, sample size, and supporting request IDs.

Evaluation must compare tool results against known SQL answers, cover ambiguous
dates and empty results, and reject causal claims unsupported by the data.
Do not present public request data as individual employee performance data.
Do not claim true business resolution merely because a request was recorded closed.
