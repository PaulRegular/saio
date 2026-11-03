# ICES unstarted units: non-age-based current assessment records

Review date: 2026-11-01
Inventory: ICES Stock Information Database snapshot retrieved 2026-10-28
Assessment sources: linked ICES Standard Graphs source-data pages retrieved 2026-11-01

## Scope and identity

This screen covers 33 ICES inventory rows that were still unreviewed in the candidate register. Each code is a separate ICES assessment unit with a distinct area description. No exact stock-code match was found in the canonical database. The provisional candidate unit IDs are stored in `discovery/candidates.csv`; these are not canonical stock records.

The reviewed codes are:

```text
raj.27.3a47d  rjb.27.3a4  rjh.27.4a6  rjr.27.23a4  dab.27.3a4
bsf.27.nea  gag.27.nea  jaa.27.10a2  usk.27.1-2  usk.27.12ac
usk.27.3a45b6a7-912b  usk.27.6b  ory.27.nea  rng.27.5b6712b
raj.27.1012  sbr.27.10  sck.27.nea  ele.2737.nea  bsk.27.nea
tsu.27.nea  reb.27.14b  rjf.27.67  rjh.27.7afg  rjb.27.67a-ce-k
cyo.27.nea  guq.27.nea  rng.27.1245a8914ab  mur.27.3a47d
ldb.27.7b-k8abd  pil.27.7  lin.27.346-91214  raj.27.67a-ce-k
bli.27.123a4
```

## Official evidence and screening decision

The pinned 2026 SID snapshot supplies each code's current data category, last-assessment metadata, and method label. The linked Standard Graph pages supply the published source series for the associated assessment key. Across all 33 pages, the code and key matched the SID and the page's age-specific F and length fields were empty. The pages report aggregate annual landings/catches, indices, or trend-based indicators where those are published; none supplies an age-disaggregated catch or survey series or N-, F-, or M-at-age outputs for these current methods.

The SID methods include “no assessment”, trend or survey-trend assessments, constant harvest-rate methods, and catch-only methods. These do not establish an age-structured production assessment with the inputs and outputs required for this database's age-disaggregated set. All 33 are therefore screened ineligible for age-disaggregated source curation. This is not a claim that age samples or biological research are unavailable outside the assessment sources reviewed.

One source-year discrepancy is retained explicitly: `rjb.27.67a-ce-k` has SID `YearOfLastAssessment = 2024` but its SID method is “no assessment”; the linked Standard Graph key 13830 is labelled 2020. The 2020 page is treated only as the last linked detailed output, not as a 2024 assessment. The current SID row and area remain the identity basis.

Three ICES Atlantic salmon units and anglerfish `anf.27.1-2` were not included in this group because their SID records indicate potentially analytical or unresolved assessments requiring separate source review. Thresher shark `thr.27.nea` was also left unresolved because its current SID record did not provide a Standard Graph assessment key. No new canonical assessment records were created.

## Cached material

The ignored local cache `source_cache/discovery_ices_unstarted_age_audit_2026/` contains all 33 linked Standard Graph source-data pages and a `sources.csv` manifest with source URL, retrieval date, assessment key/year, bytes, and SHA-256. The SID snapshot and its original provenance manifest are in `source_cache/discovery_ices_sid/`. The relevant public sources are the [ICES Stock Information Database](https://sid.ices.dk/Default.aspx) and [ICES Standard Graphs](https://standardgraphs.ices.dk/).
