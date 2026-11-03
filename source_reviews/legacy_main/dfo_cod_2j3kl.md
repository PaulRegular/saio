# Northern cod (2J3KL) source review

For Northern cod, the database represents the 2025 production assessment under
the 2023 framework. DFO's detailed research document for that run was published
in April 2026; its model inputs extend through 2024 and selected estimates are
reported through 2025. DFO later published a 2026 assessment summary to 2026
(Science Advisory Report 2026/030), but it does not provide the full numerical
input and model-output series needed to link those data to that run. Following
the selection rule above, the 2026 summary is not entered as a separate
assessment and none of its values are mixed into the 2025 record.

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

The assessment remains partial. The spring Capelin acoustic series is shown in
the detailed 2025 Capelin report but not tabulated; its exact spatial match to the
model's 3L covariate is unresolved. Detailed tagging observations and
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

## Smith Sound translation

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

The integration trial fits independent Smith catchability by informative age,
separate from RV catchability, and a separate observation SD. It does not
reproduce xteNCAM's latent local population fraction, age-year availability
process or normalization `max(q) = 1`. The existing 1995-2007, age-block RV
catchability adjustment is retained as a proxy for offshore availability
during the period with approximately more than 10 kt in Smith Sound. It is
not an exact translation of the source's 1995-2009 availability process.

## Juvenile timing and integration

The production report (2026/026, pp. 12-13) and framework research document
(2025/034, pp. 14-15) specify shared, time-invariant catchability between
Fleming and Newman, with independent q at ages 0 and 1. Newman sampling spans
July-November. Both reports print the Fleming season in reversed order as
October-September. The cited Fleming survey report (2022/056, pp. 1, 3 and
Table 8.3) resolves this to September-October; it also gives 2020 dates of
September 30-October 29. That supporting report is cached locally.

The integration trial uses season midpoints 9.5/12 for Fleming and 9/12 for
Newman. These are explicit translation approximations, not recovered annual
xteNCAM timing parameters; canonical sampling_time remains missing. The trial
extends tinyAM to ages 0-14. The source fixes F at ages 0-1 to zero
(2025/034, p. 15); tinyAM's current process estimates F at every modeled age.
That constraint cannot be reproduced with the current interface and is not
silently relaxed in the main age-2+ recipe. Trial diagnostics determine whether
the extra indices can be fitted numerically, not whether this limitation is
scientifically negligible.

## Common definitions

Compare N and mortality at matching ages. Sum official N, biomass and mature
biomass only over the tinyAM ages; do not compare official age-0+ totals with
tinyAM age-2+ totals. Table 17's native age-0 recruitment is not compared with
tinyAM recruitment. The official N-at-age surface supplies a separately
labelled age-2 abundance comparison with tinyAM recruitment. Common F/M means use the matching N and
age-specific mortality surfaces with tinyAM's population weighting. Preserve
the native Table 17/18 aggregates for dashboard context and label comparisons
derived from rounded age-specific tables separately. No plot digitization or
invented SEs are used.

## Recruitment and juvenile limitations

Framework 2025/034, equation 2.26, relates age-zero recruitment to same-year
SSB. The age-2+ translation retains RW recruitment rather than treating a
survivor approximation as the same stock–recruit relationship. Fleming and
Newman observations remain canonical but are omitted from the retained fit.
Their timing approximations and the source zero-F constraint at ages 0–1
prevent a direct translation with the current age structure.
