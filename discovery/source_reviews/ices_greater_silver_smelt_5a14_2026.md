# ICES greater silver smelt in Subarea 14 and Division 5.a (2026)

**Review date:** 2026-10-30
**Official stock code:** `aru.27.5a14`
**Scientific name:** *Argentina silus*
**Assessment year:** 2026

## Stock identity and assessment

The 2026 ICES advice and Standard Graphs pages identify the current assessment
as `aru.27.5a14`. This stock unit is not present in the canonical stocks table.
The 2026 MFRI technical report describes an age-based SAM assessment, and the
2025 ICES WKBDEEP benchmark report records the current model benchmark.

## Recoverable inputs

The 2026 MFRI report documents catch biomass by year and age in Figure 8 and
mean catch weight-at-age in Figure 9. These support reconstruction of
numbers-at-age by dividing catch biomass by catch weight where the figures
provide nonzero, matching age-year coverage. The report also gives age-composition
sample coverage for validation. Age-specific autumn and spring survey indices
are in Figure 15, stock weights-at-age are in Figure 16, and maturity-at-age is
in Figure 17. These inputs are mainly available as figures rather than
machine-readable annual matrices, so numerical import requires transparent
digitization and unit, age, and year coverage checks. The assessment describes
the spring survey as conducted in March and stock weights as coming from the
autumn groundfish survey in October; converting these months to fractional-year
survey timing would be an approximation.

The WKBDEEP 2025 benchmark selected fixed natural mortality `M = 0.1`. The
benchmark discusses `M = 0.15` as an alternative within the profile-likelihood
range, so the fixed value and its sensitivity should remain explicit in any
translation.

## Official outputs

The 2026 ICES Standard Graphs/source-data pages provide recruitment at age 5 in
thousands, spawning-stock biomass in tonnes, and fishing mortality for ages
6–14, with uncertainty. These are useful aggregate outputs but do not provide
annual abundance-at-age or fishing-mortality-at-age surfaces in the public
source-data table.

## Screening decision

This is a distinct, new candidate and is **eligible for source curation**:
public sources document catch quantities and weights sufficient to reconstruct
catch numbers-at-age, age-specific survey indices, fixed M, survey timing, and
comparable official outputs. It is not yet ready for numerical
import because the input matrices require figure digitization and unit/coverage
validation. No canonical assessment, input, or output rows have been added, and
The ICES SAG XML endpoint returned HTTP 503 during retrieval. The official graph,
source-data, advice pages, and MFRI report were cached instead. Their URLs,
revision descriptions, retrieval date, sizes, and SHA-256 checksums are in
`source_cache/discovery_ices_greater_silver_smelt_2026/sources.csv`; the
cache is gitignored.

## Sources

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/19_arg_2026_1_techreport_en.html)
- [ICES 2026 Standard Graphs](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22476)
- [ICES 2026 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22476)
- [ICES 2026 advice record 7182](https://asd.ices.dk/viewAdvice/7182)
- [ICES WKBDEEP 2025 benchmark report](https://doi.org/10.17895/ices.pub.28882295)
