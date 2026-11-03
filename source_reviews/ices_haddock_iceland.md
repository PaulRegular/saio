# Icelandic haddock (had.27.5a)

Translation revision: 2026-10-14.

## Assessment record

The 2025 benchmark is retained as a historical assessment record. The 2026 official assessment is now the current detailed record; see [the 2026 source review](ices_haddock_iceland_2026.md). The two runs retain separate inputs and outputs.

The 2025 benchmark replaced the previous assessment framework with the state-space assessment model (SAM). The assessment uses catch numbers-at-age, catch weights, stock weights, maturity, spring and autumn survey indices-at-age, and estimated abundance and fishing mortality-at-age.

The assessment covers ages 1–12+, with age 12 as the plus group. Detailed catch and biological input tables end in 2024, while population estimates extend through 2025. The canonical database records 1979–2024 as the detailed fitted input period and retains the 2025 estimates separately.

The 2026 MFRI report confirms that the assessment continues to use the 2025 benchmark framework, fixes natural mortality at 0.2, and allows selectivity-at-age to vary over time.

The 2026 age-specific input and output matrices are documented separately in the 2026 source review. No 2026 values are substituted into this 2025 record.

## Inputs and assumptions

- **Catch:** Commercial catch-at-age is reported directly in thousands of fish, ages 1–12+.
- **Weights:** Catch weights come from commercial samples. Stock weights are derived from the March survey.
- **Maturity:** Maturity-at-age comes from the March survey. The source reports that pre-1985 stock-weight and maturity vectors use 1985 values.
- **Spring survey:** IS-SMB, March, 1985–2025.
- **Autumn survey:** IS-SMH, October, 1995–2024.
- **Survey units:** Official tables label indices as numbers but do not establish calibrated physical units. Values are retained on their native scales.
- **Survey timing:** The translation records 0.20 for March and 0.80 for October, based on survey months. These are approximations, not verified native SAM sampling fractions.
- **Natural mortality:** Fixed at 0.2 per year for all ages.
- **Spawning timing:** The official assessment uses pre-spawning mortality fractions of 0.4 for F and 0.3 for M.
- **Outputs:** Summary tables provide recruitment, SSB and length-based reference biomass, with reported uncertainty. Age-specific output uncertainty was not recovered.

The 2025 record also includes total abundance derived by summing the reported
numbers-at-age across ages 1–11 and the 12+ group for each year, 1979–2025.
No uncertainty is calculated for this sum. The newer 2026 record remains
separate and has its own reported age-specific population series.

The official reference biomass represents fish measuring at least 45 cm and is distinct from total age-structured biomass.

## tinyAM translation revision (2026-10-14)

The translation was revised to improve numerical performance and better represent time-varying fishing mortality.

The previous configuration used IID cohort-survival deviations and a stationary AR1 F process around estimated age-specific mean fishing mortality.

The revised configuration retains the IID survival process and replaces stationary AR1 F with correlated random walks.

### Population and recruitment

The revised model specifies:

`N_settings = list(process = "iid", init = "free")`

This uses independent deviations from expected cohort survival, with freely estimated initial abundance for older ages.

Recruitment remains a separate random-walk process under tinyAM's default recruitment settings. Specifying `process = "iid"` for N does not imply IID recruitment.

The official SAM model also estimates abundance and recruitment as latent states, but its precise process covariance, variance sharing and initial-state conventions have not been fully reconstructed in the canonical record.

The translation therefore retains a simpler population-process specification.

### Fishing mortality

The principal revision is:

`F_settings = list(process = "cor_rw", mu_form = NULL)`

This replaces the earlier configuration:

`F_settings = list(process = "ar1", mu_form = ~factor(age))`

The previous AR1 process described fishing mortality fluctuating around estimated age-specific means, with deviations tending to return toward those means.

The revised correlated random walk allows annual changes in log fishing mortality to accumulate over time. The annual increments are correlated across neighbouring ages through an estimated AR(1) age-correlation parameter.

This provides a flexible representation of changing fishing mortality and selectivity-at-age without requiring an estimated stationary mean F curve.

The official 2025 benchmark SAM likewise allows fishing selectivity to vary over time. The revised tinyAM structure is therefore a plausible approximation of the official assessment's temporal flexibility.

However, the precise official SAM F-process covariance, variance-sharing keys and age-state sharing have not been independently verified for this translation. The use of `cor_rw` should not be described as an exact reconstruction of those settings.

