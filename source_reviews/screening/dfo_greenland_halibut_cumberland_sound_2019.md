# DFO Greenland halibut — Cumberland Sound Turbot Management Area

## Unit and assessment

The DFO sustainability inventory lists the Cumberland Sound Turbot Management
Area separately from Greenland halibut in NAFO Subarea 0A and 0B. DFO's 2019
Subarea 0 Integrated Fisheries Management Plan also excludes the Cumberland
Sound management area and says its TAH is separate from the Subarea 0 quota.
The 2019 science review describes seasonal movement between Cumberland Sound
and Division 0B, as well as emigration to Davis Strait. The inventory crosswalk
therefore identifies a distinct management unit, not a biologically isolated
population.

The latest assessment located is the regional peer review held November 25–27,
2019, published as *Assessment of Cumberland Sound Greenland Halibut in 2019*,
DFO Science Advisory Report 2026/007 (February 2026). The report says additional
meeting publications would be posted when available. A detailed research
document and native model files were not located. The official publication PDF
URL redirected to the Government of Canada archived-information notice during
local retrieval on 2026-10-29, so no placeholder was retained as a cached PDF.
The report text was reviewed through the official publication record. Cached
supporting files are listed in the ignored local source cache manifest.

## Inputs and outputs relevant to an age-structured model

- **Catch:** landings are reported to DFO during the fishing year, and plant
  samples have been collected since 1987. Samples include fork length, round and
  dressed weight, sex, maturity condition and otolith extraction. The reviewed
  assessment reports catch length-frequency, but no run-matched catch numbers
  at age or age-composition likelihood input.
- **Survey:** an annual fishery-independent bottom-longline survey began in
  2011, with five depth strata (201–400, 401–600, 601–800, 801–1,000 and
  1,001+ m), equal effort allocation and a minimum of three sets per stratum.
  Sets soak overnight for 12 hours. Set catches are reported in numbers and
  total weight, converted to densities per km² using the area fished, then
  expanded by stratum area and summed to annual abundance and biomass indices.
  The reported series spans 2011–2018; biomass is unavailable for 2011–2012 due
  to unstable vessel-scale calibration. These are aggregate indices, not
  age-specific abundance observations.
- **Biology and mortality:** sampled fish have length and weight records, and
  sex/maturity observations, but the report does not provide run-matched
  weight-at-age or maturity-at-age inputs. It recommends developing updated
  age-length relationships. The report recommends estimating natural and
  fishing mortality from tagging data rather than supplying age-specific
  mortality values.
- **Assessment outputs:** DFO developed a generic DLMTools population model,
  but it had poor convergence and was not used for science advice. The report
  provides aggregate survey indices and fishery trends, not accepted model
  outputs for N-at-age, F-at-age, recruitment or spawning biomass.

## Screening decision

The inventory row is crosswalked to the provisional unit
`greenland_halibut_cumberland_sound_tma`, with no asserted official stock code
and no canonical numerical records added. It is ineligible for the current
age-disaggregated assessment set because the latest review does not expose
age-structured input matrices or accepted population-at-age outputs. The
aggregate survey index and sampled age structures are not substitutes for
those missing quantities.

## Sources

- [DFO Science Advisory Report 2026/007](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-007-eng.pdf), assessment review from 2019.
- [DFO Integrated Fisheries Management Plan for NAFO Subarea 0](https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/groundfish-poisson-fond/2019/halibut-fletan-eng.htm), which distinguishes the Cumberland Sound area.
- [DFO 2026–2027 Greenland halibut Subarea 0 TAC notice](https://www.dfo-mpo.gc.ca/fisheries-peches/commercial-commerciale/atl-arc/2026/halibut-fletan-2026-2027-tac-eng.html), consulted as current management context, not as assessment output.
- Cached supporting PDFs: `dfo_sar_2008_040_cumberland_greenland_halibut.pdf` and `dfo_ifmp_nafo_subarea_0_2019.pdf` under the ignored local source cache. The source manifest records their retrieval dates and SHA-256 checksums.
