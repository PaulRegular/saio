# Celtic Sea and Bristol Channel plaice

## Identity and current assessment

The Charbonneau–Keith stock `ICES-WGSCE_platessa_CS7f-g` is ICES
`ple.27.7fg`, Pleuronectes platessa in divisions 7.f and 7.g. Its existing
`stock_id` is retained. It is in the Northeast Atlantic, with the assessment
area separate from the basin label.

The detailed 2026 assessment provides advice for 2027–2028 using the category-3
**rfb rule**, method 2.1. It combines a UK beam-trawl biomass index and a
catch-length indicator. It does not estimate a current N/F/M-at-age surface,
recruitment or absolute SSB. Historical AP, SPiCT and benchmark SAM trials are
not substituted for current production outputs. The benchmark was held in
2022 and published in 2023; the 2026 advice invokes the 2025 category-2/3
guidelines.

The database event `ices_plaice_celtic_sea_7fg_2026` is current and applied,
with terminal year 2025. All three completeness statuses remain partial:
the current method and detailed published indicators are recovered, but the
original data files, exact package version and production rule object are not.
This is not a claim that a current age-based model has been recovered.

## Recovered inputs and outputs

Importer `153_import_ices_plaice_celtic_sea_2026.R` reads the checksum-pinned
official PDFs. The canonical addition contains **685 inputs, 11 assumptions
and 46 indicator outputs**.

- Final advice Table 8 supplies landings and discards separately, in tonnes,
  for 1988–2025. The 16 blank discard cells before 2004 stay missing. The
  advice describes earlier reconstruction from the 2004–2010 discard/landings
  ratio, but this import does not invent the unavailable original series.
  In 2025, landings are 107 t and discards 180 t (287 t combined).
- The same table supplies 38 annual UK(E&W)-BTS-Q3 biomass indices, in
  **kg per 100 km towed**. These rounded values are retained as inputs and
  reported indicators; they are one series, not two independent datasets.
  They are neither absolute biomass nor SSB. The 2025 index is 44.
- WGCSE Table 16.7 supplies 363 ancillary UK survey cells: 1993–2025,
  ages 0–10+, in fish per 100 km towed. They are age-specific abundance
  indices, not biological composition samples. The official rfb rule uses
  the biomass series; it does not fit these cells as additional age-index
  likelihood observations. Rounded totals are checked against age sums but
  are not duplicated as observations.
- Table 16.6 supplies 161 ancillary Irish survey cells for 2003–2025 and
  23 effort values in fished minutes. The caption says ages 1–8+, but the
  actual header and rows contain only ages 1–7. The printed labels are
  preserved without inventing an eighth age or assigning a plus group.
  Whether these numbers are raw catches or already standardized indices is
  unresolved. They remain on the source index scale, without division by
  effort. The Irish series is a supporting indicator, not an input to the
  current rfb calculation.
- Final advice Table 8 reports eight length-based fishing-pressure ratios,
  2018–2025: 1.03, 1.01, 1.06, 1.08, 1.03, 1.10, 1.06, 1.08.
  They are `LF=M/Lmean`, not instantaneous F, Fbar or age-specific mortality.
  No standard errors or intervals are reported or manufactured.
- WGCSE Table 16.5 supplies 24 corrected length summaries for 2018–2025:
  mean catch length, annual first-capture length and the 30-cm MSY proxy
  length. Their ratios reproduce the final advice's pressure indicator to
  reported precision. They do not reconstruct raw length frequencies.
  Annual first-capture length is descriptive; the pinned script uses a
  fixed 23.5-cm cutoff in its mean-length calculation.

The UK survey is in Q3, the Irish survey in Q4. These source season labels
are retained. The rule has no population-observation timing fraction, so
`sampling_time` remains blank; a quarter is not converted into an invented
exact sampling date. Commercial CPUE is not promoted to an abundance index:
the report explicitly regards those series as qualitative because fishing
policy and bycatch behaviour affect them. The contextual approximately 40%
discard survival is not explicitly incorporated in the source assessment and
is not applied to the observations.

## Conflicting source fields

The **final published advice** controls the canonical indicator values.

- WGCSE section 16.4 prints a biomass trend factor of 0.55 despite both
  index means being about 40, and retains a stale 114-t conclusion. The
  final advice correctly reports `r = 1.0` and advice of **77 t** for each
  of 2027 and 2028. Rounded `f = 0.92`, `b = 0.77`, `m = 0.95` and
  `Ay = 114 t` approximately reproduce that advice; exact unrounded inputs
  are unavailable.
