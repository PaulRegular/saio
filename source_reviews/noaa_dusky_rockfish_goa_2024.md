# Dusky rockfish in the Gulf of Alaska

## Current unit and assessment

NOAA Stock SMART identifier 10559 is the Gulf of Alaska dusky rockfish
(*Sebastes variabilis*) unit. The latest detailed assessment located is the
November 2024 SAFE assessment, model m22.5a, with data through 2024. The GOA
Plan Team agreed with m22.5a, and the Council used that assessment for 2025
harvest specifications. The 2026 SAFE chapter is a pre-dissemination harvest
projection from the 2024 assessment; it reports no new model fit. The 2026
projection is cached for context but its projected years are not mixed into
the 2024 assessment record.

## Inputs and assumptions recovered

The SAFE reports commercial catch biomass in metric tons for 1977–2024. The
table has no 1987 value, which is retained as missing. It identifies foreign
observer data, joint-venture data and the NMFS Regional Office Catch
Accounting System as sources.

Table 12-7 reports fishery age proportions for ages 4–29 and a 30+ group in
2000–2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020 and 2022. Table 12-10
reports bottom-trawl survey age proportions for the same age groups in 1990,
1993, 1996, 1999, 2001, 2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017,
2019, 2021 and 2023. Both tables include input sample size (`n_iss`), haul
count (`n_h`) and effective sample size (`n_ess`). The fishery table's years
do not match the main-text model data summary exactly. Its reported rows are
stored as published source data, but the import does not claim that they are
the exact composition arrays in the final likelihood.

Table 12-9 reports NMFS bottom-trawl VAST biomass estimates and natural-scale
standard errors in metric tons for 1990–2023, with lower and upper confidence
limits. The table does not state the nominal confidence level. It identifies
VAST lognormal error as the m22.5a survey likelihood. No fractional survey
timing is reported.

Natural mortality is fixed at 0.07 per year. The report provides a
weight-at-age equation with parameters `W_inf = 1928 g`, `kappa = 0.190`,
`t0 = 0.607` and `b = 3.0`; it says the curve was constructed outside the
model from combined-sex survey age/length data. The numeric weight-at-age
vector is not tabulated. Female maturity is fitted conditionally with a
logistic curve and binomial likelihood from observations cited to Lunsford
(1997, personal communication) and Chilton (2010). The report gives age at
50% maturity as 10.1, but does not tabulate the underlying observations or
both fitted coefficients.

## Outputs recovered and remaining gaps

Tables 12-12 and 12-14 report annual female SSB, total biomass, fully selected
F and age-4+ recruitment through 2024. Table 12-12 provides maximum-likelihood
point estimates. Table 12-14 provides MCMC means and 2.5/97.5 percentile bounds
(described in the report as 95% confidence bounds). Source units are retained:
the MLE recruitment table uses millions of fish, while the MCMC table uses
thousands. No 2025–2026 projections are imported. The assessment does not
provide numeric annual N-at-age or F-at-age tables.

The source import is therefore partial. It preserves aggregate catch biomass,
the two published composition tables, the aggregate VAST survey index and its
reported uncertainty, selected model/biology assumptions, and aggregate MLE
and MCMC outputs. Exact final fishery composition arrays, raw maturity
observations, the full maturity coefficients, numeric weight-at-age values,
survey timing, N-at-age and F-at-age remain unavailable or unresolved.

## Sources

- [2024 GOA Dusky Rockfish SAFE chapter](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAdusky.pdf), Tables 12-2, 12-7, 12-9, 12-10, 12-12 and 12-14.
- [December 2024 GOA Groundfish Plan Team report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+PT+Report.pdf&p=7edd1c8f-f0ce-4936-9fd9-cc1353fe8d0e.pdf), recording agreement with model m22.5a for the 2025 cycle.
- [2026 GOA Dusky Rockfish projection](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=12.+GOA+Dusky+Rockfish.pdf&p=ed574dbd-35fa-43dc-99f0-a80909caf4d5.pdf), a projection without a new assessment fit.
- [NOAA Stock SMART record 10559](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10559).

The 2024 SAFE and 2026 projection are cached under
`source_cache/discovery_noaa_dusky_rockfish_2024/`. Their URLs, retrieval
dates, checksums, byte sizes and cache filenames are recorded in
`provenance/discovery_noaa_dusky_rockfish_2024/sources.csv`.
