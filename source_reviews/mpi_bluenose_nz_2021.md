# New Zealand bluenose (BNS), 2021 assessment

## Assessment unit and source status

The May 2026 Fisheries Assessment Plenary identifies the 2021 Casal2 model as
the latest completed bluenose assessment it reports. FAR 2021/82 describes that
production assessment and prints its base-run model inputs in Appendix D. The
model represents one New Zealand-wide biological unit with two sexes and two
population areas, `background` and `features`. BNS 1, 2, 3, 7, 8, and 10 are
management QMAs, not separate models in this assessment. The Plenary notes that
biological stock boundaries remain uncertain.

The assessment used Casal2 1.0.0. Its population model covers 1910–2021 and
ages 1–61+, with projections to 2126. Fishing years run October–September and
are labeled by ending year. The 2021 catch inputs repeat the 2020 values, as
specified in the population file.

## Inputs and assumptions recovered

- **Catch:** 10 fleet-specific catch-biomass series in tonnes, covering
  1936–2021 (860 fleet-year values).
- **Commercial CPUE:** 12 standardized relative biomass series, 11 longline
  and one trawl, with 98 annual index values and paired CVs. The CPUE
  observations are evaluated halfway through the fishery time step. The model
  uses series-specific nuisance catchability settings and fixed process-error
  values. No fishery-independent survey index is included.
- **Age compositions:** 15 multinomial observations: three trawl samples and
  12 bottom-longline samples. They are proportions with supplied
  `error_values`, not catch numbers-at-age or age-specific abundance indices.
  The trawl series covers ages 5–61+, and the line series covers ages 3–61+.
- **Length compositions:** Male and female trawl proportions for 1998–2000.
  `length_plus = false`, so the model input uses one fewer composition value
  than the number of length boundaries. The stored `length_bin` is the lower
  boundary of each interval. This follows the [Casal2 User Manual's
  proportions-at-length specification](https://docs.niwa.co.nz/library/public/NIWAtr139.pdf).
- **Weight compositions:** Four bottom-longline packing-data frequency series.
  The native bins are mean fish weights per box-part in kg, rounded to 0.1 kg;
  the model also specifies length bins, fish counts per bin, 12 kg fishboxes,
  lognormal length-weight variation, and a multinomial likelihood. The supplied
  `error_values` are retained as effective likelihood sizes, not raw fish
  counts. The Northland 2020 composition has 190 weight-bin values but no
  printed `error_values` entry; its `sample_size` is left blank rather than
  inferred.
- **Biology:** The model supplies empirical sex-specific length-at-age for
  ages 1–61, a fixed length-weight relationship, and fixed sex-specific
  maturity ogives. Stock weight-at-age is reconstructed from the supplied
  length-at-age and length-weight parameters; the transformation is recorded
  with the rows. Natural mortality is fixed at 0.08 per year for all ages,
  sexes, and areas.
- **Recruitment and spatial structure:** Recruitment is deterministic
  Beverton–Holt with fixed year-class strengths and steepness 0.84. The model
  includes movement from background to features. Estimated base-model
  parameters, their prior types and bounds, and the minimiser and MCMC settings
  are retained in `assumptions.csv`.

## Outputs and remaining source gaps

Table 5 reports the base-model MPD estimate of unfished biomass, B0 = 39,076
tonnes, 2021 spawning biomass as 25.3% of B0, and fitted selectivity and
movement parameters. The database retains those table values. It also records
an approximate 2021 SSB of 9,886.228 tonnes, derived from the rounded B0 and
percentage values; no uncertainty is attached to that derived value.

The report does not provide numerical annual N-at-age, F-at-age, recruitment,
or absolute SSB trajectories in tables. It shows some trajectories in figures,
which have not been digitized. The base model fixes M, so it has no estimated
M-at-age output. The report includes MCMC plots, but does not tabulate numeric
standard errors or confidence limits for the reported MPD quantities.

## Sources and local provenance

- [FAR 2021/82: The 2021 stock assessment of New Zealand bluenose](https://fs.fish.govt.nz/Doc/25020/FAR-2021-82-New-Zealand-Bluenose-Stock-Assessment-2021.pdf.ashx)
- [Fisheries Assessment Plenary May 2026, Volume 1](https://fs.fish.govt.nz/Doc/26241/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf.ashx), bluenose chapter

Both assessment documents are cached under the ignored
`source_cache/mpi_bluenose_nz_2021/` folder. Retrieval dates and SHA-256
checksums are recorded in `provenance/mpi_bluenose_nz_2021_sources.csv`. The
model input files are reproduced as text in FAR 2021/82 Appendix D; no separate
fitted object or numeric annual-output file was located.
