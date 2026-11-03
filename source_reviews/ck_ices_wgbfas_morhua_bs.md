# Western Baltic cod assessment history

## Current assessment: WBCod2026

The [WGBFAS 2026 report](https://literatur.thuenen.de/digbib_extern/dn071152.pdf), section 2.3, identifies the 2026 SAM update for cod in subdivisions 22–24. The assessment record uses 2025 as the terminal catch year and 2026 as the terminal estimate year. The report classifies it as category 3: because mortality is uncertain, ICES relies on relative SSB and recruitment trends and uses harvest rate instead of F for advice. The 2025 assessment remains in the database as a historical run.

The 2026 report is cached under `source_cache/ices_cod_western_baltic_2026/`; its SHA-256 is `7e8a6ac51f72abf7d1f026e0997f764267f07690cb2b78e32e073e13fd658732`. Catch-at-age is reported for ages 1–7+ in 1985–2025 (Table 2.3.15). Landings weights cover ages 1–7+ for 1985–2025, with 2025 age-7+ missing (Table 2.3.16); discard weights cover ages 3–7+ in 2015–2025, with a three-year average marked for some cells (Table 2.3.17); combined catch weights cover ages 1–7+ in 1985–2025, with age-7+ absent in 2024–2025 (Table 2.3.18). Stock weights cover ages 0–7+ in 1985–2025, with age-7+ absent in 2024–2025 (Table 2.3.19). Fixed maturity is reported for ages 1–7+ in 1998–2025 (Table 2.3.20), and an age-specific M vector is reported for 1985–2025 (Table 2.3.21). Missing terminal cells were left missing; values are rounded as published.

The published BITS Q1 series covers ages 1–4 in 1996–2026 and BITS Q4 ages 0–4 in 1999–2025; FEJUCS covers age 0 in 2011–2025 except 2012 (Tables 2.3.22a–c). The report says the assessment uses BITS Q1 in 2001–2026, BITS Q4 in 2001–2025 and FEJUCS in 2011–2025. The final BITS age row is pooled 4+, not age 4 alone; earlier published values are retained in the database but are not model observations. The report gives quarter labels but not exact within-quarter sampling fractions or a physical index multiplier. The public stockassessment.org index lists a WBCod2026 directory, but downloading run/model.RData through fitfromweb() failed with a peer receive error on 2026-10-27; the native fit and likelihood configuration therefore remain unverified, not confirmed absent.

Published outputs include SSB, age-1 recruitment and total stock biomass for 1985–2026 (Table 2.3.23); numbers-at-age 0–7+ (Table 2.3.24); total mortality by ages 1–4 and pooled ages 5–7 (Table 2.3.25); and C/SSB harvest rate (Table 2.3.26). The summary mortality column is labeled Fbar(3–5), but the table caption and report text call it Zbar(3–5); it is stored as total mortality with this conflict documented. The reported summary bounds are retained as low/high; the interval level is not stated, and SEs were not inferred. The 2026 age-0 N cell is absent from the published table and was not reconstructed. No age-specific F output is provided.

All three completeness fields remain partial. Report tables provide valuable numerical inputs and outputs, but native SAM input rows, exact likelihood weights/settings, precise survey timing, and an unambiguous F summary are unavailable. The 2026 outputs should be interpreted as relative-trend indicators under the report's category-3 caveat.

## tinyAM 2026 comparison

The restricted recipe uses 1985–2023 and ages 1–7+. This avoids missing age-0 maturity and the missing age-7+ stock weights in 2024–2025. It retains BITS Q1 and Q4 for 2001–2023 at ages 1–3; the reported age-4 row is pooled 4+ and is not treated as a single age. FEJUCS is omitted because it indexes age 0. Survey timing is carried forward from the 2025 native SAM fit (Q1 0.1653494, Q4 0.8477816) because the 2026 report does not provide within-quarter fractions. SSB is calculated at the start of the year by setting spawning time to zero. The fitted model uses IID N and F processes, IID age-1 recruitment, fixed source M, and the package's default initialization; no source-based starting values were used.

The default fit passed numerical checks: optimizer code 0, objective 455.812, maximum absolute gradient 0.00066, successful uncertainty estimation, and a positive-definite Hessian (23 fixed and 539 random effects). `check_tam()` also flagged residual spreads outside its reference range, large standardized residuals, and adjacent-year residual correlation in some groups.

Over the common 1985–2023 period, mean absolute percent differences were 17.5% for N-at-age, 13.1% for total abundance, 14.0% for recruitment, and 14.5% for approximate SSB. Their trend correlations were 0.952, 0.980, 0.970 and 0.980, respectively. At 2023, tinyAM was 62.3% lower for the mean age-specific N comparison, 14.0% lower for total abundance, 4.5% lower for recruitment and 6.7% lower for approximate SSB. Total biomass had a 14.0% mean absolute percent difference and 0.984 trend correlation, but was 54.7% lower in 2023. Fixed M-at-age matches by construction; F-at-age and Fbar are unavailable from the report. The SSB comparison is approximate because age 0 is excluded. These results are a restricted comparison to published trend estimates, not a reconstruction of the unverified WBCod2026 SAM fit. The dashboard is cached locally at `results/cache/ices_cod_western_baltic_2026/dashboard.html`.

## Previous detailed run: WBCod2025

The 2025 WGBFAS assessment and its native SAM files remain separately documented below. It was the latest detailed run before the 2026 update and is retained as historical source data; its observations and outputs are not combined with the 2026 report tables. The existing tinyAM translation and dashboard refer to this 2025 run only.

## Source selection

The WGBFAS 2025 report documents the assessment run `WBCod2025`. The report and
the linked SAM input/configuration files provide detailed observations,
biological inputs, fitted population outputs and settings. The source stock is
ICES cod in subdivisions 22–24 (`cod.27.22-24`). The selected run has catch
observations through 2024 and fitted population estimates through 2025. The
2025 age-0 population is not reported; age-1 recruitment is reported for 2025.

Sources:

- [ICES WGBFAS 2025 report, DOI 10.17895/ices.pub.29099786](https://doi.org/10.17895/ices.pub.29099786), western Baltic cod section 2.3, especially Tables 2.3.15 and 2.3.17–2.3.26.
- [ICES WKBALTCOD2 benchmark, DOI 10.17895/ices.pub.4984](https://doi.org/10.17895/ices.pub.4984).
- [ICES advice, DOI 10.17895/ices.advice.27202560](https://doi.org/10.17895/ices.advice.27202560).
- [Official ICES TAF repository](https://github.com/ices-advice/2025_cod.27.22-24), pinned locally at commit `093cc29bf0e4d47b89adfb209348adc946041b3f`.
- [SAM data and configuration for `WBCod2025`](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/WBCod2025/), cached locally with the fitted object returned by `stockassessment::fitfromweb("WBCod2025")`.

The report identifies the assessment as uncertain because mortality data are
incomplete. It states that indices are used for SSB and recruitment and that
harvest rate is used instead of F for advice. The fitted SAM object still
contains its estimated F surface; it is retained as a model output but must not
be read as an equally reliable advice quantity.

## Inputs and settings

The fitted SAM object covers 1985–2025 and ages 0–7. Total catch-at-age covers
1985–2024, ages 1–7+, in thousand fish; the source model omits unavailable
catch-age cells. The observation likelihood weight is 1 through 2019 and 0.1
for catch observations in 2020–2024. The public report does not explain this
weight change, so the native weight values are preserved without converting
them to an assumed SD or precision multiplier.

The three survey series are BITS Q4 (ages 0–4+, 1999–2024), BITS Q1 (ages
1–4+, 1996–2025) and FEJUCS pound net (age 0, 2011–2024; 2012 is missing).
The report describes the BITS observations as CPUE indices. It does not give a
physical scale multiplier, so native SAM index units are retained. The fitted
sampling times are 0.8477816, 0.1653494 and 0.85, respectively. BITS Q1 has
correlated age residuals in the SAM configuration; tinyAM uses independent
survey residuals.

Natural mortality is fixed at 1985–2024 values from Table 2.3.21: ages 0–7+
are 1.318, 0.598, 0.411, 0.324, 0.274, 0.241, 0.218 and 0.201 per year.
The SAM input surface also supplies 2025 values. Stock, catch, landings and
discard weights, maturity, landings fractions and pre-spawning F/M fractions
are extracted from the native fit data and retained without interpolation.
The report defines SSB at the start of the year; pre-spawning F and M fractions
are zero. Maturity is a fixed ogive in the model, documented in Table 2.3.20.

SAM uses an age-1 recruitment state, an age-0 to age-7 population surface,
age-specific log-F states with ages 5–7 sharing one state, and a shared F
process variance. The SAM configuration has no F residual correlation. The
N-process variance is separate for age 0 and ages 1–7. Catch observation
variance is separate for age 1 versus ages 2–7. BITS Q4 and Q1 have the
survey-age variance-sharing groups in the model configuration; Q1 age residuals
are correlated. Catchability is estimated by survey and age where the SAM
configuration includes a parameter.

## Outputs and checks

The canonical outputs retain native SAM N-at-age, the fitted F states,
recruitment at age 1, SSB, total stock biomass, Fbar for ages 3–5, catch/index
predictions and q where available. Conditional random-effect uncertainty for
N-at-age and F is stored as natural-scale delta-method SEs with 95% log-Wald
intervals; the source report does not publish these age-specific intervals.
The report's Tables 2.3.25–2.3.26 provide grouped total mortality and harvest
rate, respectively; those rounded table values are retained as separate native
outputs. Total abundance is derived from N-at-age, with uncertainty left
blank.

The cached SAM fit converges with optimizer code 0, positive-definite Hessian,
and maximum absolute fixed-effect gradient below `4e-12`. Its 2024–2025 age-1
recruitment, SSB, Fbar and TSB reproduce the rounded values in Table 2.3.23.
The fitted object includes a 2025 age-0 state that is not reported in Table
2.3.24; that unavailable table cell is not imported as a source estimate.

The tinyAM translation uses an IID recruitment process and cohort deviations,
IID F states, fixed source M, source survey timings and survey-by-age q groups.
It cannot reproduce SAM's joint survey residual correlation, native catch
observation weights, or the exact initial-state and process parameterization.
tinyAM estimates F at age 0, whereas the source has no F state at age 0. These
are recorded as approximations; no observations are adjusted to improve
agreement.

The source PDF, extracted text, raw `.dat` inputs, configuration, selected TAF
revision and fitted SAM object are cached under the gitignored
`source_cache/ices_cod_western_baltic_2025/` directory. The local manifest
records retrieval dates, checksums and source URLs.

## tinyAM fit result

The default-initialized tinyAM fit passed numerical checks: optimizer code 0,
objective 671.63, maximum absolute gradient 0.000356, successful uncertainty
report, and a positive-definite Hessian (29 fixed and 648 random effects). The
fit did not use source-based starting values.

Over common years, mean absolute percent differences were 16.9% for matched
SSB, 15.5% for derived total abundance, 16.1% for total biomass, and 18.4% for
N-at-age. Their annual trend correlations were 0.98, 0.98, 0.98, and 0.96,
respectively. However, at the terminal comparison year 2024, tinyAM was 70.5%
lower for SSB, 31.1% lower for total abundance, and 58.1% lower for total
biomass. Same-year age-0 recruitment is an approximate comparison and was
26.1% lower in 2024. Fixed M matches by construction; F and Fbar are not
like-for-like with the SAM age-state definitions. Convergence therefore does
not imply close terminal agreement. The exploratory comparison is available
in the local cached dashboard at
`results/cache/ices_cod_western_baltic_2025/dashboard.html`.
