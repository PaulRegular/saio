# ICES ling in Division 5.a (2026)

**Review date:** 2026-10-30
**Official stock code:** `lin.27.5a`
**Scientific name:** *Molva molva*
**Assessment year:** 2026

## Stock identity and assessment

The 2026 ICES Standard Graphs and MFRI technical report identify the current
Icelandic ling assessment as `lin.27.5a`. This unit is not represented in the
canonical stocks table. The latest assessment is an age-based SAM assessment;
the 2026 report describes its fit and current advice cycle.

## Inputs and assumptions

The MFRI report provides commercial catch numbers-at-age in Figure 8 and
age-disaggregated indices for the spring survey, autumn survey, and gillnet
survey in Figure 15. Figure 10 reports catch weights-at-age, Figure 16 reports
stock weights-at-age from the spring survey, and Figure 17 reports
maturity-at-age. The 2023 ICES Stock Annex describes the model ages as 2–12+ and
sets natural mortality to fixed `M = 0.15` because direct information is
unavailable.

These input matrices are primarily figure-based and require digitization plus
checks of units and age/year coverage. The Stock Annex notes that age reading
from catches stopped in 1998 and resumed in 2013, so missing years must be
preserved rather than filled. Survey timing is described as March for the spring
survey, October for the autumn survey, and early April for the gillnet survey;
converting these months to fractional-year timing would be an approximation.

## Official outputs

ICES 2026 source data report age-2 recruitment in thousands, SSB and total
biomass in tonnes, and fishing mortality for ages 8–11 with 2.5% and 97.5%
limits. The public series do not provide annual abundance-at-age or
fishing-mortality-at-age surfaces. The MFRI report recommends 7,657 tonnes for
the 2026/2027 fishing year.

## Screening decision

This is a distinct, new candidate and is **eligible for source curation**.
Public sources document age-specific catches and survey indices, relevant
weights and maturity, fixed M, survey timing, and comparable official outputs.
It is not ready for numerical import: input values are mostly figure-based and
catch age sampling has a documented gap. No canonical assessment, input, or
output rows have been added has been attempted.

Cached sources are gitignored. URLs, revision descriptions, retrieval date,
sizes, and SHA-256 checksums are in
`source_cache/discovery_ices_ling_5a_2026/sources.csv`. The annex text file in
that folder is a local text extraction used to verify its M assumption and
model settings.

## Sources

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/6_lin_2026_1_techreport_en.html)
- [ICES 2026 Standard Graphs](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22475)
- [ICES 2026 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22475)
- [ICES 2023 Stock Annex](https://doi.org/10.17895/ices.pub.23599644.v1)
