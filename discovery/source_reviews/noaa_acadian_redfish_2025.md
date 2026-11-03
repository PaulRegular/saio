# NOAA Acadian redfish, Gulf of Maine / Georges Bank

- **Source review:** 2026-11-03
- **Official assessment:** 2025 Management Track, Stock SMART assessment 14070
- **Run:** Run 5, WHAM 2.1.0.9002, commit `47506172e9a55376137501608e645ddae8a574e9`
- **Fitted years:** 1963–2024
- **Status:** Source inputs curated; outputs partial; started.

## Assessment identity and sources

The run-specific SASINF bundle identifies the assessment as an ASAP-like WHAM
model and includes its input file, R model code, report, and fitted tables. The
NOAA Stock SMART record gives the assessment ID as 14070 and the terminal data
year as 2024. The September 2025 peer-review panel found that the assessment met
its terms of reference and represented best scientific information available.
The older Stock SMART model label says ASAP; this review uses the run-specific
model code and fitted report tables for the 2025 run.

Source links: [2025 assessment report](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=1&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&filename=2025_RED_UNIT_RPT_2025_09_17_121440.522737.pdf), [Run 5 input](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=1&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=2025_RED_UNIT_MOD_BaseWHAMInput.DAT), [Run 5 model code](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=1&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=2025_RED_UNIT_MOD_BaseWHAMCode.R), [fitted figures and tables](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=1&stock_id=6&review_type_id=3&info_type_id=1&map_type_id=&filename=2025_RED_UNIT_FIG_FiguresTables.zip), [peer-review panel report](https://www.fisheries.noaa.gov/s3/2025-11/September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf).

The source ZIP and standalone files are cached under the gitignored
`source_cache/discovery_noaa_acadian_redfish_2025/` folder. Its `sources.csv`
records retrieval date, source URL, revision, file size, and SHA-256. The HTML
table used below is also checksummed as an extracted member of the official
figures-and-tables ZIP. The cache includes the 2023 assessment and 2024
state-space assessment reports as background; they are not treated as the
specification for the 2025 WHAM run.

## Model inputs

The native input spans 62 years, 1963–2024, and ages 1–25 plus 26+. It has one
commercial trawl fleet and two NEFSC abundance indices, spring and fall.

- Annual catch is retained as aggregate catch biomass in metric tons. The
  accompanying age composition is retained as number proportions, together
  with the source-supplied effective sample size and total-catch CV. The source uses a
  logistic-normal AR(1) age-composition likelihood; zero entries are treated
  as missing. Years with zero effective sample size have no observed
  composition rows in the database.
- Each survey's aggregate index is retained on its native number-index scale.
  The ASAP unit code is 2 (numbers), but the physical multiplier is not stated;
  the values are not rescaled. Survey age compositions are retained separately
  as number proportions with their effective sample sizes. The source month is
  4.5 for spring and 10.5 for fall; fractional-year sampling time is calculated
  as `(month - 1) / 12`, while the original month is preserved in the source
  inputs and assumptions.
- The three weight-at-age matrices retain their source roles: catch weight,
  spawning weight, and January 1 biomass weight. Both survey index weight
  pointers refer to matrix 3. The age-specific maturity schedule and all three
  weight matrices are constant over years. Natural mortality is fixed at
  0.05 per year at every modeled age.
- The source sets the SSB calculation at 0.4 of the year. The model code uses
  age-specific, time-invariant selectivity and a mean-recruitment process with
  annual AR(1) variation. Initial numbers use the equilibrium-age setup.

The canonical inputs preserve the official values and native observation
components. They do not replace the original index series with fitted values.

## Fitted outputs and derived summaries

The machine-readable fitted tables report N-at-age in thousands of fish and
trawl F-at-age in year⁻¹. The tables extend through 2028, but 2025–2028 are
projection years. Only fitted historical values through 2024 are entered as
age-specific outputs; `estimate_terminal_year` records that the supplied tables
also extend through 2028.

The parameter table reports spring and fall fully selected q, mean recruitment
to age 1, and the annual recruitment AR(1) correlation, each with an estimate,
standard error, and 95% confidence interval. The q estimates remain on the
source index scale. The fitted age-year N and F tables do not provide
cell-specific uncertainty.

The database also records three clearly labeled derived series from the
reported N-at-age and F-at-age tables:

- total abundance is the sum across ages 1–25 and 26+;
- recruitment is age-1 abundance;
- SSB is calculated at the source's 0.4-year timing as
  `sum(N_at_age * spawning_weight_at_age * maturity * exp(-(F + M) * 0.4))`.

The SSB calculation uses the official age schedules and rounded table values.
The total-abundance, recruitment, and SSB rows have no calculated uncertainty.
The assessment output status remains partial because the age-specific output
uncertainty is unavailable and the annual SSB series is derived rather than
reported in the machine-readable tables.

## Remaining limitations

- The physical multiplier for the native number-index scale is not specified;
  no conversion is guessed.
- A fitted model object was not recovered. The pinned model code, native inputs,
  fitted age tables, and parameter table are available.
- Full uncertainty for annual N, F, total abundance, recruitment, and SSB is not
  available in the extracted tables. Any future translation
  should compare the source scale, age grid, survey timing, and the spawning
  biomass definition explicitly.
