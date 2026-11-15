# Inside Yelloweye Rockfish

Reviewed 2026-10-29. DFO's Pacific inventory entry corresponds to the inside Yelloweye Rockfish population in Groundfish Management Area 4B. DFO distinguishes it from the outside population on the basis of genetic and geographic evidence.

## Current advice and detailed model evidence

The 2025/26 DFO Groundfish IFMP identifies June 2020 as the latest science advice for Inside Yelloweye. The detailed follow-up, Research Document 2021/008, evaluates rebuilding strategies with six age-structured stock-reduction-analysis operating models conditioned on observed catches, abundance indices, and available age compositions. The analysis covers data through 2019. DFO describes it as a rebuilding and management-strategy evaluation, not a new conventional assessment update.

The report documents age data collected in Area 4B from 1984–2018, primarily from the hard-bottom longline (HBLL) survey after 2003. Survey age compositions are used in the SRA and the model aggregates ages into an 80+ group. The report notes that age-composition samples are small. Commercial age samples are available from one 1989 fishing trip only; the model otherwise uses annual aggregate catches. The public, pinned [`pbs-assess/yelloweye-inside` repository at revision `2f9a8a4`](https://github.com/pbs-assess/yelloweye-inside/tree/2f9a8a4) contains processing scripts and privacy-compliant sample-data objects, including the survey-age and catch preparation workflow.

The report includes biological age and length data and sex-specific maturity-at-age ogives. A run-matched numeric weight-at-age table and a fractional within-year timing for the age observations were not verified in this screen. The report presents operating-model biomass trajectories and probabilities relative to reference points, but not standard annual N-at-age and F-at-age tables.

## Screening decision

Survey age compositions are verified, while the lone commercial age-sampling trip does not establish a representative annual catch-at-age series. The source set also needs verification of numeric weight-at-age, fractional timing, and comparable age-specific fitted outputs. Keep the source record as a follow-up candidate; do not treat the MSE projections as a conventional fitted assessment or fill missing inputs from model states. No canonical assessment or numeric series was imported.

## Sources

- [2025/26 DFO Groundfish IFMP](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4127698x.pdf), identifying the latest inside advice as June 2020 and describing the inside unit.
- [DFO Research Document 2021/008](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41058136.pdf), detailed rebuilding analysis and age-structured OM documentation.
- [Pinned source repository](https://github.com/pbs-assess/yelloweye-inside/tree/2f9a8a4), cited by the report and cached locally as a revision-specific archive.

The cited PDFs and repository snapshot are cached in the gitignored `source_cache/discovery_dfo_yelloweye/`; `sources.csv` records retrieval dates, URLs, sizes, and SHA-256 checksums.
