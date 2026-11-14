# Western tarakihi, 2026 assessment

## Assessment and stock unit

Fisheries New Zealand's 2026 production assessment covers the western biological stock of tarakihi (*Nemadactylus macropterus*), including TAR 8 and western portions of TAR 1 and TAR 7. The model represents the stock as one spatial region with two sexes and 40 age classes, with age 40 as a plus group. Model years are 1932–2025; 2025 represents the 2024–25 fishing year. The assessment used Stock Synthesis and the source report is FAR 2026/23.

## Inputs and biological information

- Table A16 reports catch biomass in tonnes for four fisheries over 1932–2025 (376 fishery-year records). These are biomass inputs, not catch numbers-at-age.
- The report provides 33 sex-specific age-composition samples, retained as 1,980 age cells for ages 1–29 and 30+. Source values remain unnormalized because some sample totals are below one and the report does not explain the shortfall. The effective sample size of 20 applies to each commercial sample; survey sample sizes are not tabulated.
- Tables 8 and 9 provide trawl-survey biomass and age-specific indices, including WCSI and WCNI biomass, TBGB age-1 and age-2 indices, and WCSI age-2 indices. Where reported, survey CV percentages are stored as ratios. The report does not specify an absolute scale for every age-specific index.
- The report gives fixed natural mortality of 0.10 per year for both sexes, sex-specific Schnute growth parameters, a length-weight relationship, and a female maturity-at-age schedule for ages 1–10 (age 10 is the plus group). These are model assumptions; they are not direct weight-at-age or observed catch-at-age data.
- The WCNI commercial CPUE series includes 32 annual indices for 1994–2025. Its 95% confidence limits are published, so the importer derives a lognormal CV from those limits and marks it as reconstructed rather than a directly reported CV.

The report describes an October–September model year with two six-month periods. It does not report fractional-year sampling times for individual survey observations. No catch numbers-at-age or direct weight-at-age table are published, and none are reconstructed from the proportions or biomass catches.

## Outputs recovered

Tables 15 and 16 provide ten official base-case outputs, including 2025 spawning biomass, unfished spawning biomass, stock-status probabilities, fishing-mortality reference results, and reference yield. The reported 2025 spawning biomass median is 4,419 tonnes (95% interval 3,170–5,986); unfished spawning biomass is 15,284 tonnes (95% interval 13,257–17,658). Available source intervals are retained without deriving standard errors.

The report does not tabulate annual numerical recruitment or N-at-age, F-at-age, or M-at-age arrays. Those trajectories are not digitized from figures, so the published outputs support terminal comparisons but not a full annual age-specific comparison.

## Source and provenance

The detailed report was retrieved on 2026-11-05 and is cached locally under the ignored `source_cache/mpi_tarakihi_western_2026/` directory. Its URL and SHA-256 checksum are recorded in `provenance/mpi_tarakihi_western_2026_sources.csv`.

- [FAR 2026/23: Stock assessment of western tarakihi for 2026](https://fs.fish.govt.nz/Doc/26247/FAR-2026-23-Stock-assessment-of-western-tarakihi-for-2026.pdf.ashx)
- [Fisheries New Zealand report record](https://fs.fish.govt.nz/Page.aspx?pk=61&tk=209)

The canonical record remains partial for assumptions, inputs and outputs. Important gaps include direct catch-at-age and weight-at-age tables, exact fractional-year sampling times, some age-index scale details, and numerical annual population and mortality arrays. No unsupported values or scales have been added.
