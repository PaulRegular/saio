# Eastern tarakihi, 2026 assessment

## Assessment and stock unit

Fisheries New Zealand's 2026 production assessment covers the eastern biological stock of tarakihi (*Nemadactylus macropterus*), spanning TAR 3, TAR 2 and the eastern parts of TAR 1 and TAR 7. The model has three spatial regions and estimates age-dependent movement among them; these regions are components of one stock, not separate stock units. The assessment uses Stock Synthesis 3.30.23.1 and model years 1932–2025, with 2025 representing the 2024–25 fishing year.

The latest detailed source reviewed is Fisheries Assessment Report (FAR) 2026/44, *Stock assessment of eastern tarakihi for 2026*. Its report tables are the source of the imported observations, assumptions and outputs. The report does not provide the native Stock Synthesis files.

## Inputs and biological information

- Table A30 provides catch biomass in tonnes for eight fisheries over 1932–2025 (752 fishery-year records). The 2025 catch values are for the 2024–25 year. These are catch-biomass observations, not catch numbers-at-age.
- Tables A31–A37 provide 47 age-composition observations with 1,410 age cells covering ages 1–29 and 30+. Values are retained as reported; the importer does not renormalize them. Effective sample sizes apply to whole samples, not individual ages.
- The assessment reports 136 annual CPUE index values across five fishery series, 20 ECSI winter/summer survey biomass indices, and 10 age-2 survey abundance indices. The survey-index CVs reported as percentages are stored as ratios. The scale multiplier for the age-2 index is not stated in the report. Annual values for the daily TAR 2 and Cook CPUE indices in 1990–2007 are not tabulated and are not reconstructed.
- The report gives fixed natural mortality of 0.10 per year for both sexes, sex-specific Schnute growth parameters, a length-weight relationship, and a maturity schedule of 0 for ages 1–3, 0.25 at age 4, 0.5 at age 5, and 1 at ages 6+. These are model assumptions; the report does not provide direct weight-at-age observations or a sex-specific maturity schedule.
- The report describes an October–September model year with two six-month periods. It does not give fractional-year sampling times for individual survey observations, so those input fields remain unspecified.

The source tables report proportions-at-age and catch biomass rather than catch numbers-at-age. The database preserves those native forms and does not combine proportions with catches to create numbers-at-age. No direct age-specific abundance index has been added beyond the report's age-2 index.

## Outputs recovered

Tables 17–19 provide 22 official output records, including reported 2025 spawning biomass and unfished spawning biomass, reference-point probabilities and fishing-mortality outputs, plus 2030 projection summaries under named scenarios. Reported point estimates and available 95% intervals are retained without deriving standard errors.

The report does not tabulate annual numerical recruitment or N-at-age, F-at-age, or M-at-age arrays. Those trajectories appear only in figures, so they have not been digitized into artificial annual records. The published tables therefore support terminal and projection comparisons, but not a complete annual age-specific output comparison.

## Source and provenance

The assessment report was retrieved on 2026-11-05 and is cached locally under the ignored `source_cache/mpi_tarakihi_eastern_2026/` directory. Its download URL and SHA-256 checksum are recorded in `provenance/mpi_tarakihi_eastern_2026_sources.csv`.

- [FAR 2026/44: Stock assessment of eastern tarakihi for 2026](https://fs.fish.govt.nz/Doc/26277/FAR-2026-44-Stock-assessment-of-eastern-tarakihi-for-2026.pdf.ashx)
- [Fisheries New Zealand report record](https://fs.fish.govt.nz/Page.aspx?pk=61&tk=209)

The canonical record remains partial for assumptions, inputs and outputs. Main gaps are unreported daily CPUE values for 1990–2007, an unspecified age-2 index scale, no direct weight-at-age table, and no numerical annual population or mortality arrays. No missing values or scaling factors have been inferred.
