# ICES Bay of Biscay seabass (`bss.27.8ab`), 2026 assessment

## Assessment identity

ICES assessment key 22538 and advice record 6153 identify the 2026 assessment
for 2027 advice of seabass (*Dicentrarchus labrax*) in divisions 8.a and 8.b.
The WGBIE 2026 report describes an update using data through 2025 and the
age- and length-structured Stock Synthesis model established at the 2025
WKBSEABASS benchmark. This is distinct from the separate 8.c–9.a seabass unit
and from the western seabass units. The assessment year, fitted-data terminal
year, and 2026 forecast year are recorded separately.

## Recovered source data

The ICES Standard Graphs source data and XML provide annual series for
1985–2025 and 2026 forecasts:

- Combined-sex spawning-stock biomass in tonnes, with reported 90% interval
  endpoints.
- Age-0 recruitment in thousands of fish, with reported 90% interval
  endpoints.
- Fishing mortality averaged over ages 4–15 in inverse years, with 90%
  interval endpoints for 1985–2025. The 2026 Fbar field is blank.
- Aggregate catch, landings, and discards in tonnes for 1985–2025. The source
  series are retained as separate total and component quantities. They overlap
  and must not be summed together as independent removals. The XML does not
  identify their fleet coverage or confirm that they exhaust the fitted SS3
  catch observations, so the canonical input record is partial.

The published point estimates and 90% endpoints are stored as reported.
Standard errors are unavailable and have not been calculated from those
intervals. The 2026 SSB and recruitment values are forecasts, not fitted
historical estimates.

## Assessment structure and unresolved inputs

The WGBIE 2026 report describes an age- and length-based Stock Synthesis
assessment. Commercial catch and length-composition information and annual
conditional age-at-length data are used; the report explains that age-length
keys support catch-at-age estimates, while marginal fleet age compositions
are not the fitted likelihood input. No run-matched age-length quantities or
age-specific catch inputs were recovered for the 2026 assessment.

The assessment uses juvenile abundance indices from Nourdem Loire
(2016–2025) and Nourdem Gironde (2019–2025), plus adult OTB LPUE
(2000–2025; 2000 and 2008 are excluded from the fitted series). The 2025
benchmark describes the juvenile indices as covering ages 1–4, but the 2026
source table reports only aggregate index series. Age-specific survey
observations and exact fractional-year timing for these indices remain
unavailable.

The 2026 report describes von Bertalanffy growth, a length-based female
maturity ogive, and age-specific natural mortality values of 0.840918,
0.463849, 0.365109, 0.306347, 0.267492, and 0.24 per year at ages 0–5,
with 0.24 at older ages. It fixes length-at-age 30 at 87.7611 cm and gives
female maturity L50 = 42.14 cm with logistic slope -0.37809. These are
useful assumptions, but exact run-matched weight-at-age, the complete growth
and weight-length inputs, and maturity-at-age rows were not recovered.

Seasonal catch reallocation rates are reported for Q3 and Q4. Those describe
stock mixing and are not survey timing. The exact 2026 fitted model files and
full age-specific state outputs were not located. No age-specific N, F, or M
surface is present in the Standard Graphs export.

## Canonical record and status

The canonical record contains the 2026 assessment's aggregate catch, landings,
and discard series; fixed M-at-age inputs for ages 0–5 and the age-6+ value;
2026 SSB, age-0 recruitment, and Fbar outputs; and a small set of
model-definition and reference-point assumptions. Inputs, assumptions, and
outputs remain marked partial. This is a source-curation record, not a
translation-ready age-structured data set.

## Sources and cached files

- [2026 ICES advice record 6153](https://asd.ices.dk/viewAdvice/6153)
- [2026 ICES Standard Graphs source data, key 22538](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22538)
- [WGBIE 2026 report](https://doi.org/10.17895/ices.pub.32790321.v1), section 11
- [WKBSEABASS 2025 benchmark report](https://doi.org/10.17895/ices.pub.25002488.v1)
- [ICES XML assessment export, key 22538](https://sag.ices.dk/SAG_API/StockXmlDownload/22538)

The gitignored local cache is `source_cache/discovery_ices_seabass_8ab_2026/`.
Its `sources.csv` records URLs, retrieval date, pinned assessment identity,
file sizes, and SHA-256 checksums for both 2026 and 2025 reference files.
