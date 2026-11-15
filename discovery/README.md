# Assessment discovery

Use the discovery register to track source searches and candidate decisions. The five database tables describe the assessment runs and values already represented in SAIO.

| File | What it records |
|---|---|
| [candidates.csv](candidates.csv) | Source inventory entries, identity matches, evidence, and decisions about screening, eligibility and import. |
| [inventory_units.csv](inventory_units.csv) | The linked entries grouped by stock or candidate unit. |
| [inventory_progress.csv](inventory_progress.csv) | Current counts by organization and source region. |
| [selections](selections/) | Dated selections and curation decisions for each batch. |
| [Screening reviews](../source_reviews/screening/) | Screening evidence and unresolved leads. |
| [inventory audit](../source_reviews/screening/inventory_audit_2026.md) | Sources, coverage limits and historical counts for the initial inventories. |

An inventory row can represent an alias or a separate run. Use `candidate_unit_id` to link rows once the stock identity is verified. Use `matched_stock_id` for a unit represented in `stocks.csv`.
A selection list records the basis for choosing a case at the time. Use `candidates.csv` for the current decision and the [stock source reviews](../source_reviews/) for substantive evidence about imported assessments.

Follow the [curation protocol](../PROTOCOL.md#1-discovering-candidate-assessments) when adding or revisiting rows. Earlier counts and summaries are in the Git history for this page at revision `7ef1dfa82d0d12819a86243f11b33395c41b871a`.
