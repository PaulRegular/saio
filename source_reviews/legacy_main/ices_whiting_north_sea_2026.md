# North Sea whiting source review

## Assessment and source

The represented assessment is the official 2026 SAM assessment for whiting (*Merlangius merlangus*) in ICES Subarea 4 and Division 7.d, stock code `whg.27.47d`. The assessment is described in the [WGNSSK 2026 report](https://doi.org/10.17895/ices.pub.32676345), with outputs available through [ICES Stock Assessment Graphs, key 22488](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22488). The [WKBW 2026 benchmark](https://doi.org/10.17895/ices.pub.32019630) documents recent model changes.

No Charbonneau–Keith identifier was confirmed in the curated catalogue; the stock is linked by its ICES code.

The official `NSwhiting_2026n` model and data objects, native input files, and report are cached under `analysis/comp_assessments/source_cache/ices_whiting_north_sea_2026/`. The cache is gitignored.

The report SHA-256 is `9d33846cf100dd8544ba30dbeffc7435a857a71854d318dbc7b383d668b03857`. The model object SHA-256 is `6bd2d93ad87b6cbbE6f479346d478796183a24befb6c2d87da97216b4ef5f6b8`, and the native data object SHA-256 is `689003079c3fede21befdf735d0af68b20a26e631d9ed9214ba06994e1b3914c`.

The import script is `scripts/database/049_import_ices_whiting_north_sea_2026.R`.

The April `NSwhiting_2026n` run is treated as official because its input data and fitted object reproduce published recruitment, SSB, Fbar, and TSB values for 1978–2025 in Table 22.22 to the table's rounding precision. Its calculated SSB also reproduces the reported 2026 intermediate-year value.

A later June `NSwhiting_2026n_updateIBTSQ1` variant is cached for reference, but its fitted annual series do not match the published 2026 assessment table and it is not used as the canonical run.

The selected model reports optimizer convergence code 0 (`relative convergence (4)`) and objective value 51.29096.

## Model structure and source data

The official SAM assessment spans ages 0–8+, with recruitment at age 0. Total catch numbers-at-age cover 1978–2025. The assessment also uses catch weight-at-age, annual stock weight, smoothed maturity, natural-mortality observations, and two research-vessel abundance indices.

The IBTS Q1 survey covers ages 1–6+ in 1983–2026, with sampling time 0.125. The IBTS Q3 survey covers ages 0–6+ in 1991–2025, with sampling time 0.625.

Catchability is estimated separately by survey and age, without density-dependent q power. The two survey observation processes use lognormal errors with AR(1) correlation across ages. Catch observations use independent lognormal errors with age-specific variance sharing.

The native survey indices are reported on an unscaled relative index scale, without a calibrated physical abundance unit. Their fitted relative precision weights and corresponding log-scale SD factors are retained in the canonical database.

Stock weights, catch weights, and maturity are used as known biological inputs. Stock weights and maturity use an age-6+ group, expanded over model ages 6–8. Maturity is estimated using Q1 information for 1991–2021, with the 1991 values held for earlier years and the 2021 values for later years.

WGSAM natural-mortality observations are available through 2022, with age 6+ grouped. The official SAM estimates natural mortality using a GMRF, including years beyond the available numerical observations.

The official assessment uses random-walk recruitment and survival processes with age-specific variance sharing, and a random-walk F process with AR(1) correlation between annual increments across ages. Fbar is calculated over ages 2–5.

The native SAM data contain `propF = 0` and `propM = 0`, specifying the mortality fractions before spawning. These are separate from survey sampling times.

## Survey precision detail

The native Q1 and Q3 CV files contain a leading `1`, followed by the six or seven age-labelled CV values shown in the report.

The official data script uses `stockassessment::read.ices()` and takes the first declared number of columns from these files. Consequently, the actual precision weights in `fit$data$weight` include the leading `1` as the first modelled age and omit the final age-labelled CV column.

This matches the official fit's stored precision weights and is how the fit is represented in the canonical database.

The age-labelled CV values from the original files are retained separately to document the distinction. They do not replace the fitted precision weights in the tinyAM translation.

## tinyAM translation revision (2026-10-14)

The translation was revised to better approximate the official SAM process structure.

The previous configuration used random-walk cohort-survival deviations and independent fishing-mortality random walks. The revised configuration uses:

- `N_settings = list(process = "iid", init = "exp")`
- `F_settings = list(process = "cor_rw", mu_form = NULL, mean_ages = 2:5)`
- `M_settings = list(process = "off", mu_supplied = ~M_assumption)`
- `catch_settings = list(sd_form = ~1)`
- `index_settings` with survey-by-age catchability, survey-specific baseline SDs, supplied relative SD factors, and no filling of missing observations.

The recruitment process remains a random walk under the default tinyAM recruitment settings, separate from the `N_settings` process. The `iid` N process describes independent deviations from expected cohort survival rather than a random walk in survival deviations.

The `latent` setting integrates older initial abundances without an initial
density. First-year recruitment remains an estimated fixed effect.

The F process now uses `cor_rw`, allowing AR(1) correlation across ages in annual log-F increments. This represents an important component of the official SAM fishing-mortality process that was absent from the earlier independent-RW translation.

The revised F process uses one shared increment SD. It is therefore a closer approximation to the source process but is not necessarily identical to the official model's complete variance specification.

Catch-at-age observation errors remain independent and use one shared lognormal SD, rather than the source's age-specific observation variance groups.

Survey observations retain their native timings and survey-by-age catchability groups. The revised model estimates separate baseline observation SDs for Q1 and Q3, modified by the relative SD factors recovered from the official SAM input. Unlike SAM, tinyAM does not model AR(1) correlation among survey residuals at adjacent ages.

The numerical M observations through 2022 are supplied directly. The final available M values are held fixed for 2023–2026 to provide the complete mortality surface required by the translation. Unlike SAM, tinyAM does not estimate a mortality GMRF.

An earlier attempt to estimate M in tinyAM resulted in non-finite optimizer gradients and was not retained. The fixed-M extension is a translation-only assumption and does not modify the official assessment database.

Official N and F estimates initialize the tinyAM population and fishing-mortality states. Initial survey catchability coefficients are derived from the observed indices and official N, F, and M estimates at the survey sampling times. These are starting values only, not constraints on the fitted states.

The revised process settings substantially change the translated model relative to the earlier baseline. Agreement and convergence statistics should be interpreted for the new configuration rather than carried forward from the previous translation.

## Remaining differences and limitations

Despite the closer alignment of fishing-mortality dynamics, several differences remain between tinyAM and the official SAM assessment.

**Survival process:** The official model uses random-walk survival deviations with age-specific variance sharing. The translation instead assumes IID cohort-survival deviations with one shared SD.

**Fishing-mortality process:** Both models now permit correlated annual F increments across ages, but their process covariance and variance-sharing configurations need not be identical.

**Natural mortality:** The official model estimates M through a GMRF. The translation uses fixed numerical M, including a constant extension of the 2022 values into 2023–2026.

**Catch observation errors:** tinyAM uses a single estimated catch observation SD rather than the source age-specific variance groups.

**Survey observation errors:** tinyAM retains survey-specific SDs and relative precision information but not the official AR(1) age correlation.

**Survey plus groups:** Both IBTS surveys report age 6 as a 6+ group, whereas the population model has an 8+ terminal group. The current translation treats these observations at age 6 rather than explicitly predicting the sum of survey-vulnerable abundance over ages 6–8+. This remains an observation-definition approximation that should be resolved or tested separately.

**Initial abundance:** Older initial ages now use latent states without an
initial density. The estimated fixed r0 anchor still differs from SAM.

These differences are documented limitations of an illustrative tinyAM translation, not corrections to the official SAM assessment.

## Comparison limits

The report publishes recruitment, SSB, Fbar, and total stock biomass point estimates and 95% intervals through 2025, with SSB alone reported for 2026.

The native fitted object contains 2026 age-specific state surfaces, which are retained as `native_model` outputs. The summary table leaves unreported 2026 recruitment, Fbar, and TSB values unavailable.

The age-specific output surfaces do not have report-published uncertainty intervals.

The official numerical inputs and fitted outputs remain unchanged in the canonical database. The carried-forward M assumption and process-model choices belong exclusively to the tinyAM translation.

The revised translation remains a proof-of-concept approximation of the official model. Numerical convergence and improved agreement do not establish equivalence of the underlying likelihoods or assessment uncertainty.

## Initial abundance

The cached official SAM fit has `initState = 0` and no `initN` parameters.
The translation uses `init = "latent"`: older first-year log-abundances are
integrated without an initial density. First-year recruitment remains an
estimated fixed effect, so this is not complete SAM initial-state equivalence.
