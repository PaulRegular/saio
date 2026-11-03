# North Sea autumn-spawning herring: 2026 source review

Source verification: 2026-10-02.  
Translation revision: 2026-10-14.

Status: canonical record `ices_herring_north_sea_2026` imported; inputs, outputs and assumptions remain partial.

Charbonneau identifier: `ICES-HAWG_ NS-IV 3a,7d_Clupea_harengus`.

Stock: `her.27.3a47d`, North Sea, Skagerrak/Kattegat and eastern English Channel.

## Current source trail

Official detailed report: ICES 2026 HAWG, 8:16, DOI [10.17895/ices.pub.31424315](https://doi.org/10.17895/ices.pub.31424315).

The complete 892-page final report is cached from its [DTU author repository](https://backend.orbit.dtu.dk/ws/portalfiles/portal/440308463/HAWG_2026_-_Full_Report.pdf).

The report identifies 2025 SSB near 1.68 million tonnes and F ages 2–6 near 0.191. These provide official-run checks, not substitutes for native time series.

Current official reproducible repository: [ices-advice/2026_her.27.3a47d](https://github.com/ices-advice/2026_her.27.3a47d).

Pinned inspected revision: `d2690dac28a0b44f1735193cf8c7c87fe8fcbbbe`.

The repository tree and relevant scripts are cached in `source_cache/ices_herring_north_sea_2026/`. The local manifest records cached filenames, source URLs, SHA-256 checksums and verification dates. Retrieval dates were not recorded for all pre-existing cached files.

The older `ICES-dk/wg_HAWG` repository contains historical NSAS artifacts and is not used as the current-run source.

The TAF `model.R` executes separate single-fleet and multifleet scripts. `model_sf.R` explicitly names `NSAS_HAWG2026_sf`.

A direct lookup under stockassessment.org user3 returned HTTP 404. This does not establish that the fitted object is unavailable under another account or through TAF archives.

The repository contains scripts but no native RData objects in its tracked tree. Its `DATA.bib` retains some older date ranges, whereas the model scripts reflect the current assessment. Native inputs and terminal years must therefore be verified independently of the bibliography.

The official historical record is the single-fleet assessment. The multifleet model supports fleet-wise forecasts and is not substituted for the historical official assessment.

No native current fitted object or public TAF artifact was recovered. Report tables provide the numerical historical assessment record, with forecast values kept separate.

## Official-model inventory

The historical assessment is a single-fleet FLSAM model with one combined commercial catch fleet.

Report Table 2.6.2.7 specifies:

- Model years 1947–2026.
- Ages 0–8 winter rings, with age 8 as the plus group.
- Recruitment at age 0.
- Fbar over ages 2–6.
- Eight fitted index streams: HERAS, IBTS-Q1, IBTS0, IBTS-Q3, LAI-ORSH, LAI-BUN, LAI-CNS and LAI-SNS.

The ages represent winter-ring classes and should not silently be interpreted as conventional chronological ages.

The pinned code trims HERAS to ages 1–8+, IBTS-Q1 to age 1 and IBTS-Q3 to ages 0–5. This resolves a discrepancy with abbreviated report prose listing only IBTS-Q3 ages 2–5.

The four larval abundance indices have FLSAM fleet type 6, representing partial spawning-component likelihoods. They contain regional spawning information and share catchability and logP process parameters. They are not conventional abundance-at-age observations.

All four LAI sampling fractions are explicitly 0.67 in `data_construct_input.R`.

The official `fleet.txt` was unavailable. Approximate seasonal midpoints are recorded for HERAS, IBTS-Q1, IBTS0 and IBTS-Q3. LAI sampling times retain their configured value of 0.67.

### Observation coverage

Table 2.6.1.1 reports the following fitted coverage:

- LAI: 1973–2025.
- IBTS-Q1: 1984–2026.
- IBTS-Q3: 1998–2025.
- HERAS age 1: 1997–2025; older HERAS ages: 1989–2025.
- IBTS0: 1992–2026.

The report contains numerical catch, natural mortality, maturity, weights, survey inputs, population and fishing-mortality outputs, and summary uncertainty in Tables 2.6.1.2–14 and 2.6.2.1–7.

Some adjacent narrative paragraphs contain earlier-year values. Explicitly labelled final numerical tables are used for the official assessment record.

### Population and fishing-mortality processes

Recruitment is represented separately from survival of older cohorts.

The official model has a distinct recruitment-process variance for age 0 and one shared older-age survival-process variance for ages 1–8.

The F process uses random-walk dynamics with AR(1) correlation across ages in annual fishing-mortality increments (`cor.F = 2`).

The official F configuration has separate states for ages 0–6 and a shared state for ages 7–8.

Innovation variances are grouped over ages 0–1, 2–5 and 6–8.

These groupings describe distinct features of the official model: the oldest ages share a latent F state, while the variance groups determine how annual innovations are penalized.

### Observation models

The official assessment has age-specific catchability and observation-error sharing groups.

HERAS catchability is shared over ages 1–2 and ages 3–8. The four larval indices share one catchability parameter.

Three logP variance parameters are printed in the native control configuration. Their precise statistical interpretation requires the relevant FLSAM implementation or framework documentation.

The pinned single-fleet configuration specifies an AR observation-error structure for IBTS-Q3; other fitted index observation flags are independent.

No power-law catchability parameters are configured.

### Biological inputs

The assessment imports natural mortality from the SMS-2023 construction, with an additional 0.02 applied in the official model script.

The report's numerical M table covers 1947–2025. It is retained as published, without reconstructing values from the model scripts.

The report describes three-year outer-year averaging, but the pinned construction script specifies a five-year window. This inconsistency is recorded rather than resolved through an inferred transformation.

The final M convention used by the official model must be distinguished from the underlying SMS numerical surface to avoid applying the 0.02 adjustment twice.

Annual stock and catch weights and maturity are available through 2025. The complete 2026 biological inputs are not available in the published tables.

## tinyAM translation revision (2026-10-14)

The tinyAM translation was revised to more closely approximate the official assessment's population and fishing-mortality process structures.

The previous translation used random-walk cohort-survival deviations and independent age-specific F random walks. The revised translation uses independent cohort-survival deviations and correlated F random walks.

The translated model retains the same fitted period, population ages, biological inputs and selected survey streams.

### Population process

The revised model specifies:

`N_settings = list(process = "iid", init = "free")`

Older-cohort survival deviations are independent rather than following a random walk.

Recruitment retains the separate random-walk process specified by the default tinyAM recruitment settings. Changing `N_settings$process` to `iid` does not change recruitment to IID.

Initial abundance for older ages is freely estimated.

The revised model uses one shared SD for older-cohort survival deviations. This broadly matches the separation between recruitment and older-age survival variation in the official assessment, but does not reproduce every aspect of FLSAM's state initialization or process specification.

The official N and F estimates are used as optimizer starting values only. They do not constrain the fitted tinyAM states.

### Fishing-mortality process

The revised model specifies:

`F_settings = list(process = "cor_rw", mu_form = NULL, mean_ages = 2:6)`

This replaces independent F random walks with correlated random walks.

The `cor_rw` process estimates annual changes in log fishing mortality with AR(1) correlation across neighbouring ages. It therefore captures a central feature of the official FLSAM fishing-mortality process that was missing from the previous translation.

The distinction is important: correlation applies to annual F increments across ages, not simply to the absolute F levels.

The revised tinyAM model remains simpler than the official FLSAM configuration in two respects:

- It uses one shared F-process SD rather than the source's three innovation-variance groups for ages 0–1, 2–5 and 6–8.
- It retains separate F states at ages 7 and 8 rather than imposing the source's shared oldest-age F state.

Fbar is calculated over ages 2–6, consistent with the official assessment.

The revised specification improves structural agreement without reproducing the complete FLSAM covariance and age-sharing configuration.

### Natural mortality

The translation specifies:

`M_settings = list(process = "off", mu_form = NULL, mu_supplied = ~M_assumption)`

The translated numerical M surface is treated as fixed. The fitting period ends in 2025, when the published biological inputs remain available.

The official SMS-2023 surface and additional 0.02 adjustment must be represented consistently with the imported numerical values. No separate mortality process is estimated in tinyAM.

### Commercial catch

The translation retains direct commercial catch-at-age observations for the common fitted period, retaining counts in thousand fish.

The catch observation model uses:

`catch_settings = list(sd_form = ~0 + sd_block)`

This permits separate estimated observation SDs for the translated catch groups.

The fishery closure in 1978–1979 is represented by missing catch observations, consistent with the official input construction.

Positive catch observations are fitted using a lognormal likelihood. Exact zeros are not fitted as positive lognormal observations.

The translation does not claim to reproduce every feature of the official catch observation model.

### Survey indices

The tinyAM translation retains HERAS, IBTS-Q1, IBTS0 and IBTS-Q3.

The four larval abundance indices are omitted because their partial spawning-component likelihoods are not equivalent to ordinary abundance-at-age indices.

The revised survey model specifies:

`index_settings = list(q_form = ~0 + q_key, sd_form = ~0 + sd_block)`

This retains the translated survey-age catchability-sharing groups and observation-SD groups.

Catchability is freely estimated within those groups. No monotone or logistic age constraint is imposed.

The source's cross-age observation-error correlation for IBTS-Q3 is not represented.

Survey observations retain their published numerical scales. Because their calibrated units have not been independently established, estimated catchability absorbs differences in index scale.

Sampling times remain documented approximations based on survey seasons, because the official `fleet.txt` was unavailable.

### Spawning-stock biomass

The official assessment reports spawning-stock biomass under its native spawning-time convention.

tinyAM calculates SSB using the translated stock weights, maturity and fitted abundance under tinyAM's spawning-time convention.

The official spawning fractions were not recovered. Consequently, native SSB and translated SSB definitions may not be exactly equivalent.

Comparisons should retain this caveat even when the estimated trajectories agree closely.

### Interpretation of the revision

The revision makes the two principal population processes more consistent with the official FLSAM structure without adding stock-specific process complexity.

The improvement is attributable to scientifically motivated changes in the survival and fishing-mortality process assumptions, rather than changes to the official assessment data.

The translation remains an approximation. In particular, the four omitted larval indices, approximate survey timing, incomplete F age-sharing and variance groups, and differences in observation-error covariance may influence the fitted population states.

The revised model's numerical convergence and comparison statistics should be evaluated separately from the previous random-walk N and independent F random-walk configuration.

## Report-table staging and configuration checks

The source-specific staging extraction retains 6,131 report-native values in `source_cache/ices_herring_north_sea_2026/report_tables_raw.csv`.

Tables 2.6.1.2–6 cover 1947–2025; the N and F surfaces in Tables 2.6.2.3–4 extend through 2026.

These staging values are not canonical imports.

Missing catch entries in 1978–1979 are printed as dots and remain missing. Survey `-1` sentinels are retained in staging for explicit interpretation during import.

Table 2.6.1.6 is captioned catch weight, but its values and accompanying narrative identify catch numbers. It must not be imported as catch weight based solely on the caption.

The current printed control configuration confirms eight unique catch F states, with ages 7 and 8 sharing a state.

The N process variance is separate for recruitment and shared across ages 1–8. F innovation variances are shared over ages 0–1, 2–5 and 6–8.

The pinned single-fleet configuration specifies `cor.F = 2` and an AR observation structure for IBTS-Q3, with independent observation flags for the other fitted indices.

HERAS q is shared over ages 1–2 and 3–8. The four larval streams share one q parameter.

The official F and N surfaces extend into 2026, whereas catch and annual biological input tables end in 2025. Q1 and IBTS0 indices include 2026 observations.

The final 2026 M input and biological-surface construction remain unresolved.

### TAF access

A public TAF access check on 2026-10-02 found that `https://taf.ices.dk` redirected to the ICES homepage and `https://taf.ices.dk/app/stock` returned 404.

The official `ices-tools-prod/icesTAF` package continued to construct the `https://taf.ices.dk/api/Artifacts` endpoint in the inspected version.

A request for year 2026 and stock `her.27.3a47d` also returned 404 without authentication.

This is a limitation of the inspected public source trail, not proof that the native model object is unavailable through all channels.

No credentials were requested or used. Portal responses and the source-specific extraction script remain cached.

Report tables are retained as the numerical fallback. Earlier-run TAF artifacts are not substituted for current official estimates.

### Summary-table verification

The wrapped summary Table 2.6.2.6 was extracted for all 80 years, 1947–2026, including published lower and upper intervals, into `report_summary_raw.csv`.

Recruitment equals the reported age-0 abundance exactly in every year.

Mean F over ages 2–6 agrees with the published Fbar within 0.0006, allowing for rounding in the four-significant-digit table entries.

Verification uses the reported numerical values directly and does not overwrite them with recalculated quantities.

The source `data_construct_input.R` explicitly deletes catch observations for 1978–1979, consistent with the report's missing values.

Zero catches in other years are distinct published values, although their native likelihood treatment requires implementation verification.

Catch-at-age is reported directly; catch proportions or reconstructed landings series are not used as substitutes.

## Larval starting-year discrepancy

The pinned `data_construct_input.R` calls `formatLAI(..., 1972, ...)` for all four larval streams.

The `utilities_data.R` function converts source years to calendar years by adding 1900 and fills missing years; it does not shift years or remove 1972.

No explicit 1973 trim was found in the cached model and control scripts.

This conflicts with the fitted-coverage table, which reports LAI observations beginning in 1973.

Canonical records currently follow the published fitted coverage and retain 1972 only in the source cache.

The native fitted object or FLSAM partial-index likelihood should be inspected before changing the canonical series or declaring input completeness.

## Remaining translation limitations

The revised translation is closer to the official FLSAM process structure, but it is not an exact reproduction.

The main remaining differences are:

- **Observation coverage:** Four regional larval indices and their partial spawning-component likelihoods are omitted.
- **Fishing mortality:** Correlated random-walk increments are represented, but the official age-specific variance sharing and common F state at ages 7–8 are not.
- **Observation errors:** The official IBTS-Q3 cross-age correlation is omitted.
- **Survey timing:** Sampling fractions for the four age-structured indices are approximations, not independently recovered native values.
- **SSB definition:** Official spawning-time fractions remain unavailable.
- **Native assessment recovery:** Complete current-run FLSAM inputs and fitted objects have not been recovered for a direct likelihood-level comparison.

These are documented limitations of the simplified translation, not errors in the official assessment.

## Record summary

The canonical record represents the official 2026 North Sea autumn-spawning herring single-fleet FLSAM assessment.

The source tables and documented model configuration support the historical 1947–2025 translation and comparisons, while official numerical outputs also extend into 2026.

The revised tinyAM model uses IID cohort-survival deviations, free initial abundance, correlated F random walks, fixed supplied natural mortality, and translated observation-error groups.

These settings more closely approximate the official assessment's core population dynamics than the previous translation.

The case tests whether a comparatively simple age-structured state-space model can recover broad official stock dynamics without reproducing the complete FLSAM observation likelihood, state-sharing configuration or biological uncertainty.

The source-review and completeness statuses remain partial pending recovery or verification of the unresolved native-model details.
