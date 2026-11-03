# Atlantic striped bass (`Morone saxatilis`)

## Identity and official run

`asmfc_striped_bass_atlantic_2024` represents the ASMFC's official 2024
single-stock assessment update, fitted through 2023. The stable catalogue ID
`NEFSC-GARMIII_saxatilis_GOM, CHATT` is retained. Its historical area label
does not describe a separate Gulf-of-Maine-only stock: the current assessment
models the U.S. coastwide population with Chesapeake Bay and Ocean fleets.
The basin is Northwest Atlantic.

The [ASMFC's assessment overview](https://asmfc.org/resources/stock-assessment/atlantic-striped-bass-stock-assessment-update-overview-2024/)
identifies the 2018 peer-reviewed benchmark and the 2024 update through 2023.
The [current species page](https://asmfc.org/species/atlantic-striped-bass/)
still uses that assessment and identifies the next benchmark for 2027.
Later projection updates and annual fishery summaries are not substituted for
a newly fitted historical assessment.

## Cached authoritative sources

- [2024 assessment report](https://asmfc.org/wp-content/uploads/2025/01/2024_AtlStripedBassAssessmentUpdate.pdf): fleet totals, fixed biology, survey inventory and official model selection.
- [2024 appendices 2–4](https://asmfc.org/wp-content/uploads/2025/01/2024_AtlStripedBassAssessmentUpdate_Appendices2-4.pdf): equations, base-run diagnostics, detailed population states and uncertainty.
- [SAW 66 assessment report](https://doi.org/10.25923/nhqe-jd35), particularly Appendix B10: the non-migration single-stock model, survey timing/age links and parameter phases. The preceding migration-model code is a different model and is not used to establish this run's implementation.

These files are cached under
`source_cache/ck_nefsc_garmiii_saxatilis_gom_chatt/`, with URLs, retrieval
dates and SHA-256 checksums in `manifest.csv`. The importer pins the two 2024
PDF hashes. Base-run labels and representative tables were visually checked.

A public [spatial-model simulation study](https://github.com/snehemiah/SE-model-performance)
was also inspected at revision `1114944eaa5b014c6891d79aa5731fdd4c4d490e`.
Its `.dat` file uses years 1–30 and simulated observations. It is not the
1982–2023 production assessment. Candidate files, URLs and checksums are
retained separately in the local research-source cache; none enters the
canonical observations or outputs.

## Model structure and source coverage

The fitted historical period is 1982–2023, recruitment is age 1, and the
terminal group is 15+. Population N combines sexes; reported SSB is female.
M, female maturity and female fraction are fixed age vectors from main
Table 4. Female fraction is separate from maturity; multiplying by both is
necessary when using both-sex N. The framework's female SSB equation sums
January-1 N times female fraction, maturity and year-age weight, with no
additional survival-to-spawning multiplier.

Recruitment has independent normal log deviations with a sum constraint and
additional penalties/bias constraints. Survival after recruitment is
deterministic. The two fleets have separate F and selectivity. Bay selectivity
blocks are 1982–1984, 1985–1989, 1990–1995, 1996–2019 and 2020–2023;
Ocean blocks are 1982–1984, 1985–1989, 1990–1996, 1997–2019 and 2020–2023.
The separate-2023-block sensitivity is excluded.

Fleet totals use a concentrated lognormal likelihood; fleet and survey
number compositions use multinomial likelihoods. Annual CVs, likelihood
weights, CV multipliers and effective sample sizes are distinct quantities.
The report describes seven fishery-independent age-1+ indices and MRIP CPUE,
plus six young-fish indices. Their numerical observation arrays have not been
recovered.

Framework Appendix B10 Table 3 documents mortality fractions for the eight
age-composition indices: NYOHS 0.75, NJ Trawl 0.25, MDSSN 0.25, DESSN 0.25,
MRIP 0.50, CT Trawl 0.33, DE30FT 0.90 and ChesMMAP 0.50. NYOHS/DESSN
terminate in 13+, while other indices extend to 15+. These are model timing
fractions, not inferred season midpoints. The framework also links young-fish
indices to January-1 ages; exact current calendar/cohort alignment needs the
native arrays. Its timing table labels “VA Age 1”, whereas diagnostics and
the current report identify NY Age 1. That label discrepancy is unresolved.

## Imported records

`scripts/database/145_import_asmfc_striped_bass_2024.R` imports:

- 84 native fleet total-removal observations in fish, including harvest and
  dead discards/releases; no catch-at-age is reconstructed without compositions;
- 15 values each for fixed female maturity, female fraction and M;
- 630 beginning-of-year N values in fish;
- 630 F values per fleet and 630 total F values, in inverse years;
- 630 female spawning-biomass contributions by age, in tonnes;
- native annual total abundance, 8+ abundance and age-1 recruitment;
- native female SSB and natural-scale SEs, and fully-recruited fleet/total F
  with their reported standard errors.

This gives 129 input records and 3,486 outputs. All completeness statuses
remain **partial**. Fleet F and total F are overlapping reports: a single-stock
comparison must select total F rather than add all three. Fully-recruited F is
retained as `Ffull`, not mislabelled as an age-averaged `Fbar`. Fixed M is an
input, not evidence of successful mortality estimation.

## Validation and reporting precision

The importer verifies all 42 years and 15 ages, year/age ordering, source
table widths, fleet-F sums, abundance sums and reported aggregate summaries.
N cells are printed at approximately six significant digits; reported totals
can have greater precision, so the original totals are retained. Catch fleet
totals differ from their printed combined total by at most one fish.

Main Table 5 and appendix Table X8 differ by one tonne for SSB in 2006 and
2021. The primary SSB series uses Table X8's point estimate with its own SE.
Table X7's more precise age-table total is retained separately as
`SSB_age_table_total`; it differs from X8 by at most 0.6 tonnes. No SE is
transferred between the two series. Table X5's caption ends at 2021 although
its rows extend through 2023; the numerical rows determine coverage.

The SSB SE is in tonnes and F SEs are in inverse years. Printed CVs remain
identified as CVs in notes; they are not inserted into `se`. Confidence bounds
and age-specific uncertainty are not supplied and remain missing. The source
tests also verify that fully-recruited F is not converted into an Fbar series.

## Remaining gaps before translation

The raw fleet compositions, age-specific/aggregate survey observations,
annual CV arrays, and complete 2024 year-age weights were not recovered from
the published files or public native-file searches. Figure diagnostics and
fitted states do not substitute for those inputs. The 2018 framework clarifies
the model, but historical data must not fill the missing 2024 update.

The printed catch equation also appears to mix fleet F in its denominator
with total F in its survival term. The corresponding non-migration production
code is needed to verify the implementation. Neither the migration-model code
in the framework nor a simulation study establishes what the 2024 run used.

To check whether the pre-2022 inputs could be recovered from the prior update,
the official 2022 appendices were also reviewed and cached. They define the
catch, index, CV and age-composition inputs and report RMSEs, CV weights,
effective sample sizes and likelihood summaries, but do not provide the annual
observed catch, index or composition arrays. The 2024 report says its 2022
input series were extended through 2023, but it likewise does not publish
those arrays. The older update therefore cannot supply a verified input
vector for the 2024 run, and its fitted values are not used to fill that gap.

The 2024 Appendix 4 projection code was checked separately. It reproduces
the fitted age-1 recruitment series for 1982–2023, then reads `BAYALKS` and
`CSTALKS` workbooks for 2020–2022 to construct alternative projection
selectivities. The appendix names those files but does not include or link the
workbooks on its download page. These projection materials do not provide the
historical catch, index or composition likelihood arrays needed for a 2024
tinyAM fit; the recruitment vector is a fitted state, not an observation.

No tinyAM model, source-based starts or dashboard is claimed. Translation
requires those original inputs and resolution of the remaining configuration
and year-alignment questions; observations will not be inferred from fitted N/F.


## Separate 2018 historical assessment

The 2018 SAW-66 report recommends the single-stock non-migration SCA for
management; its alternative two-stock migration model is not the accepted run.
The historical record `asmfc_striped_bass_atlantic_2018` is separate from the
2024 update, which remains the current assessment. The official assessment
and its source tables are cached locally; the PDF URL, retrieval metadata and
SHA-256 checksum are recorded in `source_cache/ck_nefsc_garmiii_saxatilis_gom_chatt/manifest.csv`.

The 2018 importer records two-fleet total removals and age proportions for
1982–2017, eight relative-abundance index series with annual CVs, recruitment
indices, eight survey age compositions, age-specific fixed M, female maturity
and female proportions, and catch, January-1 and spawning weights. Table B10
reports age-1+ abundance, total F-at-age, age-1 recruitment, SSB-at-age and
SSB; the reported SSB SE is retained on its natural tonne scale. The 2018
record remains partial because complete native configuration and effective
composition sample sizes are not available.

The published index tables provide numerical values for 1982–2017. The model
text also describes Maryland YOY and age-1 indices in 1970–1981, but those
values are not tabulated in the available numerical appendix. They are not
invented or used in the translation; the tinyAM fit is restricted to the
1982–2017 overlap where catch, biology and reported population states are
available. Appendix B10 links YOY indices to age 1 and age-1 indices to age 2.
Its “VA Age 1” label conflicts with the “NY Age-1” label in Table B5.6 and
assessment diagnostics. The translation retains the table label, links the
series to age 2, and records the discrepancy.

For analysis only, the two catch fleets are each converted from totals times
age proportions and then pooled. Aggregate relative indices are combined
with their available age compositions to create age-specific index values;
composition proportions are normalized across available ages, and zero cells
are omitted from tinyAM's lognormal likelihood. These transformed observations
do not replace canonical totals or compositions. tinyAM uses a simpler
age-specific lognormal likelihood and does not reproduce the source's
multinomial compositions, time-varying CV weights, or fleet-specific
selectivity. Female maturity is multiplied by the fixed female proportion for
tinyAM's single maturity surface. Source SSB and derived January-1 biomass
remain distinct comparisons; derived biomass has no uncertainty.

The 1982–2017 tinyAM fit passed the numerical checks after the one permitted
retry with source-based N/F starting values; the default-start attempt did not
pass. The successful fit had optimizer code 0, maximum absolute gradient
0.00283, a positive-definite Hessian and successful SD reporting (168 fixed
and 575 random effects). The main disagreement is fishing mortality: its
mean absolute percent difference is 157%, terminal-year difference is +49%,
and trend correlation is 0.775. By comparison, total abundance has 12.0% mean
absolute percent difference and 0.991 trend correlation; recruitment has
11.5% and 0.986. SSB differs by 36.7% on average with a -27.4% terminal-year
difference, while its trend correlation is 0.986; the source and tinyAM SSB
definitions remain approximate. Fixed M matches because it is supplied as an
input, not estimated. See the local dashboard for the year- and age-specific
comparisons.
