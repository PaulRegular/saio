# Aleutian Islands Pacific cod

## Production source and run identity

Charbonneau–Keith Master `unique_ID` `AFSC_macrocephalus_AL to (AI)`; the prior catalogue identifier `AFSC_AI_Gadus_macrocephalus` remains recorded as an alias in `stocks.csv`.
The December 2024
SSC selected age-structured Tier 3 Model 24.1. The historical catalogue's Tier 5
label is not a reason to exclude this case. The final November 15 SAFE report
is cached in `source_cache/afsc_cod_ai/`, along with the public native files
and report source at revision `bc170ea3acb7cea2f9c743653cd9648092b9ec25`.

The public `M24_1` fit is dated **September 26**, and does not reproduce final
November results. For example, public growth L1 is 14.1037 versus final
14.0937, estimated M is 0.571771 versus 0.5703, and projected female spawning
biomass/total biomass differ. The authors' November Rmd loads the unpublished
local directory `November2024/M24_1_data/run`. Do not combine the public
preliminary N/F/weight surfaces with final report outputs. Neither a matching
folder label nor a near-match of aggregate values establishes run identity.

## Recovered inputs

The final source models 1991–2024 and ages 0–13+, one combined-sex population.
Retain total catch in tonnes from Table 2A.6 for complete years through 2023.
For 2024 use the explicit **4,676 t model catch** in Table 2A.24, corroborated
in the native data file. Table 2A.6's **3,570 t** is partial reported landings
through September 22 and is not substituted for the full-year model catch.

The trawl biomass series is Table 2A.14, including 50,383 t in 2024. The source
table explicitly identifies these as model inputs. Its 2022 value 51,539 t
differs slightly from the regional table total 51,543 t; preserve the series
actually identified for the model. The fractional S.E. column is retained
with its original relative scale, not treated as tonnes or silently converted
to a log SD. Native survey month 7 corroborates midyear timing. The separately
tabulated longline index is not made part of the selected trawl likelihood.

Fishery observations are lengths; active survey age observations are
conditional age-at-length, not standardized abundance-at-age. Final production
composition arrays, stock weights and N/F outputs were not verified. Table
2A.17's maturity-at-age is a converted summary of a length ogive, not an
original supplied age-maturity matrix. The final length-ogive coefficients
are A=−8.589 and B=0.155; growth is estimated. Original weight–length parameters
are kg = 5.40706e-6 × cm^3.19601. Do not invent a population weight matrix or
use fitted preliminary N to allocate final observations.

M is fixed at 0.417 before 2016. From 2016 onward a replacement level is
estimated: final M=0.5703 with natural-scale SD 0.0371 (Table 2A.21). The fixed
pre-2016 values are inputs; the estimated block is an output, not a fixed input.

## Recovered outputs and definition caution

Final Model 24.1 biomass, reported SSB and age-0 recruitment are transcribed
from Tables 2A.18–20 with available original 95% limits. Ages/years and units
are retained; no SE is inferred from limits. The tables' pre-start labels
1989/1990 represent equilibrium/initial summaries for a model beginning 1991,
not additional assessment years, and are not imported as historical estimates.
In 2024 total biomass is 74,386 t, reported SSB 50,446 t (35,559–65,333),
and age-0 recruitment 76,193 thousand fish (63,933–90,805).

The SSB caption calls these female biomass, but its values exceed half of
total biomass and the projection table appears to use the half-scaled
single-sex convention. This definition remains unresolved without final
native output. Preserve the printed values and limits; do not silently halve
them or claim comparability to tinyAM female SSB.

## Follow-up source check

The local ignored cache was refreshed on 2026-10-19 with the final 2024 SAFE PDF, the public `M24_1` directory and the repository's `AIPcod2024Nov.Rmd` and `M24_1_data.R` scripts; URLs, pinned revision, retrieval date and SHA-256 checksums are in `source_cache/afsc_cod_ai/accessible_sources_manifest.csv`. The public `Report.sso` records a September 26, 2024 fit (including L1 = 14.1037 and replacement M = 0.571771), consistent with the earlier preliminary-run diagnosis. The November R Markdown source points to author-local CSV inputs and `November2024/M24_1_data/run`; that final run directory and its model files are absent from the public repository tree. The cache therefore makes the version mismatch reproducible but does not recover the final November production inputs or outputs needed for a faithful tinyAM translation.

On 2026-10-20, the public [`AI_PCOD` repository](https://github.com/afsc-assessments/AI_PCOD) was checked again. Branch searches surfaced `main` and `devmk`; requests for the README and candidate 2024 run files on `devmk` returned 404. On `main`, alongside the September 2024 `M24_1` run, the repository contains an [`M24_1_2025` data file](https://github.com/afsc-assessments/AI_PCOD/blob/bc170ea3acb7cea2f9c743653cd9648092b9ec25/M24_1_2025/data_echo.ss_new) written in August 2025 and spanning 1991–2024. The repository README identifies Model 24.1 as the 2024 base, while the public tree does not provide an `M24_1_2025/Report.sso`. This later input snapshot does not identify itself as the missing November 2024 production run, so it is not mixed with final report outputs. NOAA continues to list the 2024 assessment as the latest AI Pacific cod assessment in its [2024 groundfish assessment collection](https://www.fisheries.noaa.gov/alaska/population-assessments/2024-north-pacific-groundfish-stock-assessments).

## Translation blocker

No tinyAM fit is attempted from an unverified final data/biology combination.
A valid translation needs matching final length/conditional-age arrays and
weights, then an explicit defensible catch-at-age allocation and survey
conversion. Preliminary fitted surfaces are not a substitute. This is one
partial curated case, **not a completed runnable translation or actual fitting
attempt**. Missing data and unresolved definitions are explicit shortfalls,
not agreement passes. No starting-value or model rescue was attempted.
