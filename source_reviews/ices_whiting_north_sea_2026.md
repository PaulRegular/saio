# North Sea whiting source review

## Assessment and source

The represented assessment is the official 2026 SAM assessment for whiting (*Merlangius merlangus*) in ICES Subarea 4 and Division 7.d, stock code `whg.27.47d`. The assessment is described in the [WGNSSK 2026 report](https://doi.org/10.17895/ices.pub.32676345), with outputs available through [ICES Stock Assessment Graphs, key 22488](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22488). The [WKBW 2026 benchmark](https://doi.org/10.17895/ices.pub.32019630) documents recent model changes.

No Charbonneau–Keith identifier was confirmed in the curated catalogue; the stock is linked by its ICES code.

The official `NSwhiting_2026n` model and data objects, native input files, and report are cached under `source_cache/ices_whiting_north_sea_2026/`. The cache is gitignored.

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

The age-labelled CV values from the original files are retained separately to document the distinction. They do not replace the fitted precision weights in the canonical record.

## Survey age groups

Both IBTS surveys report a terminal 6+ group, whereas the population model has an 8+ terminal group. The source survey observations retain their grouped-age definition.

## Comparison limits

The report publishes recruitment, SSB, Fbar, and total stock biomass point estimates and 95% intervals through 2025, with SSB alone reported for 2026. The remaining 2026 summary estimates and intervals below come from the official native fit, not from the report table.

The native fitted object contains 2026 age-specific state surfaces, which are retained as `native_model` outputs.

The native fitted object also supplies fitted catch and survey observations, age-specific q estimates, and covariance information for the N, F, and M state surfaces. These were added to the canonical outputs from the April model object. State SEs use the conditional random-effect covariance diagonal; the stored natural-scale SEs use the delta method, and the 95% limits are Wald intervals on the log scale. They are derived from the fit rather than transcribed from the report.

The 2026 intermediate-year recruitment, Fbar and total-biomass estimates and intervals are available from the native SAM summary tables. They are stored as native-model outputs, separately from the report-published SSB row.

The official numerical inputs remain unchanged in the canonical database. The added fitted outputs come directly from the April model object.

## Initial abundance

The cached official SAM fit has `initState = 0` and no `initN` parameters.
