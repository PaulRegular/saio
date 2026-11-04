# West of Scotland whiting: 2025 ICES SAM assessment

## Assessment selected

The stock is ICES whiting in Division 6.a (whg.27.6a), assessed by WGCSE. ICES Advice View identifies the 2025 assessment as the latest listed assessment; the available WGCSE 2026 chapter is a placeholder for a chapter to be updated later in 2026. The 2025 assessment is therefore the latest detailed production run recovered for this record.

- 2025 WGCSE assessment chapter: [ICES report chapter](https://doi.org/10.17895/ices.pub.29401877.v3), especially Tables 24.14–24.16.
- Assessment listing: [ICES Advice View, whg.27.6a](https://asd.ices.dk/viewAdvice/3936).
- Model framework: [WKNSEA 2021 report](https://doi.org/10.17895/ices.pub.7922), which describes the SAM age-structured state-space framework.
- Native fitted model and inputs: [stockassessment.org whiting_27.6a_2025](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/whiting_27.6a_2025/).

The official run identifies stockassessment 0.12.0, RemoteSha 1cc464b80f6f. The cached fit converges with optimizer code 0 and a positive-definite Hessian. Its terminal modeled year is 2025; total catch-at-age observations end in 2024.

## Inputs

The native fit contains 830 year-fleet-age rows, of which 799 have finite observations:

| Series | Years | Ages | Rows | Scale and timing |
|---|---:|---:|---:|---|
| Total catch-at-age | 1981–2024 | 0–7+ | 327 | Thousands of fish |
| WCIBTS.Q1 | 1985–2010 | 1–6+ | 156 | Native survey index; 0.125 of year |
| SCO.Q1 | 2011–2025, excluding 2022 | 1–6+ | 84 | Native survey index; 0.125 of year |
| SWC.Q4 | 1996–2024 | 0–7+ | 232 | Native survey index; 0.8530996 of year |

The two Q1 series are distinct survey fleets and remain separate. The source model uses age 7 as the plus group. The native SAM reader divides the raw series by its effort value. The database keeps the resulting fitted index scale; no abundance multiplier or physical-unit conversion is applied.

The fitted precision vector has finite relative weights for 316 survey observations. The database stores those weights on their native rows. SAM scales log-index observation SD by 1/sqrt(weight) where a weight is provided. Other observations have no supplied relative weight. The source bundle also contains survey_variance.txt; the fit-aligned weights, rather than a reconstructed reordering of that file, are stored as the likelihood inputs.

Original fitted input surfaces are retained for stock, catch, landings and discard weights; maturity; natural mortality; landings fractions; and the fractions of F and M applied before spawning.

## Model assumptions

The SAM configuration has age-specific F states with random-walk time evolution and AR(1) correlation across F age increments. Recruitment follows the configured random walk. The N process shares one variance for age 0 and another across ages 1–7. Natural mortality is supplied as a fixed year-age surface and is not estimated in this run.

Catch observation errors are lognormal with the source age-variance groups: age 0, ages 1–6, and age 7+. The two Q1 fleets use separate catchability parameters, with ages 1–4 separate and ages 5–6 shared within each fleet. Q4 catchability is separate for ages 0–5, with ages 6–7 shared. The Q4 index residuals use AR(1) correlation across ages. Source observation weights are retained where finite.

## Outputs and validation

The database records fitted N and F at age, fixed M at age, recruitment, SSB, Fbar, total stock biomass, q, and fitted catch and index predictions. It also includes total abundance derived by summing the fitted age-specific N estimates, and biomass at age derived from fitted N and fixed stock weights. Total abundance has no uncertainty; biomass-at-age uncertainty reflects N alone and treats weights as fixed. N and F state SEs are on the natural scale using the delta method, with 95% log-scale Wald limits. q is similarly converted from the native log-q estimate and its SD. Aggregate summary-table confidence limits are retained as reported by the native summary functions.

The 2025 fitted SAM age-0 abundance and recruitment are about 385,197 thousand fish, SSB is about 19,372 tonnes, and Fbar over ages 1–3 is about 0.0302 per year. These agree with the native fitted tables and the assessment report age and summary tables. The advice summary’s resampled 2025 recruitment forecast is a distinct quantity and is not substituted for fitted age-0 abundance.

The source PDFs and native run are cached locally under source_cache/ices_whiting_6a_2025/. The document manifest records retrieval URLs, date, byte size and SHA-256. Model-file provenance is recorded in the native bundle's model/source_manifest.csv.

The database record preserves the native fitted inputs and outputs.

## Discovery inventory screening

The ICES 2026 inventory entry whg.27.6a matches this existing canonical West of Scotland unit and is screened eligible. The latest detailed production run recovered is the complete 2025 SAM assessment; the 2026 WGCSE chapter is a placeholder. The matched run has age-based catch and survey inputs, fitted biological assumptions and mortality, documented timing, and fitted population/mortality outputs.
