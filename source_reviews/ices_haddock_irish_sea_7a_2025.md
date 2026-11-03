# Irish Sea haddock: 2025 age-structured assessment

## Assessment represented

The detailed record represents the ICES assessment of haddock in Division 7.a, fitted through 2024 and reported in WGCSE 2026. The assessment uses a single-fleet ASAP model with ages 0–5, Fbar ages 2–4, catch-at-age, and four abundance indices. The 2026 category-5 catch advice is stored as a separate summary event because it does not provide updated age-structured inputs or population estimates.

The 2025 age-structured assessment is the current detailed record under the database convention. The 2026 category-5 advice is a newer advice event, but it is not an updated age-structured assessment and is not marked current for detailed-data translation.

## Sources and cached files

- [WGCSE 2026 assessment report](https://doi.org/10.17895/ices.pub.32625759), especially Tables 9.2–9.8.
- [ICES SAG 2025 source data](https://sg.ices.dk/ViewSourceData.aspx?key=19850), including annual recruitment, SSB, total biomass and Fbar summaries through 2024.
- [WKIrish3 2017 benchmark report](https://doi.org/10.17895/ices.pub.8713), including selected ASAP assumptions and the use of Lorenzen M.
- [WKIrish2 2016 data-evaluation report](https://doi.org/10.17895/ices.pub.8712), including age-specific Lorenzen estimates in Table 6.2.3.
- [2026 ICES category-5 advice](https://asd.ices.dk/viewAdvice/6126), recorded separately as 586 tonnes in each of 2027 and 2028.

Source PDFs, the SAG XML and extracted text are cached under `source_cache/ck_ices_wgcse_aeglefinus_cs7a/`. The cache is local and gitignored. Its manifest records the source URL, checksum and retrieval date.

## Inputs and assumptions

The database preserves the reported catch numbers-at-age for 1993–2024 and the age-specific index values from NIGFS-WIBTS-Q1, NIGFS-WIBTS-Q4, NI-MIK and UK-FSPW. Reported stock weight-at-age, female maturity-at-age and the four survey series are retained on their source age and year grids. Missing survey values remain missing. The assessment report gives slightly different survey year ranges in its narrative and tables; the database follows the table rows. It also notes that catch age sampling was inadequate in 2003, which is retained with those values.

The catch-number multiplier and stock-weight unit are not printed beside Tables 9.3–9.4. The database records catch as thousands of fish and stock weight as kg per fish based on the scale of the values, and marks both interpretations as inferred. Survey index multipliers are not stated; index values are retained on their native scale. Month-based sampling times are represented as 0.20 for the Q1 surveys and 0.80 for Q4. NI-MIK is set to 0.50 using the report's June description, while the model-settings table lists month 7; this discrepancy is unresolved.

The report says natural mortality was calculated with Lorenzen's method at WKIrish2, and the 2017 benchmark retained the unscaled Lorenzen estimates. The database includes the 2016 Table 6.2.3 values for ages 0–5 as a reconstructed input. The exact M values used by the final 2025 ASAP fit could not be confirmed without its native configuration, so this is not represented as a verified fit input. Assumptions, inputs and outputs remain marked partial.

## Outputs

The assessment report and SAG provide aggregate recruitment at age 0, SSB and Fbar ages 2–4 with 95% confidence limits through 2024. Landings and discards are also retained from the assessment summary. The available sources do not provide N-at-age or F-at-age, so those quantities and their uncertainty are not added or derived. The 2026 catch advice is 586 tonnes for each of 2027 and 2028 and is kept out of the historical assessment output series.

## tinyAM translation

The translation fits 1993–2024 at ages 0–5, keeps all four index identities and their reported ages, uses the annual weight and maturity tables, and supplies the reconstructed fixed M values. The model uses an IID N process with exponential initialization, random-walk recruitment, correlated random-walk F, one catch observation SD and survey-specific q and observation SDs. This is an approximation of the single-fleet ASAP fit; the report does not give enough detail to reproduce every likelihood, variance-sharing rule or initial-state treatment. The survey CV and effective-sample-size settings are recorded in the audit but are not fully represented by tinyAM's simple observation-error structure.

The report contains zero catches and zero index values, which tinyAM treats as missing under its lognormal observation likelihood. Those source values remain in the database. The three missing-index groups (Q4 2024, NI-MIK 2020/2022 and UK-FSPW 2014) are omitted only from the analysis-side observation table; no values are imputed. Fitting uses package starting values first. Since official N-at-age and F-at-age are unavailable, a source-aligned population-start retry cannot be constructed from the published outputs.

The package-default fit converged with optimizer code 0, maximum absolute gradient 0.00087 and a successful positive-definite sdreport. Agreement is still poor: mean absolute percent differences are 178.9% for recruitment and 523.5% for the approximate SSB comparison; terminal differences are +258.5% and +842.3%, respectively. Recruitment trend correlation is 0.695. Official Fbar is not directly compared because its age range matches but its weighting cannot be aligned without official N-at-age. The fixed M comparison checks only that the reconstructed 2016 input was passed through; it is not an official fitted M output.

## Alternative process checks

Turning the IID N process off, to approximate deterministic cohort survival,
returned optimizer code 0 and a small gradient, but the fixed covariance was
non-finite and the Hessian was not positive definite. Keeping IID N while
replacing correlated F increments with independent temporal random walks did
pass convergence checks (objective 903.142, gradient 0.001067 and a positive-
definite Hessian), but worsened both reported comparisons: median percent
differences rose from 178.6% to 208.7% for recruitment and from 562.9% to
620.9% for SSB. Recruitment correlation increased only slightly (0.695 to
0.701), while SSB correlation fell from 0.922 to 0.915. The original
correlated-F translation is retained.
