# Irish Sea cod source review

Source review: 2026-10-19.
Assessment record: `ices_cod_irish_sea_2026`.

The source record is partial and is not fit-ready for a tinyAM translation.

## Identity and official run

Charbonneau–Keith identifier: `ICES-WGCSE_morhua_IS7a`. The current ICES stock code is `cod.27.7a`, Atlantic cod in Division 7.a (Irish Sea).

The current applied assessment is the 2026 WGCSE run, assessment key 23721, with data through 2025 and advice for 2027–2028. The report says the final assessment used Stock Synthesis 3 (SS3). The latest stock annex says the stock was last benchmarked in February 2022 and was updated in May 2025. Native 2026 SS3 data and control files were not found.

The working-group chapter is divided into separate PDFs on Figshare. The cod chapter and the 2025 stock annex are cached locally with retrieval URLs, dates and checksums under `source_cache/ck_ices_wgcse_morhua_is7a/assessment_2026/`.

## Model dimensions and inputs

The assessment spans 1968–2025, ages 0–6+, with recruitment at age 0 and Fbar over ages 2–4. There is one Irish Sea population and a single commercial fleet; recreational removals are excluded.

Table 6.9 reports total catch numbers-at-age in thousands of fish. It marks 2003–2005 and 2020 as excluded from the assessment because sampling was limited. Those source values remain in `inputs.csv` with the exclusion noted; the translation must omit them from the catch likelihood. Table 6.11 separately reports discards-at-age in thousands. Discards before 2007 are reconstructed in the source, and no 2020 age-discard values are tabulated.

Table 6.10 reports mean weights-at-age in landings, used for the whole stock and catch. The age-0 value is missing for 2019. In 2020 the report marks the weights as available only from Q1 sampling and not included; 2023–2025 have low or incomplete age sampling, and the 2025 ages 4+ values use the preceding three-year average. These source limitations are retained rather than filled.

Table 6.12 reports annual maturity from 1996 through 2025. Ages below 2 are immature and ages 3+ are mature. The 2025 stock annex reports a constant pre-1996 age-2 value of 0.27; the 2026 table reports 0.292 for 1996. The ogive is held constant from 2025 onward. The stock annex reports fixed, time-constant natural mortality of 1.7, 0.714, 0.68 and 0.65 for ages 0, 1, 2 and 3+, respectively.

The report provides age-specific index series for NIGFS-WIBTS-Q1 (ages 1–4), NIGFS-WIBTS-Q4 (age 0) and UK FSP (ages 2–6+). The working-group text says FSP spans 2004–2025, while Table 6.13 values begin in 2005; the database follows the numeric table. Table 6.13 gives one annual CV beside the Q1 age-index vector; the canonical long table repeats that value across the four ages as a source-table expansion, not as evidence of separately estimated age-specific CVs. Q1 CPUE and its standard deviation are also reported separately, but their native units are not specified. The age-index scale multipliers are not stated either.

The 2026 report and stock annex summarize model structure, selectivity, survey ages and some effective-sample-size settings. The native SS3 data/control files were not recovered, so exact likelihood definitions, observation weights and current parameter activation remain uncertain. These assumptions are explicitly marked partial.

## Outputs and readiness

Table 6.14 reports annual SSB, age-0 recruitment and Fbar ages 2–4 with pointwise 95% confidence limits. The reported summary values were cross-checked against the official ICES SAG export for key 23721, within report rounding. The source report and SAG export do not provide recoverable age-specific N-at-age or F-at-age; M is fixed rather than estimated.

The source table contains one missing cell in the weight surface (2019 age 0). No authoritative value was found, so it remains missing in the database. The translation fits ages 0–6+ over 1968–2018, where weight and maturity are complete. It retains Q1 ages 1–4, Q4 age 0 and UK FSP Q1 ages 2–6+, with timing approximated at 0.125, 0.875 and 0.125. Catch years 2003–2005 are excluded as in the assessment. The 2020 weights were marked by the report as unavailable for model use; the fitted period ends before them.

Index scale multipliers and exact likelihood allocations are unresolved. The native Q1 CV and FSP effective sample size are not used because their current likelihood roles were not recovered; tinyAM estimates a separate index observation SD by survey. Catch-at-age remains in thousand fish. The official Beverton-Holt recruitment blocks are represented by a random-walk recruitment process, and the source selectivity process is approximated with an AR1 temporal F process and a shared mean for ages 3+.

The default-initialization fit converged (optimizer code 0, maximum gradient 0.000364, positive-definite Hessian). Over 1968–2018, approximate SSB agreement was mean absolute percent difference 36.5%, terminal difference -9.3%, and trend correlation 0.971. Age-0 recruitment agreement was weaker: mean absolute percent difference 61.0%, terminal difference +1568%, and trend correlation 0.731. The simpler recruitment process remains an important limitation; no starting values were supplied.

The comparison period does not include the assessment's terminal 2019–2025 estimates. Official aggregate SSB timing is not stated, while tinyAM calculates beginning-of-year mature biomass, so SSB is approximate. Recruitment is age-aligned but its published point-estimate convention is unspecified, so it is also approximate. Official age-specific N and F are unavailable. Official Fbar is ages 2–4, while tinyAM Fbar is abundance-weighted and the required official N-at-age is unavailable; therefore the Fbar values are not compared. M is fixed at the published input values and shown as an input rather than a fitted output. The maintained translation and structural checks are in `scripts/translation/stocks/ices_cod_irish_sea_2026.R` and `tests/test_irish_sea_cod_translation.R`; source values are validated by `tests/test_irish_sea_cod_source.R`.

## Discovery inventory screening

The 2026 ICES inventory entry cod.27.7a matches this existing Division 7.a Irish Sea stock and is screened eligible for source curation. Age-based catch, survey, weight, maturity and fixed-M information plus aggregate official outputs are available from current report tables. Native SS3 data/control files and fitted age-specific N/F outputs remain unavailable; the exact likelihood is therefore not recoverable.
