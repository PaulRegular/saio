# Northern cod (2J3KL) source review

For Northern cod, the database represents the 2025 production assessment under
the 2023 framework. DFO's detailed research document for that run was published
in April 2026; its model inputs extend through 2024 and selected estimates are
reported through 2025. DFO later published a 2026 assessment summary to 2026
(Science Advisory Report
2026/030). It is now represented separately as `dfo_cod_2j3kl_2026_summary`:
Table 1 aggregate estimates and Table 2 reported catch totals are preserved
under that event. The summary does not provide the full age-specific input and
model-output series. The 2025 production assessment remains the selected
current detailed record, and summary values are never blended into it.

## Separate 2026 summary-only update

The cached Science Advisory Report 2026/030 is entered as
`dfo_cod_2j3kl_2026_summary`, with `is_current = FALSE` and `is_applied = TRUE`;
the 2025 detailed assessment remains the selected detailed record. Table 1
(p. 5) contributes SSB and age-0 recruitment estimates for 2022-2026, and
population-weighted average M and F for ages 5+ in 2022-2025, all with the
published 95% confidence limits. The table does not specify a separate
point-estimator convention, and no standard errors are derived.

Table 2 (p. 6) contributes reported catch including bycatch for 2016-2025 by
NAFO division 2J, 3K and 3L. The 2025 values are provisional. Division rows are
preserved without a duplicate summed total. The report does not provide the
complete fitted catch-age vector, fleet mapping, age-specific 2026 N/F/M
surfaces, or native run files, so this remains a summary-only source record and
is not a tinyAM translation target.

The 2025 record contains 819 commercial catch numbers-at-age values for ages
2-14 in 1962-2024, plus all 71 reported 2J3KL landings values from 1954-2024.
The model uses landings as a bounded catch input and converts catch-age counts
to proportions for its composition likelihood. The fall RV data include 507
age-specific values and 40 total biomass index values used as the lagged cod-biomass
covariate for M; the total-abundance series in Table 6 is not included because it
is not an xteNCAM input. 2004 and 2021 are excluded from the age series, and
2022 was not surveyed.
The database also includes 239 age-specific sentinel values, 13 Smith Sound
biomass estimates and 119 sampled age counts, and 88 Fleming/Newman juvenile
index values. Table 9 and Table 10 each contribute 1,065 age-weight rows for
1954-2024. Table 8 reports 1,065 female maturity-at-age estimates as
calendar-year-by-age values for 1954-2024. The maturity model used a cohort
effect, but that does not change the table year-age indexing. Reported catch
counts remain counts in thousand fish; no
proportion-to-count conversion was needed. Fall timing is represented by a
0.75 season-level approximation; Smith Sound timing is derived from reported
months. Sentinel effective timing remains unresolved. Juvenile seasons are
recoverable, but exact annual model timing is not (see below).

The assessment remains partial. The 3L spring Capelin acoustic series is
digitized from Figure 32 of DFO Research Document 2025/061, which confirms the
spatial match to the cod model's Capelin covariate. The 31 years used in the
cod model are retained. Most plotted values were read from the log-kilotonnes
axis, rounded to 0.01 log units, and exponentiated to kilotonnes. The Capelin
assessment report gives exact rounded values for 2013 (668 kt), 2014 (779 kt),
and 2024 (647 kt); those three rows now use the report's stated values and are
labelled `official_document`. Other years remain approximate figure-derived
values, not the original unrounded acoustic estimates, and no uncertainty is
assigned.

A DFO Newfoundland and Labrador data release, [2J3KL Cod and Capelin Biomass
Indices](https://doi.org/10.5281/zenodo.17515115), was also checked. Its
`cap_acoustic.csv` series ends in 2019, omits the 2022–2024 cod-model years, and
differs from the selected 2025 Capelin assessment for several years (for
example, it lists 763 kt in 2013 and 1,060 kt in 2014). It is cached locally
with its record metadata and checksum as a cross-check, but is not substituted
for the current assessment series. Detailed tagging observations and
reporting-rate likelihood data are not represented. Smith Sound sample ages
14-16 are zero in every reported sample year, so there is no positive older-age
count needing an age-14 mapping. Tables 19-24 provide numerical abundance,
biomass, mature biomass, Z, M and F at ages 0-14. The earlier review overlooked
these tables; 6,435 rounded source values are now stored in outputs.csv.
Tables 19-21 cover 1954-2025 and Tables 22-24 cover 1954-2024. Age-specific
uncertainty is not tabulated and is left missing. Table 16
does report fitted F and natural-mortality process parameters; the F correlations
and variance and the M-process correlations, variance, baseline M, and Capelin
effect are now described in assumptions.csv. M is estimated in the model, not
supplied as an input.

## Source details retained from the modelling review

The production report supplies biomass (Table 11) and sampled counts (Table 12)
as separate observations. Seven years have both: 1995 and 1998-2003. These can
be translated to an index using `N[a] = B * p[a] / sum(p * w)`, with B converted
to kg, p the sample proportions and w in kg/fish. This is a reconstruction,
not a published abundance estimate or a replacement for canonical counts.

The framework research document (2025/034, p. 10, equation 2.14) uses stock
body mass in the Smith Sound biomass equation. Beginning-of-year stock weights
(production Table 9) are therefore preferable to mid-year catch weights
(Table 10, used for predicted fishery landings). They still approximate mass
at survey time: neither Smith-specific weights nor a within-year growth
surface is supplied. The zero age-0 and age-14-16 sample categories can be
removed before conversion without changing proportions or reconstructed
biomass. The age-1 biomass contribution is retained in the denominator even
when the tinyAM fit starts at age 2.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/dfo_cod_2j3kl.md). They do not determine source completeness or official run selection.

## Source context

The production report (2026/026, pp. 12–13) and framework (2025/034, pp. 14–15) specify shared, time-invariant catchability between Fleming and Newman, with independent q at ages 0 and 1. Newman sampling spans July–November. Both reports print Fleming timing in reversed order as October–September. The cached survey report (2022/056, pp. 1, 3, Table 8.3) resolves this to September–October and gives September 30–October 29 for 2020. Exact annual assessment timing remains unresolved. The framework fixes F at ages 0–1 to zero.

## Source context

Framework 2025/034, equation 2.26, relates age-zero recruitment to same-year SSB.
