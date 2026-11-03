# North Sea, Skagerrak and Kattegat sprat (ICES spr.27.3a4)

Review date: 2026-10-30

## Unit and current assessment

The ICES unit is European sprat (*Sprattus sprattus*) in Division 3.a and
Subarea 4, covering the Skagerrak, Kattegat and North Sea. It is distinct from
Baltic sprat already represented in the database. The current assessment is
ICES assessment year 2026, Category 1. Advice applies from 1 July 2026 through
30 June 2027.

## Evidence for age-disaggregated inputs

The public 2026 TAF processing script specifies SMS data for 1980-2025, model
ages 0-3, and seasonal catch numbers-at-age. It also constructs three
age-specific survey series: IBTS_Q1 ages 0-3 in 1982-2025, IBTS_Q3 ages 1-3 in
1992-2025, and HERAS ages 1-3 in 2006-2025. The script passes a biological
matrix containing natural mortality, maturity and weight fields to the model
setup, and declares survey timing and seasons.

The published TAF repository snapshot contains the processing script and a
DATA.bib entry marked public with source type folder, but its repository tree
does not contain the referenced input folder or numeric catch, survey or
biological files. The script verifies the input structure, not observation
values, units or coverage. Direct unauthenticated requests to the TAF
repository proxy returned HTTP 401. No values were reconstructed from code or
other sources.

## Official outputs and comparison limits

The current ICES Stock Assessment Graphs source table reports age-0
recruitment in thousands, SSB in tonnes, landings, and F for ages 1-2 through
2025, with published uncertainty bounds for recruitment, SSB and F. The HAWG
2026 report summarizes 2025 SSB as 199,809 tonnes and F1-2 as 1.51. The
reviewed graph table does not report N-at-age or a full F-at-age surface.

These aggregate outputs provide useful comparison targets if the numeric
assessment inputs can be recovered. They are not enough to create canonical
input records or claim a completed age-disaggregated comparison case.

## Screening decision

This is a distinct new unit, but eligibility remains **unresolved**. The
assessment is demonstrably age-structured and its published processing code
specifies catch-at-age and three age-specific survey series. The numeric files
needed to verify the actual observations and biological surfaces are not in
the reviewed public repository snapshot. A Category 1 or SMS model label is
not a substitute for those values. No canonical stock, assessment, input or
output records were added, and no tinyAM translation was attempted.

## Sources

- ICES, [2026 advice for sprat in Division 3.a and Subarea 4](https://asd.ices.dk/viewAdvice/4079).
- ICES, [2026 Stock Assessment Graphs](https://standardgraphs.ices.dk/ViewCharts.aspx?key=21311) and [source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21311).
- ICES, [2026 HAWG report](https://backend.orbit.dtu.dk/ws/portalfiles/portal/440308463/HAWG_2026_-_Full_Report.pdf).
- The public [2026 TAF assessment repository](https://github.com/ices-advice/2026_spr.27.3a4/tree/51bd58e56d3d9623626b6b0a0a47028f095cc0e1/2026_spr.27.3a4_assessment).
- The ignored source cache records URLs, retrieval dates, revisions, byte sizes and SHA-256 checksums. The HAWG report is shared with the other sprat cache to avoid a duplicate large file.