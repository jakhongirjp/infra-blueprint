# ADR-0003: Multi-burn-rate SLO alerts instead of threshold alerts

- Status: accepted
- Date: 2026-11-24

## Decision

Alert on error-budget burn for a 99.9% 30-day availability objective using
two windows per severity (1h/5m and 6h/30m for paging, 3d for tickets), as
described in the Google SRE Workbook.

## Why

Static thresholds ("error rate > 1% for 5m") page on harmless blips during
low traffic and miss slow, steady degradation. Burn-rate alerts page only
when the budget is genuinely at risk, and the short window makes them reset
quickly once the problem is fixed.

## Consequences

- Services must expose `*_http_requests_total{status}`; the shared chart and
  both portfolio services already do.
- Recording rules keep alert evaluation cheap.
