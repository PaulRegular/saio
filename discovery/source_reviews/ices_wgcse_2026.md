# ICES WGCSE 2026 regional screening

The full [2026 Working Group for the Celtic Seas Ecoregion report](https://doi.org/10.17895/ices.pub.32625759.v1) was retrieved from ICES Figshare on 2026-10-29 and cached under `source_cache/discovery_ices_wgbie_2026/`. The report’s section 1.3 classifies assessment methods; stock chapters and the audit annex provide run-specific evidence. The full report and its direct-file URL and checksum are recorded in that cache manifest. This review does not create canonical assessment records.

## Age-based assessments

WGCSE identified 14 category-1 age-based assessment units. Category 1 describes the assessment method; it does not by itself establish that age-disaggregated observations can be recovered. The source-screened status for this WGCSE set is 11 eligible, 1 ineligible and 2 unresolved. Eight previously screened eligible matches are Irish Sea plaice, Irish Sea cod, Celtic Sea cod, Celtic Sea haddock, Rockall haddock, Western Channel sole, Celtic Sea common sole and West of Scotland whiting. The additional decisions are:

| ICES unit | Match / screen | Decision | Evidence and remaining limit |
|---|---|---|---|
| `whg.27.7a` Irish Sea whiting | Matched; screened | Eligible; imported | Existing canonical record has the 2025 SAM benchmark inputs and outputs through 2023 plus a separate 2025 ICES summary through 2025. The 2026 WGCSE report leaves this chapter for its autumn update; do not treat the newer summary as run-matched input data. |
| `pol.27.67` pollack | Provisional new; screened | Eligible; not imported | The 2026 stock annex documents commercial catch age data since 2010, fixed age-specific M and maturity, life-history inputs, aggregate survey and LPUE series; WGCSE 2026 and ICES graphs provide official outputs. Annual timing is a documented approximation because quarterly samples were not considered sufficient for a seasonal SS3 model. |
| `whg.27.7b-ce-k` Celtic Sea whiting | Provisional new; screened | Eligible; partial source import | The 2026 WGCSE chapter supplies catch, weight, VAST survey, commercial index, fixed biology, F-at-age, N-at-age and aggregate outputs. Run-matched landings fractions, exact timing and age-specific output uncertainty remain unavailable; see `ices_whiting_7b_ce_k_2026.md`. |
| `anf.27.3a46` Northern Shelf anglerfish | Provisional new; screened | Ineligible | Although assessed with age-structured SS3, the 2026 production assessment uses commercial catch-at-length and size-class abundance indices. The report says the 2011 ageing exchange found little agreement among readers; no catch-at-age or survey age series was verified. |
| `bss.27.4bc7ad-h` northern seabass | Provisional new; screened | Unresolved | The 2026 SS3 update reports length compositions and conditional age-at-length, plus length-based maturity. screened | Unresolved | See `ices_sol_27_7a_2026.md`. the source review records the remaining catch-scale and production-run M gaps. |.

The two new eligible candidates are distinct from existing same-species records: pollack is *Pollachius pollachius*, not saithe (*P. virens*); Celtic Sea whiting is a different ICES stock code and boundary from Irish Sea whiting. New identities remain provisional until the NOAA, ICES and DFO inventories are reconciled across organizations.

The current 2026 production evidence for pollack and Celtic Sea whiting was checked against the WGCSE report, the 2026 stock annexes, and the applicable ICES Stock Assessment Graphs. Official PDFs for those annexes, the WKBSS3 pollack benchmark report and the WKBSEABASS benchmark report are cached locally in `source_cache/discovery_ices_wgcse_2026/`; that folder's `sources.csv` records direct download URLs, retrieval dates and SHA-256 checksums. The WKBSEABASS and WGCSE sources show that an age-based model label can coexist with length-composition likelihoods, which is why northern seabass remains unresolved.

## Other assessment methods

The report classifies 11 other units outside the current age-structured candidate set: two megrim stocks use SPiCT (category 2); plaice in 7.e is a category-3 data-limited update and plaice in 7.f-g and 7.h-k use survey trends and length indicators; haddock in 7.a and sole in 7.h-k receive category-5 advice; and seabass 6.a/7.b/7.j, cod 6.b, plaice 7.b-c and sole 7.b-c receive category-6 advice. These units are ineligible for this age-structured candidate set under the methods used for current advice. This does not assert that age observations do not exist or that earlier assessments were not age structured.

The reviewed non-age-structured candidate IDs and method evidence remain recorded in `candidates.csv`. These WGCSE results are one regional screening slice, not a completed ICES, NOAA or DFO inventory audit and not a selected import batch.
