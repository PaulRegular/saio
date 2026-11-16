# Norwegian spring-spawning herring (ices_herring_norwegian_spring_spawning)

## Norwegian spring-spawning herring

### Assessment represented

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

### Inputs and assumptions

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
source precision information. RFID relative errors are tabulated, but its numerical index estimates are only
shown in a figure and are not transcribed. The native SAM fit and exact process,
q-sharing, and uncertainty settings were not recovered.

Published biology includes age-12 stock weight and maturity. No abundance-by-single-age surface above age 12 was recovered for a population-weighted biological average. Maturity is reported by cohort, related to calendar year by `cohort = year - age`.

### Source files cached locally

The authoritative report and derived table extracts are in the gitignored
`source_cache/ices_herring_norwegian_spring_spawning/ices_herring_norwegian_spring_2026/`
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

## Norwegian spring-spawning herring: historical 2025 assessment

Assessment `ices_herring_norwegian_spring_2025`.

### Assessment represented

The separate historical record uses the official 2025 ICES assessment, configured at
WKBMACNSSH 2025. This note preserves the earlier detailed run; the 2026 assessment is now current. Its fitted catch series ends in
2024; estimated N, F, and summary series extend through 2025. The newer detailed 2026 record is documented in [the current source review](ices_herring_norwegian_spring_spawning.md). Its values do not replace this historical 2025 record.

The assessment is for Norwegian spring-spawning herring (*Clupea harengus*) in
ICES Subareas 1, 2, and 5 and Divisions 4.a and 14.a. The reported model ages
are 2–12+, with recruitment at age 2. The detailed 2025 output includes
numbers-at-age, F-at-age, recruitment, SSB, catch, and Fbar.

### Inputs and assumptions

The catch table reports numbers-at-age for 1950–2024 in thousand fish and
source age groups 0–14 and 15+. The official fit uses 1988–2024. The database
retains ages 2–15+ as reported without substituting the model's 12+ group for the reported ages. Catch weights are retained separately.

The report gives standard natural mortality of 0.9 per year at age 2 and 0.15
per year at ages 3 and older. It also refers to annual mortality deviations in
the stock annex; those values were not recovered, so the database records only
the published baseline surface. Stock weights are annual, and maturity is
reported by birth cohort and age. The maturity report notes that maturity
depends on cohort size and that the 2020 year-class values were not updated
from the previous assessment.

The numerical indices are NASF acoustic abundance at ages 3–12+ (1988–2008
and 2015–2025), IESNS Barents Sea at age 2 (1991–2024 except 2008), IESNS
Norwegian Sea at ages 3–12+ (1996–2025), and BESS at ages 2–3 (2004–2024). The 2025 fitted
period uses values through 2024. Although the Barents abundance table lists
ages 1–5, its SAM relative-error table specifies age 2 only, so only age 2 is
recorded as a fitted index input. The database keeps source survey units and
records approximate seasonal timing: 0.13 for NASF, 0.42 for IESNS Barents,
0.38 for IESNS Norwegian Sea, and 0.75 for BESS. Exact fitted fleet settings
were not recovered.

The report includes relative standard errors for catch and the surveys.
These are stored as source precision information. RFID relative
errors are available, but the numeric index series is only shown in a figure,
so no RFID observations are transcribed. The official native SAM object and
its exact process, q-sharing, and uncertainty settings were not recovered.


### Source files cached locally

The following files are in the gitignored
`source_cache/ices_herring_norwegian_spring_spawning/ices_herring_norwegian_spring_2026/`
folder for reference:

| File | Source or use |
|---|---|
| `wgwide_2025_norwegian_spring_spawning_herring.pdf` | [WGWIDE 2025 report](https://doi.org/10.17895/ices.pub.30233824), detailed assessment tables and assumptions |
| `ices_sag_2025_key_21106.xml` | ICES Stock Assessment Graphs 2025 detailed time series |
| `ices_stock_assessment_graph_data_25912.xml` | ICES Stock Assessment Graphs 2026 summary-only time series |
| `wgwide_2025_extracted_text.txt` | Local text extraction for review and summary-table import |
| `wgwide_2025_age_tables.csv` | Age-aligned table extraction; blank cells remain missing |

The 2025 benchmark is [WKBMACNSSH](https://doi.org/10.17895/ices.pub.29279615).
The 2026 advice is [ICES Advice 2026](https://doi.org/10.17895/ices.advice.30932075).