### Natural mortality

The translation retains:

`M_settings = list(process = "off", mu_form = NULL, mu_supplied = ~M_assumption)`

Natural mortality is supplied as a fixed value of 0.2 across ages and years, matching the official assumption.

No additional M process is estimated.

### Catch observations

The translation uses:

`catch_settings = list(sd_form = ~1)`

Commercial catch numbers-at-age are retained and fitted with one estimated lognormal observation SD.

Missing catch observations are not filled.

This is a simplified observation likelihood rather than a complete reproduction of the official SAM catch-error specification.

### Survey observations and catchability

The translation retains both the spring IS-SMB and autumn IS-SMH age-specific survey series.

The observation settings are:

`index_settings = list(q_form = ~0 + q_key, sd_form = ~0 + survey)`

Catchability is estimated separately for the translated survey-age groups, while observation SDs are estimated separately for the spring and autumn surveys.

The model does not impose monotone catchability or density-dependent catchability powers.

The survey indices remain on their published native scales. Their calibrated physical units were not recovered, and differences in index scale are absorbed through the estimated catchability parameters.

The translation uses approximate sampling fractions of 0.20 and 0.80. Exact timing and complete observation-error covariance equivalence with the official model remain unresolved.

### Biological inputs

The official annual stock weights, catch weights and maturity-at-age inputs are retained.

The source's early-year stock-weight and maturity substitutions are preserved.

No alternative biological surfaces are introduced as part of the revised model configuration.

### Spawning-stock biomass comparison

The official assessment calculates spawning-stock biomass after accounting for mortality before spawning.

Its published definition uses fractions of 0.4 for fishing mortality and 0.3 for natural mortality.

The current tinyAM translation does not apply those fractions when calculating mature biomass.

Consequently, the comparison summary uses a common-definition mature biomass calculated from the official population numbers and the same translated stock weights and maturity inputs used by tinyAM.

This quantity supports comparisons of estimated mature stock abundance but is not identical to the official assessment's native spawning-time SSB.

The official length-based reference biomass for fish of at least 45 cm is retained as a native output. It is not directly compared with tinyAM's total age-based biomass.

### Interpretation of the revision

The revision replaces a stationary fishing-mortality process with a correlated random walk, allowing more persistent temporal variation and age-correlated annual changes.

The N process, biological assumptions, survey selection and observation-error specifications remain unchanged.

The revised configuration improves the representation of temporally varying fishing mortality without adding stock-specific biological processes or extra observation streams.

The numerical fix and any improved agreement with official outputs should be documented using the newly generated convergence diagnostics and comparison summaries. No new numerical performance statistics are asserted in this source review.

## Remaining translation limitations

The principal differences between the official assessment and the revised tinyAM translation are:

- The exact official N and F process covariance and parameter-sharing structures have not been fully recovered.
- tinyAM uses a simplified catch and survey observation likelihood.
- Exact survey sampling fractions and calibrated survey-index units remain unavailable.
- Native spawning-time SSB differs from the common-definition mature biomass used for comparison.
- The official length-based reference biomass cannot be reproduced exactly from age-specific inputs.
- Full age-specific uncertainty from the official assessment was not recovered.

These differences describe the limits of the translation rather than problems with the official SAM assessment.

## Sources reviewed

- [MFRI 2025 assessment tables](https://dt.hafogvatn.is/astand/2025/2_HAD_en.html)
- [MFRI 2025 technical report](https://www.hafogvatn.is/static/extras/images/02-had_2025_techreport_en.html)
- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html)
- [ICES WKICEGAD 2025 benchmark report](https://doi.org/10.17895/ices.pub.28444499.v1)

The numerical MFRI table exports used for the 2025 record are cached under the gitignored `source_cache/iceland_haddock_2025/` directory. Their filenames and access notes are listed in that directory's README.

## Record summary

This historical record represents the 2025 benchmark SAM assessment for Icelandic haddock. The current detailed assessment is the separate 2026 run.

The revised tinyAM translation fits 1979–2024, ages 1–12+, with random-walk recruitment, IID cohort-survival deviations, free initial abundance, correlated F random walks and fixed natural mortality.

Catch and survey observations retain the source age structure and biological inputs, with simplified observation-error models and approximate survey timing.

The translation is intended to test whether a compact age-structured state-space model can reproduce broad official population dynamics without duplicating every feature of the official SAM configuration.
