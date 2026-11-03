# Northeast Arctic beaked redfish (`Sebastes mentella`)

## Official run and sources

`jrn_redfish_beaked_2026` represents the detailed 2026 JRN-AFWG production
assessment through 2025, corresponding to Charbonneau–Keith
`ICES-AFWG_mentella_DEEP 1,2` and stock code `reb.27.1-2`.
The stock-specific statistical catch-at-age model (SCAA) is implemented in TMB;
it is not a SAM assessment.

- [JRN-AFWG 2026, chapter 6](https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5): production assessment, original input tables and fitted outputs.
- [WKREDFISH 2018](https://doi.org/10.17895/ices.pub.19291142.v1): benchmark and working document 4, including the SCAA equations, survey observation models and baseline configuration.
- [2026 advice for 2027](https://www.hi.no/en/hi/nettrapporter/imr-vniro-en-2026-3): current advice basis.

The report HTML, assessment PDF and complete framework PDF are cached under
`source_cache/ck_ices_afwg_mentella_deep_1_2_2026/`, with URLs, retrieval dates
and SHA-256 checksums in `manifest.txt`. The importer pins the HTML checksum.
The official framework's Figshare record has one PDF attachment; a public
native production configuration or fitted object has not been recovered.
An earlier search using an unrelated plaice SAM endpoint was erroneous and
provides no evidence about this stock's availability.

## Model inventory

The 2026 report identifies the 2018 baseline with 53 estimated parameters.
It models 1992–2025, recruitment at age 2, demersal and pelagic fisheries,
and fixed M = 0.05 per year. The reporting tables aggregate ages 19 and older.
Internally the population matrix retains older cohorts as the series advances;
it is not simply an age-19 plus-group recursion in every year.

Working document 4 specifies AR1 log recruitment, separate AR1 annual fleet
F coefficients and AR1 demersal selectivity parameters. Survival after
recruitment is deterministic. Demersal selectivity varies annually; pelagic
selectivity is fixed across years. Fleet F is the annual coefficient times
selectivity, summed across fleets for total F. Initial ages 2–19+ are fitted
separately. Native catch-at-age and catch-weight likelihoods are lognormal;
the deep-pelagic age composition has a logit-scale likelihood. These are not
independent absolute age-specific indices.

## Canonical coverage

The reproducible importer is
`scripts/database/143_import_jrn_beaked_redfish_2026.R`.
All three completeness statuses remain **partial**.

| Component | Recovered source records | Important qualification |
|---|---|---|
| Total catch | Table 6.8, 1992–2025, ages 6–19+, thousand fish, and total tonnes | Includes the separately reported pelagic subset; do not add them |
| Pelagic catch outside EEZ | Table 6.9, 2006–2025, ages 7–19+, thousand fish, and tonnes | Some compositions are source estimates; exact two-fleet input assembly remains unresolved |
| Stock and catch weight | Table 6.12 **Modelled** row, ages 6–19+, kg per fish | Fixed across years; annual observed weights are not these model inputs |
| Maturity | Table 6.14 **Model input** row, ages 6–19+, proportion | Fixed across years since the 2024 assessment; do not use annual observed ogives |
| M | Fixed 0.05 per year, ages 2–19+ | Source input, not estimated mortality |
| Russian autumn survey | Table 6.15, year classes 1974–2015, ages 0–11, fish per hour | Source header is **Yearclass**; preserve birth-cohort labels, not calendar survey years |
| Ecosystem survey | Table 6.17, 1996–2025, ages 2–15, million fish | 2010 has no age reading; 16+ retained separately as a combined-age index |
| Winter bottom-trawl survey | Table 6.18b, published annual rows, ages 2–15, million fish | Missing age readings and coverage restrictions remain explicit |
| N | Table 6.20a, 1992–2025, ages 2–19+, thousand fish | 612 reported states; 19+ sums older cohorts |
| F | Tables 6.20a–c, same years/ages | Derived from rounded fleet coefficients and selectivities; approximate, with original components retained |
| Aggregates | Table 6.21, SSB and total biomass in tonnes, age-2 recruitment in millions, F summaries | Native definitions retained; no numerical uncertainty supplied |
| Total abundance | Sum of all Table 6.20a age groups, thousand fish | Derived source output; no invented joint uncertainty |

Survey timing fractions are winter 0.12, ecosystem 0.75, Russian autumn 0.90
and deep pelagic 0.67, from framework working document 4. The framework fixes
ecosystem survey scaling at 1/3500 under its native units. The 2026 tables
report millions; current production input conversions have not been recovered.
That coefficient must not be copied into a translation without reconciling units.

Printed dashes remain missing. Six Russian-survey cells contain `+` without
a numerical definition; they remain missing with a cell-specific note, not
zero. Rows marked “No age reading” remain missing. Published zeros stay zero.
The fitted observation cell selections and weights are not fully resolved.

## Validation and unit conflict

Source checks cover off-diagonal year/age cells, fixed biological vectors,
fleet overlap, survey timing and year basis, missing values, age coverage and
units. Reconstructed F is checked against both native F summaries using a
bound based on the printed three-decimal precision. The original fleet
coefficients and selectivities remain available to reproduce the calculation.

An additional cohort-survival check detects a small systematic precision
difference: unselected young-age N trajectories imply M approximately 0.04979,
whereas the report states 0.05. The reported two-decimal input is retained;
the native configuration is needed to establish its exact value. Cohort
consistency is checked at the precision of all published quantities, not by
replacing M with a value inferred from fitted N.

Table 6.21 labels age-6 recruitment “thousands”, but its values match Table
6.20a age-6 N divided by 1,000: for example, 2025 N is 591,807 thousand fish,
whereas the summary gives 592. The raw summary and its reported unit are
retained as `recruitment_age6_reported`, with the inconsistency flagged. It
does not populate standard recruitment. The age-2 summary agrees with N in
millions; an eventual age-6 comparison should use same-year official N6.
No SEs or intervals have been inferred from these point estimates.

## Limited tinyAM translation

The maintained recipe is
`scripts/translation/stocks/jrn_redfish_beaked_2026.R`. It fits 1992–2025
at ages 6–19+, using the non-overlapping total catch-at-age series once,
fixed M = 0.05, published age-6+ weight and maturity, and the ecosystem and
winter number indices for ages 6–15. The million-fish indices are converted
to thousand fish by the shared observation converter. It does not alter
observations using fitted q. The source's age-2 recruitment is not represented
or renamed as tinyAM recruitment; entry at age 6 is an age-range boundary.

The source framework says the ecosystem and winter survey selectivity is high
for young fish and declines at older ages. The tinyAM recipe estimates a
separate intercept and log-linear age effect for each survey. This allows a
decline and is a compact approximation to the source's survey-specific
selectivity curves. The source fleet structure, selectivity processes,
catch-weight likelihood, and observation weights are not represented.

The default-start fit converged and its Hessian was positive definite. It had
41 fixed effects, 509 random effects, an objective of 1031.742, and a maximum
absolute gradient of 0.00134. The optimizer returned code 0 with relative
convergence (4), and uncertainty estimation succeeded. Residual checks still
flagged some age/series groups with standardized residual spread outside
0.5–1.5 and some residuals above three standard deviations. Numerical
convergence is not evidence of close replication.

| Comparison | Status | Median absolute percent difference | Terminal mean percent difference | Trend correlation |
|---|---|---:|---:|---:|
| N at ages 6–19+ | Approximate | 31.6% | -44.9% | 0.926 |
| F at ages 6–19+ | Approximate | 55.8% | +85.9% | 0.819 |
| Fbar, ages 12–18 | Approximate | 38.4% | +90.5% | 0.790 |
| SSB, common definition at ages 6–19+ | Approximate | 46.4% | -50.7% | 0.983 |

The common-definition source SSB is calculated without uncertainty from
reported age-6+ N, fixed weight and maturity. The source's native SSB remains
available in the dashboard. Fixed M is shown as an input-consistency check;
its agreement is not evidence of estimated-M performance. Recruitment and
whole-stock abundance or biomass are non-equivalent because tinyAM starts at
age 6. Age-specific biomass is unavailable from the source outputs.

The dashboard and fitted object are cached locally under
`results/cache/jrn_redfish_beaked_2026/`; they are generated outputs and are
not committed.

## Remaining source and translation gaps

1. Numerical model weights and current maturity at ages 2–5 are unpublished.
   The framework describes young-age biology but does not supply the complete
   current numerical vector. The limited fit therefore starts at age 6 and
   cannot reproduce the full age-2+ population model.
2. Table 6.19 contains aggregate deep-pelagic survey comparisons and means,
   **not** a numerical age-composition table. The age curves are Figure 6.14;
   numerical likelihood compositions and age-block weights remain unavailable.
3. The total and outside-EEZ pelagic catch tables overlap. Their exact assembly
   into the two source fleet likelihoods must be recovered for a closer
   source-faithful translation; the current approximation uses total catch once.
4. Current production observation selection, variance settings and the full
   native configuration have not been recovered. The source's published
   survey-selectivity shape is represented by an estimated log-linear age
   trend in tinyAM. Survey coverage and species-identification qualifications
   in the source still apply.
5. Aggregated 19+ reporting does not recover the source's explicit older-age
   state and biological surfaces. Native SSB is retained; no claim is made that
   it can be reconstructed exactly from the incomplete published biology.

The partial import supports a restricted, converged age-6+ approximation and
dashboard, not a source-faithful age-2+ replication. The source completeness
statuses remain partial, and the substantial F and SSB scale differences
should remain visible in any use of this comparison.
