# Western Atlantic bluefin tuna, ICCAT 2021

## Identity and latest assessment

NOAA Stock SMART 10165 and DFO's Western Atlantic bluefin entry refer to one
transboundary stock assessed by ICCAT, west of 45° longitude. No matching
canonical stock record was found. The ICCAT assessment calendar lists the West
Atlantic assessment as 2021/2027 and names Stock Synthesis 3.30.14 as the model
used for advice. The 2024 SCRS report continues to report status from the 2021
assessment.

The accepted 2021 run spans 1950–2020 and has no spatial subdivision within the
Western Atlantic assessment area. It is a single-sex model with ages 0–35+ and
14 catch fleets. The DFO and NOAA inventory rows are linked under one internal
candidate unit; they are not separate assessments or stocks.

## Inputs and outputs

The advice model uses annual fleet catches in metric tonnes over 1950–2020,
assumed known with a 0.05 standard error, 12 aggregate abundance indices, and
length compositions. It also uses conditional age-at-length observations from
otolith age–length pairs collected by five laboratories. The report counts
9,307 pairs available from 1973–2018 and 6,552 retained after screening under
the strict-update protocol. Length compositions use 5-cm bins from 30 to
350 cm. Composition likelihood weights were adjusted; index weights were not
changed in the 2021 update. Each abundance index has within-year timing
adjustments, but the report does not give the complete numeric timing vector.

Catch-at-age is not a fitted likelihood input in the advice model. A Japan
longline catch-at-age series, obtained by cohort slicing, is included only as a
diagnostic comparison with the model's predicted catch-at-age. The report's
full numerical catch-at-age, N-at-age and F-at-age tables are from the separate
VPA analysis. The assessment group found that VPA had poor diagnostics,
including severe retrospective bias, and did not recommend it for stock-status
determination or projections. Those tables must not be substituted for advice
model outputs.

The model estimates growth using a Richards curve, derives weight from the
length–weight relationship `1.52e-5 * length^3.05305`, and uses alternative
early- and late-spawning maturity schedules. SSB is the mass of mature fish.
Natural mortality follows an age-specific Lorenzen curve scaled to 0.1 per year
at age 20, with a reported schedule through age 35+.

The advice report provides SSB, recruitment, total biomass and fishing-mortality
trajectories through 2020 as figures, with terminal F-based status and
uncertainty in tables. It plots F-at-age for recent years, but numeric annual
N-at-age and F-at-age arrays from the Stock Synthesis advice run were not found
in the reviewed documents. The latest summary continues to use the 2021
assessment; no later Western Atlantic assessment was listed as of this review.

## Screening decision

The latest advice assessment is genuinely age-structured and includes
conditional age-at-length data, but it does not fit catch-at-age observations;
its only catch-at-age input is diagnostic. The publicly available reports do
not include run-matched numeric composition arrays or the complete electronic
input files, nor an age-specific survey-index likelihood. Some source data may
support a reconstruction from catch totals, length compositions and
age-at-length samples, but that reconstruction and its coverage have not been
verified. Eligibility therefore remains unresolved. Do not import the VPA's
age-specific tables as Stock Synthesis outputs.

No canonical records or numerical assessment values were added.

## Sources

- [ICCAT assessment calendar](https://iccat.int/en/assess.html)
- [2021 Western Bluefin Stock Assessment Meeting report](https://www.iccat.int/Documents/Meetings/Docs/2021/REPORTS/2021_WBFT_SA_ENG.pdf)
- [Stock Synthesis Part I: model specification and input data](https://www.iccat.int/Documents/CVSP/CV078_2021/n_3/CV078030734.pdf)
- [Stock Synthesis Part II: diagnostics, results and projection](https://www.iccat.int/Documents/CVSP/CV078_2021/n_3/CV078030756.pdf)
- [VPA paper, not selected for advice](https://www.iccat.int/Documents/CVSP/CV078_2021/n_3/CV078030706.pdf)
- [2024 ICCAT SCRS report](https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_SCRS_ENG.pdf)
- [DFO Sustainability Survey](https://www.dfo-mpo.gc.ca/reports-rapports/regs/sff-cpd/survey-sondage/index-en.html)

The reviewed PDFs are cached locally in the gitignored
`source_cache/discovery_iccat_western_bluefin_2021/`; `sources.csv` records
the source URLs, retrieval date and SHA-256 checksums.
