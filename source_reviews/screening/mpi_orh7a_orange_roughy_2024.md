# Challenger Plateau orange roughy (ORH 7A) — 2024 assessment

## Stock and assessment

ORH 7A is the orange roughy stock on the southwest Challenger Plateau, including Westpac Bank outside New Zealand’s Exclusive Economic Zone. Fisheries New Zealand treats these areas as one stock. The 2024 assessment was accepted by the Deepwater Working Group and Plenary and used for scientific advice. The May 2026 Plenary still identifies 2024 as the most recent assessment.

The accepted base case is All2. All6 and 3Series are assessment sensitivities, not additional stocks or assessment years. The report provides the complete CASAL estimation file in Appendix A. The 2026 Plenary summarizes MCMC estimates from this assessment.

## Inputs recovered

The All2 model inputs are represented in the database:

- Catch biomass, including the report’s over-run adjustments, for model years 1981–2024. These correspond to fishing years 1980–81 through 2023–24. The terminal catch was assumed equal to 2022–23.
- Six Thomas Harrison trawl-survey spawning-biomass indices for 2006, 2009, 2011, 2012, 2013 and 2018. The model CVs include the report’s additional 20% process error.
- Two aggregate acoustic spawning-biomass indices for 2009 and 2013, which are the only acoustic observations used in All2. Other years and area-specific series in the report belong to All6 or 3Series sensitivities and are not mixed into the base-case input series.
- Four trawl-survey age-frequency samples and two Volcano age-frequency samples. Each sample contains proportions for ages 15–100, with age 100 as the plus group. The likelihood effective sample sizes are 10, except for Volcano 2018, which is 5. The values are the published CASAL inputs and have not been renormalized.

The report states that the assessment had no commercial age-frequency data. The age-frequency samples are survey compositions, not age-specific abundance indices. No catch-at-age series or age-specific index was created from them. The fitted data therefore comprise aggregate catch and survey biomass with survey age compositions; the assessment does not report catch-at-age or an age-specific abundance index.

The model is single-sex and age-structured, with deterministic recruitment and an estimated logistic maturity/selectivity ogive. The appendix gives a von Bertalanffy length-at-age function and a length-weight relationship rather than numeric age-specific weight or maturity surfaces. The reported M parameter is age-invariant and estimated with a broad lognormal prior. The report cautions that this estimated M includes other undefined productivity factors and is not directly comparable to natural mortality.

The CASAL input places observations in time step 2 with proportion_mortality=0.5. The CASAL manual defines this as the share of mortality in that step occurring before the observation. It is not a 0.5 fraction of the calendar year, so no calendar-year sampling_time has been assigned.

## Outputs recovered

The 2026 Plenary reports MCMC medians, 95% credible intervals, and 2024 stock-status probabilities for All2, All6 and 3Series:

| Run | M (per year) | B0 (thousand tonnes) | B2024/B0 (%) | P(>50% B0) | P(>30% B0) | P(<20% B0) | P(<10% B0) |
|---|---:|---:|---:|---:|---:|---:|---:|
| All2 (base) | 0.033 (0.020–0.054) | 99.4 (87.6–117.2) | 35 (16–57) | 0.09 | 0.66 | 0.07 | 0.00 |
| All6 | 0.024 (0.016–0.037) | 98.5 (91.3–110.3) | 16 (8–35) | 0.00 | 0.06 | 0.71 | 0.12 |
| 3Series | 0.031 (0.020–0.045) | 97.5 (89.3–110.5) | 29 (18–44) | 0.09 | 0.44 | 0.05 | 0.00 |

The 2024 report does not tabulate annual or age-specific abundance, spawning biomass, fishing mortality or natural-mortality surfaces. The output record is therefore partial. The database retains the reported status ratio and B0 separately; it does not multiply their marginal medians to invent an absolute SSB estimate.

## Sources and cached files

The three authoritative PDFs were downloaded on 2026-11-05 and are cached under the gitignored source_cache/mpi_orange_roughy_orh7a_2024/ directory. Their original URLs and SHA-256 checksums are recorded in provenance/mpi_orh7a_2024_sources.csv.

- Fisheries New Zealand, [FAR 2024/58: Assessment of the Challenger Plateau orange roughy stock for 2024](https://fs.fish.govt.nz/Page.aspx?dk=25788&pk=113), especially Table 4 (printed p. 11), Tables 5–6 (printed pp. 12–13), and CASAL Appendix A (printed pp. 28–33).
- Fisheries New Zealand, [FAR 2024/26: Estimation of the abundance of orange roughy on the southwest Challenger Plateau](https://fs.fish.govt.nz/Doc/25743/FAR-2024-26-Estimation-of-the-abundance-of-orange%20roughy-on-the-southwest-Challenger%20Plateau.pdf.ashx), supporting the 2023 acoustic survey context.
- Fisheries New Zealand, [Fisheries Assessment Plenary May 2026, Volume 2](https://fs.fish.govt.nz/Page.aspx?dk=26242&pk=113), ORH 7A chapter, especially Table 6 (printed p. 1008).
- NIWA, [CASAL User Manual v2.30](https://webstatic.niwa.co.nz/library/NIWAtr135.pdf), definition of proportion_mortality.
