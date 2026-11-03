# DFO NAFO Division 4T white hake: 2024 assessment to 2022

## Assessment identity

The latest detailed assessment located for the current DFO management unit is
the 2024 assessment of white hake (*Urophycis tenuis*) in NAFO Division 4T,
documented in DFO Research Document 2025/008. The assessment model covers
1978-2022 and ages 2-10+. The assessment is separate from the NOAA Gulf of
Maine/Georges Bank white hake unit. The report notes that the broader biological
stock unit also extends into northwest 4Vn, but the population model includes
the 4T area only.

The detailed report PDF and catalogue record are cached in the local,
gitignored source cache. The Science Advisory Report 2024/055 is available from
the official DFO site, but the PDF download did not succeed from the DFO or
catalogue links during this review; its reported status and trends are also
covered in the detailed report.

## Imported inputs and assumptions

- Table A2 reports nominal landings totals across commercial gears in tonnes.
  Totals for 1978-2022 are preserved as the available annual fishery catch
  series. Reported recreational catch is unknown; the report cites an anecdotal
  estimate of 0.5 t per year for St. George's Bay. No recreational, discard, or
  4Vn removals were added to the table totals.
- Table A4 reports commercial fishery catch numbers in thousands for 1978-2022
  in native bins 0-2, ages 3-12, and 13+. These bins are preserved as
  `numbers_at_age_group`, with the lower age in `age` and the source interval in
  notes. They do not match the assessment grid of ages 2-10+, so they cannot be
  treated as exact single-age observations or directly aligned to that grid.
  Source dashes remain missing values; printed zeroes remain zero.
- Table A5 reports September Research Vessel stratified mean catch rates at
  ages 2-14, in fish per tow, for 1978-2022 and strata 415-439. The values are
  preserved as an age-specific index-scale series, rounded as printed. A value
  of 0.000 may be rounded. The model's native survey likelihood uses
  proportions-at-age and age-aggregated biomass indices for ages 2-7; Table A5
  is not substituted for those native inputs.
- Table A6 reports RV mean weights-at-age in kg for 1978-2022. Its printed
  headings place age 12 before age 11, so values follow the printed labels and
  that ordering is documented rather than silently corrected. The report says
  missing weight-year values were predicted with a Gompertz model and that all
  2015-2022 weights were predicted; it does not identify observed versus
  predicted status for every other table cell. Fishery and Mobile Sentinel
  weight vectors were not recovered.
- The model assumes knife-edge maturity: ages 2-3 are immature and age 4+ is
  mature. This is stored as an assessment assumption, not as measured maturity
  observations.
- The model estimates separate log-scale random-walk natural-mortality series
  for ages 2-3, 4-5, and 6+. M is not a fixed input. Age-2 recruitment is
  estimated with log-average recruitment, annual deviations, and an
  autocorrelation term. Fishery selectivity is logistic and estimated
  separately for 1978-1995 and 1996-2022.
- The assessment uses the continuous RV series with one catchability parameter
  and the survey conversion factors applied. Survey compositions are modeled
  with a multivariate logistic distribution. Priors and numerical process
  settings are described but not fully tabulated in the report.

The assessment describes RV sampling in September and Mobile Sentinel sampling
in August. Neither report gives a within-month fraction of year, so no
fractional sampling time is stored. Numerical RV age proportions and
age-aggregated biomass indices, Mobile Sentinel indices and compositions, and
the fishery and Mobile Sentinel weight vectors remain unavailable from the
recovered source files.

## Imported outputs

The report prose provides rounded SSB estimates for 2000, 2014, and 2022; M
values for selected years in each estimated age group; and selected F values
for ages 4-5 and 6+. Those reported values are stored with `official_document`
provenance. The report describes plotted estimates as posterior medians, but
numeric uncertainty for these points is not included in the prose. The figures
show full trajectories and intervals, but no full annual N/F/M arrays or
numerical interval series were recovered or digitized.

Accordingly, `assumptions_status`, `inputs_status`, and `outputs_status` remain
`partial`. The current record is useful for source review and preserves
verified quantities, but the grouped catch bins and missing native survey
inputs do not yet support a faithful.

## Validation

The importer checks its cached report checksum, table coverage, duplicate
year-age cells, candidate identity, and duplicate assessment IDs. The source
test checks the table values, units, age ranges, missing cells, assumptions,
reported output values, provenance, and partial completeness status. The
canonical database validator checks the complete database after import.

## Sources

- [DFO Research Document 2025/008](https://open-science.canada.ca/server/api/core/bitstreams/28963929-7d4b-47c6-a56d-c0d705be4621/content)
- [Government of Canada catalogue record for Research Document 2025/008](https://publications.gc.ca/site/eng/9.947511/publication.html)
- [DFO Science Advisory Report 2024/055](https://www.dfo-mpo.gc.ca/csas-sccs/Publications/SAR-AS/2024/2024_055-eng.pdf)