- SAG key 22650 stores the biomass index in a generic `SSB` column and labels
  it kg/km2. Final advice Tables 1, 3 and 8 and the pinned rule script specify
  kg/100 km. No numerical rescaling is made: the advice values are imported
  under their published definition, and the SAG label is not taken literally
  as absolute SSB or used to infer swept area.
- SAG's length-proxy series differs from final Table 8; for example 2025 is
  1.09 in SAG and 1.08 in the advice. SAG also has 2012 discards of 1,115 t,
  versus 1,123 t in the final advice. These exceed rounding differences.
  Neither series is blended into the final published table.
- All 38 SAG biomass-index values agree with the final advice to its printed
  precision. This cross-check supports the numerical series, but does not
  validate SAG's conflicting unit label or make the indicator absolute SSB.
- Other WGCSE catch cells also conflict with final advice, including 2019
  landings. The importer uses the identified final table consistently rather
  than repairing conflicting cells using undocumented choices.

## Native files and framework

The official repository exists at
`ices-advice/2026_ple.27.7fg`, pinned at
`83dec5135007b7c6443d78cea8fe4c1a6a72c9fd` (18 September 2026).
It contains scripts, but `DATA.bib` lists local `PLE LPUE.csv`,
`advice_history.csv` and `IC_combined.csv` without download URLs. Neither
those files nor a production `advice.rds` are in the tree. The biomass script
uses column `BC`; catch lengths are raised InterCatch numbers by length.
`report_sg.R` still sets `ass_yr = 2024`, and bibliography periods end in
2022/2023. Therefore a 2026 repository name alone does not establish an exact
production snapshot. The code is inspected as text, not executed.

The script documents a fixed Lc of 235 mm and LF=M of 300 mm, a generic
life-history multiplier from k = 0.11 and a conditional biennial stability
clause. These help interpret the method, but are not used to reconstruct
unavailable 2026 length-frequency inputs or to certify an exact production
package version. Historical benchmark weights, maturity, growth and trial
assessment states are not current input surfaces.

Original sources, pinned scripts, repository metadata and checksums are
cached in the gitignored
`source_cache/ck_ices_wgsce_platessa_cs7f_g/` folder. The catalogue scientific
identity and area were checked against the 2026 advice before updating the
existing stock row.

## Translation and comparison limit

No tinyAM recipe or fit is claimed. Current catch-at-age, annual stock-weight
and maturity surfaces and a verified numerical M specification have not been
recovered for a source-faithful age-structured translation. Original raised
catch-length data are also absent, and length frequencies cannot be allocated
to age without validated additional information. Ancillary survey-at-age
tables alone do not supply the missing inputs.

The current production assessment itself has no N/F/SSB estimates to compare.
Its survey-biomass and length-pressure indicators must not populate the
standard SSB or F reference tables. Tests enforce that distinction and the
runner reports no stock specification when preparation is requested. This is
an explicit source/assessment-structure shortfall, not numerical
non-convergence and not a completed translation. Older analytical model
trials would require a separately justified historical assessment event;
they are not a silent fallback.

## Validation

The importer passed a second-run byte-identical check and preserved every
unrelated canonical row. Full database validation passed: 118 stocks,
115 assessment events, 2,218 assumptions, 364,298 inputs and 195,113 outputs.
The new source test and six related reference, plus-group, comparison,
initialization and unit checks passed (seven assessment-analysis scripts).
The original readiness table and shared model-comparison tables were not
regenerated. The full package suite (2,936 passes) and package-only check
(Status: OK, tests run separately) passed at the preceding Area 4 reporting
milestone; they were not repeated after this analysis-only source addition.
The broader assessment-analysis suite was not rerun, and its previously
recorded unrelated failures are not claimed resolved.
## Sources

- [Official 2026 advice](https://doi.org/10.17895/ices.advice.30932282), Tables 1, 4 and 8.
- [WGCSE 2026](https://doi.org/10.17895/ices.pub.32625759.v1), chapter 16, especially Tables 16.6–16.7.
- [2022 benchmark, published 2023](https://doi.org/10.17895/ices.pub.21558681).
- [Category-2/3 guidelines](https://doi.org/10.17895/ices.pub.28506179).
- [Pinned official repository](https://github.com/ices-advice/2026_ple.27.7fg/tree/83dec5135007b7c6443d78cea8fe4c1a6a72c9fd).
- [SAG 22650](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22650), retained locally to document discrepancies.
