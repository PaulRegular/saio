# Norwegian spring-spawning herring

## Assessment represented

The current record is the official 2026 WGWIDE assessment for Norwegian
spring-spawning herring (*Clupea harengus*) in ICES Subareas 1, 2, and 5 and
Divisions 4.a and 14.a. The report says the assessment used SAM with the model
options defined at the 2025 WKBMACNSSH benchmark. Catch-at-age inputs extend
through 2025; the reported N-at-age, F-at-age, and summary estimates extend
through 2026. The detailed 2026 assessment is recorded separately from the
2025 assessment, whose data remain unchanged. The 2026 record is current.

The model ages are 2–12+, with recruitment at age 2. The report supplies N and
F point estimates by age and year, plus recruitment, SSB, catch, and Fbar
summaries. Total abundance is derived by summing N-at-age for ages 2–12+ and
has no reported uncertainty.

## Inputs and assumptions

The 2026 report provides catch numbers-at-age for 1950–2025 in thousand fish,
with source age groups 0–14 and 15+. The assessment fit uses 1988–2025. The
database retains age-specific catch numbers and catch weights for ages 2–15,
where age 15 represents 15+. Annual stock weights extend through 2026. Maturity
is reported by birth cohort and age through cohort 2026. The report gives
standard natural mortality of 0.9 per year at age 2 and 0.15 per year at ages
3 and older; annual M deviations referenced in the stock annex were not
recovered.

Numerical abundance indices are NASF acoustic abundance at ages 3–12+ in
1988–2008 and 2015–2026, IESNS Barents Sea at age 2 in 1991–2026 where a
survey was conducted, IESNS Norwegian Sea at ages 3–12+ in 1996–2026, and BESS
at ages 2–3 in 2004–2025. The report states that the 2026 assessment used the
benchmark-recalculated BESS series after permission to use it was obtained;
the report's values are retained without further adjustment. The Barents
abundance table lists ages 1–5, but its SAM relative-error table specifies age
2 only, so only age 2 is recorded as a fitted index input. Approximate seasonal
timing is 0.13 for NASF, 0.42 for IESNS Barents, 0.38 for IESNS Norwegian Sea,
and 0.75 for BESS. Exact fitted fleet settings were not recovered.

Relative standard errors for catch and the tabulated surveys are stored as
source precision information; tinyAM estimates its own observation errors.
RFID relative errors are tabulated, but its numerical index estimates are only
shown in a figure and are not transcribed. The native SAM fit and exact process,
q-sharing, and uncertainty settings were not recovered.

For a tinyAM comparison, source ages above age 12 are combined into age 12+.
The published age-12 stock weight and maturity are used as proxies for the
12+ group because no abundance-by-single-age surface above age 12 supports a
defensible weighted biological average. Maturity cohorts are mapped to
calendar year by `cohort = year - age` in the translation.

## tinyAM translation

The current-run approximation is defined in
`scripts/translation/stocks/ices_herring_norwegian_spring_2026.R`. It fits
1988–2025 at ages 2–12, using IID N with free initial abundance, an F random
walk, and the standard age-specific M pattern as fixed. Catch and the four
numerical survey series are fitted with tinyAM observation errors; SAM's
relative-error weights and unavailable annual M deviations are not reproduced.
The fit uses package-default starting values; no source-based retry was needed.

The fit converged (optimizer code 0, objective 1059.441, maximum absolute
gradient 0.00111). The Hessian was positive definite and `sdreport` succeeded;
the fit had 53 fixed and 825 random effects and took 3.6 seconds. Numerical
convergence does not remove the model differences above. Residual checks flag
some groups with unusual standardized-residual spread, residuals above three
standard deviations, and adjacent-year residual correlation.

Over 1988–2025, common-definition SSB had 10.75% mean absolute percent
difference, +0.16% terminal difference, and 0.965 trend correlation.
Recruitment had 46.22%, +50.21%, and 0.743; total abundance had 20.03%,
+8.55%, and 0.798. N-at-age had 21.82% mean absolute percent difference and
0.943 mean within-age trend correlation; F-at-age had 29.27%, -21.82%
terminal difference, and 0.816. Fbar had 13.59%, -0.90%, and 0.923. Fixed M
matches its supplied baseline by construction and is not evidence that tinyAM
estimated or reproduced the source's annual M deviations. These comparisons
describe this documented approximation; they are not fit targets.

The fit, initialization diagnostics, and dashboard are cached locally under
`results/cache/ices_herring_norwegian_spring_2026/`.

## Source files cached locally

The authoritative report and derived table extracts are in the gitignored
`source_cache/ices_herring_norwegian_spring_2026/`
folder:

| File | Source or use |
|---|---|
| `wgwide_2026_nssh.pdf` | [WGWIDE 2026 report](https://doi.org/10.17895/ices.pub.33882730.v1), Norwegian spring-spawning herring assessment tables and assumptions |
| `wgwide_2026_nssh_extracted_text.txt` | Local report text extraction for review |
| `wgwide_2026_age_tables.csv` | Age-aligned extraction of report tables; blank cells remain missing |
| `wgwide_2026_summary.csv` | Extraction of Table 4.5.1.4; 2026 catch and Fbar are not reported |
| `ices_stock_assessment_graph_data_25912.xml` | ICES Stock Assessment Graphs summary series, including total biomass |
| `manifest.csv` | Retrieval date, source URLs, and checksums for cached source and extracts |

The 2025 record remains available as the preceding detailed assessment. Its
benchmark is [WKBMACNSSH 2025](https://doi.org/10.17895/ices.pub.29279615).
