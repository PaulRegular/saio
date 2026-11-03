# Southern Gulf fall-spawning herring

## Assessment represented

The canonical database now has two separate assessment records for the
Charbonneau–Keith catalogue stock `DFO-GSL_harengus_4T-Fall`.

- `dfo_herring_4tvn_fall_2024` is the 2024 assessment to 2023. It is the
  latest run with detailed numerical input and output tables recovered so
  far, and remains the current detailed record.
- `dfo_herring_4tvn_fall_2026` is the official assessment to 2025 summarized
  in DFO Science Advisory Report 2026/032. The record contains the reported
  2025 total SSB and current public fall acoustic-biomass series. Full annual
  inputs, population surfaces, and the model object have not been recovered.
  Its data are not mixed into the 2024 assessment.

The 2024 supporting document is primarily a data report. DFO Research
Document 2022/068 supplies the last detailed SCA-method description, for the
2020–2021 assessment, and is used as methodological context rather than
assumed to describe every detail of the 2022–2023 update. The 2026 Research
Documents 2026/050 and 2026/061 describe framework and CPUE-index work; their
results are not treated as the official 2025 assessment output.

## 2024 source data

DFO Research Document 2024/058 reports the fall component over 1978–2023 and
ages 2–11+, with age 11 as the plus group. Its numerical inputs include:

- fixed- and mobile-gear catch-at-age by North, Middle, and South region,
  Tables 6 and 10, in thousands of fish;
- fixed-gear weight-at-age by region, Table 7, and mobile-gear weight-at-age,
  Table 11, in kilograms per fish;
- fall fixed-gear CPUE by region and age 4–11, Table 14, in numbers per net
  haul, for 1986–2023;
- fall acoustic catch-at-age/index values at ages 2–10, Table 15, for
  1994–2023; and
- multispecies bottom-trawl stratified mean numbers per tow at ages 1–11+,
  Table 17, for 1994–2023.

The 2024 acoustic table does not state a scale multiplier. DFO Research
Document 2016/060, Table 16, explicitly labels this seasonal acoustic
catch-at-age series in thousands of fish. The 2024 numeric values are retained
unchanged on that scale. The latest public DFO acoustic-biomass CSV reports
fall survey biomass in tonnes, according to its data dictionary; those values
are attached only to the separate 2026 assessment record.

Table cells shown as dashes are left unfilled in the canonical database; they
are not converted to zero. The missing 2023 mobile-gear weight-at-age values
remain unavailable.

## Source issue: mobile-gear catch-at-age

The 2024 report's Table 10 is titled as mobile-gear catch-at-age, but the
published numbers duplicate Table 6 exactly across every year, age, and
region. This is visually confirmed in the PDF and is inconsistent with the
distinct mobile-gear data in the 2020–2021 assessment's Table 10. No verified
2022–2023 correction or source model file has been located.

The canonical database retains the Table 10 values as published and flags the
duplication in every row. They are not treated as verified mobile catch and
are excluded from the tinyAM catch construction. The translation uses the
complete 2024 fixed-gear catch series only, so catch inputs are a documented
subset of the official assessment. Mobile-gear weight data are available
through 2022; the 2023 mobile weight row is unavailable.

## Model assumptions and outputs

The documented SCA had separate North, Middle, and South population models.
It estimated regional initial abundance, annual age-2 recruitment, selectivity,
time-varying M in age groups 2–6 and 7–11+, and time-varying index
catchability. The 2022 methods describe log-M random walks with fixed
increment SD 0.075 and initial-M prior mean 0.2. The source likelihood uses
total catch with age-composition information, age-specific and aggregate
indices, and observation weights; the supporting document does not recover
all likelihood inputs or their complete 2024 settings.

Tables 22–29 report August 1 biomass and January 1 abundance at age by region
and for the combined population. The reported 4+ biomass is retained as the
assessment's spawning-biomass quantity under the documented knife-edge
maturity schedule (ages 4+ mature). Tables 30–33 report January 1 F-at-age
and Fbar for ages 5–10. Numerical age-specific M and tabled uncertainty are
not available. The database also contains explicitly labelled sums of
age-specific N and biomass, without invented uncertainty.

The 2026 advisory reports total 2025 SSB of 321 kt with a 95% interval of
259–433 kt. That single aggregate is not enough to construct annual N-, F-,
or M-at-age reference surfaces. The public fall-acoustic biomass series is
preserved as an available input, but its exact revision in the 2025 fitted
likelihood is not confirmed.

## Local source cache

Relevant PDFs, extracted text, the acoustic data and dictionary, retrieval
URLs, and checksums are listed in the ignored
`source_cache/ck_dfo_gsl_harengus_4t_fall/manifest.csv`. The 2026 PDF URLs
currently redirect to the Government Publications HTML archive page in the
local downloader, so those PDFs are not represented as cached files.

## References

- [DFO Research Document 2024/058](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41256384.pdf),
  Tables 6–7, 10–11, 14–17, and 22–33.
- [DFO Research Document 2022/068](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091589.pdf),
  fall SCA methods and maturity schedule.
- [DFO Research Document 2016/060](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/365860.pdf),
  Table 16 acoustic-unit clarification.
- [DFO Science Advisory Report 2026/032](https://publications.gc.ca/site/eng/9.963395/publication.html),
  assessment to 2025.
- [DFO Research Document 2026/050](https://publications.gc.ca/site/eng/9.964104/publication.html),
  state-space framework context.
- [DFO Research Document 2026/061](https://publications.gc.ca/site/eng/9.965416/publication.html),
  CPUE-index framework context.
- [DFO historical acoustic biomass dataset](https://open.canada.ca/data/en/dataset/7c17f4eb-93fc-11ea-b1dd-f48c505b2a29)
  and its data dictionary.
