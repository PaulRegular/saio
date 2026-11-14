# Sub-Antarctic ling (LIN 5&6 and LIN 6B), 2024 assessment

Reviewed 6 November 2026. The source PDFs and checksums are listed in
`provenance/mpi_ling_lin56_2024_sources.csv` and cached under the ignored
`source_cache/mpi_ling_lin56_2024/` directory.

## Stock unit and latest assessment

The Fisheries Assessment Plenary May 2025 identifies the 2024 Sub-Antarctic
ling assessment as the latest assessment used for advice, with the next
assessment planned for 2027. The May 2026 Plenary confirms that LIN 5&6 and
LIN 6B were last assessed in 2024 and remain scheduled for assessment in 2027
(printed pages 861 and 892). The same 2026 report lists separate 2025 and 2026
updates for LIN 3&4 and LIN 7WC; those are different biological stocks. The
2024 assessment is a two-sex, age-based statistical catch-at-age model
implemented in Casal2 v24.02. Its model years are calendar years, and the
reported observations extend through 2023.

The 2024 unit combines LIN 5&6 and LIN 6B in one biological population. LIN 6B
is represented as its own fishery and shares the LIN 5&6 biological parameters
and recruitment. Statistical Area 032 catches were moved from the Sub-Antarctic
unit to LIN 7WC. The database records the current 2024 unit, not LIN 5&6 alone
from the preceding assessment.

## Recoverable inputs

FAR 2024/82 Appendix E, Table E.1 provides annual catch biomass in tonnes for
1972-2023 for LIN 5&6 bottom trawl, LIN 5&6 bottom longline, and LIN 6B bottom
longline. The report says LIN 5&6 bottom longline includes potting catches and
LIN 5&6 bottom trawl includes other catches.

FAR 2024/84 Table 2 gives the years for the two Tangaroa survey biomass and
age-composition series and the LIN 5&6 commercial longline and trawl age
compositions. The model uses sexed ages 3-21 for the survey (age 21 is the plus
group) and sexed ages 3-28 for the commercial fisheries (age 28 is the plus
group). FAR 2024/84 does not tabulate the numerical fitted survey-index values,
their CVs, or the age-composition vectors and effective sample sizes for the
selected run. Those likelihood values are not reconstructed from plots or
later observations.

The report describes a non-spatial LIN 5&6 longline CPUE series for 1991-2023
and a spatially explicit LIN 5&6/LIN 6B series from 2004-2023. Neither series
is in the 2024 base case; CPUE treatments are sensitivities.

The base assessment fixes natural mortality at 0.18 per year for both sexes,
constant at age. Table 3 reports stock-recruitment steepness 0.84, recruitment
variability sigma-R 0.7, ageing-error CV 0.06, proportion male at birth 0.5,
proportion of mature fish spawning 1.0, and maximum exploitation rate 0.6.
Tables 3-4 provide sex-specific growth and length-weight parameters and
maturity proportions at ages 3-13. The reports do not provide a direct
weight-at-age matrix or maturity values outside the tabulated ages. The import
retains the reported parameters and values without extending those schedules.

The model annual cycle has January-August and September-December steps; Table 1
describes mortality and observation timing by step. The annual cycle and its
reported fractions are recorded as assumptions; no single fractional sampling
time is assigned to the seasonal observations.

## Additional detailed source reports

FAR 2024/74 Tables 11 and 17 report sex-specific calculated numbers-at-age
for the LIN 5&6 trawl and non-spawning longline fisheries in the 2022–23
fishing year. FAR 2024/84 Table 2 lists fitted age-composition observations
only through model year 2022, so the 2023 estimates are not imported as inputs
to the selected 2024 run. Earlier year-by-age series in FAR 2024/74 are shown
as figures rather than numerical tables.

FAR 2024/74 also reports a January 2024 trawl survey for the Chatham Rise
stock, but states no Sub-Antarctic survey was scheduled in 2024. It therefore
adds no later Sub-Antarctic survey values for the selected assessment.

FAR 2024/85 describes observer coverage and sensitivity analyses that remove
bottom-longline age compositions. It confirms those age compositions were
used in the selected model, but does not publish their numerical input vectors.

## Recoverable outputs

FAR 2024/84 Tables 8-11 report posterior biomass and relative-spawning-biomass
summaries for CPUE and natural-mortality sensitivities and for projections to
2029. These are imported with their published scenarios and intervals. Table 11
labels the LIN 5 exploitation probability as pLIN5 < U40, although the caption
says “over U40”; the source text also describes the below-target probability.
The imported measure follows the table heading and preserves this wording
discrepancy in its notes. No absolute annual SSB trajectory or annual N-, F-,
M-at-age or recruitment table was located; those remain unavailable as
numerical records.

The 2025 and 2026 Plenary reports are used as current-run cross-checks, not to
replace the 2024 assessment values. The 2026 report confirms that the
Sub-Antarctic unit's latest assessment remains the 2024 run.

## Source completeness

The canonical database now contains 156 annual catch-biomass records for
1972-2023, 56 fixed M-at-age records, 22 reported maturity-at-age values, 24
model and biological assumptions, and 80 posterior summary and projection
outputs from Tables 8-11. The assessment remains partial: numerical survey
indices and fitted age-composition vectors for the selected run are not
published in the reviewed sources. No values are filled from the 2021
assessment, fitted trajectories, or later-year observations.
