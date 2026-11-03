# NOAA Gulf of Mexico shrimp inventory records (2026 snapshot)

**Review date:** 2026-10-30  
**Source:** NOAA Stock SMART  
**Scope:** identity reconciliation and taxonomic screening only

## Records

The pinned NOAA-EDAB Stock SMART snapshot identifies three separate Gulf of
Mexico shrimp units:

| NOAA stock ID | Common name | Scientific name |
|---|---|---|
| `10079` | Brown shrimp | *Farfantepenaeus aztecus* |
| `10081` | Pink shrimp | *Farfantepenaeus duorarum* |
| `10083` | White shrimp | *Litopenaeus setiferus* |

The source metadata gives each a distinct stock ID and Gulf of Mexico
ecosystem. They do not match any stock in the canonical database. Stable
candidate-unit keys are assigned to preserve those identities across the
inventory.

## Screening decision

These are crustaceans, outside the expansion's initial marine-finfish scope.
They remain screened ineligible without reviewing assessment inputs or
outputs. This is a taxonomic scope decision, not a finding that the
assessments lack age data. No canonical assessment, input, or output records
were added.

The metadata snapshot is cached at
`source_cache/discovery_noaa_stocksmart/stock_assessment_summary.rda`. Its
pinned repository revision, retrieval date, URL, and SHA-256 are listed in the
adjacent `sources.csv` manifest.

## Source

- [NOAA Stock SMART](https://www.fisheries.noaa.gov/resource/tool-app/stock-smart)
