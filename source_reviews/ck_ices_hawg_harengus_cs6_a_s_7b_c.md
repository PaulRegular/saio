# Herring in divisions 6.a South and 7.b–c

## Stock and assessment selection

The Charbonneau–Keith record `ICES-HAWG_harengus_CS6.a (S), 7b-c` is the
southern stock `her.27.6aS7bc`. It was assessed jointly with 6.a North from
2015 to 2021; since the 2022 benchmark the genetically split acoustic survey
has allowed separate assessments. Its data must not be copied into the
separate northern stock or the historical combined-stock assessment.

The HAWG 2026 report provides the latest detailed source found, using data
through 2025. The current method is an ICES category 3 constant harvest-rate
rule using the genetically split Malin Shelf Herring Acoustic Survey (MSHAS)
biomass index. ICES published 2026 ACOM advice based on this assessment, but
its Advice and Scenarios Database record 4061 is currently marked **Invalid**;
the reason for that status and any management application are unresolved.
The 2025 advice, SAG key 19342 and advice record 3843, is marked **Active**.
These statuses must remain separate from the source values.

## Recovered data and assessment method

The 2025 and 2026 HAWG reports include catch-at-age in thousands of fish,
catch weights and spawning stock weights in kg/fish, and MSHAS survey
numbers-at-age, weights, maturity, biomass and a reported survey CV. The
source does not explicitly identify the precise target of the CV. The source
biological and catch-at-age tables provide useful context but are not a
separate age-specific likelihood in the survey-index harvest-rate rule. The
report also includes exploratory age-based assessments; their fitted states
are not the published chr assessment outputs.

The 2026 SAG XML reports a 2025 survey biomass index of 7,774 tonnes, catch
of 1,378 tonnes and catch/index of approximately 0.1773. The 2026 published
advice uses a harvest-rate proxy of 0.13, index trigger 51,390 tonnes and a
biomass safeguard of 0.151. The published 2025 advice instead uses proxy 0.26,
2024 index 54,657 tonnes and a stability clause. Do not mix these separate
assessment versions or interpret the index as a fitted absolute SSB state.
HAWG 2026 section 5.3.1 gives the trigger as 51,340 tonnes, while the published
advice gives 51,390 tonnes. HAWG Table 5.6.2.6 prints a biomass safeguard of 1,
which cannot reproduce its stated 153-tonne advice; the published advice gives
0.151. The canonical rule assumptions use the published advice values and retain
these discrepancies for review rather than treating them as rounding.

The 2026 HAWG report Table 5.2.1.1 wraps the final digit of the 1991 age-5
catch cell onto the next line: visually it reads `10044` with a `4` below in
the same cell. Search-index text for the earlier ICES 1994 assessment report
shows `100444` alongside the same neighbouring values; the full historical PDF
could not be downloaded locally because its host did not resolve. Record any
rejoining of the printed digits explicitly and check the result against the
source image; do not silently shift the remaining age columns.

Source extraction must also preserve the blank survey numbers and mean weights at age 1 in 2014–2017,
the blank 2015 age-9 cells, and missing 2025 age-9 biology. The 2026 report
labels its genetically split survey rows `her-014`, whereas the 2025 report uses
`her-irlw`; the tables' titles identify the southern stock in both cases. Check
age labels and source units against the rendered pages rather than treating the
row label as an independently verified stock code.

## Canonical records

`scripts/database/162_import_ices_herring_6a_s_7bc.R` imports separate 2025
and 2026 records, with 1,903 and 1,960 input rows and 22 and 24 indicator
outputs, respectively. Inputs include the reported catch-at-age series,
catch and spawning-time weights, genetically split survey numbers-at-age,
survey weight, maturity, reported survey CV, external SMS-derived M,
historical length indicators, and aggregate catch and index.
The CV is retained as source context without assuming its precise target or
using it as a likelihood weight.
The printed 1991 age-5 cell is joined as 100,444 thousand fish and marked as
a source reconstruction. Missing survey ages and biological cells are omitted;
no exact survey sampling fraction is inferred from June–July. Table 5.3.2.1
also reports a dedicated winter acoustic survey as additional context; it is
not an input to the chr rule and is not imported as a second fitted index.

The 2026 selected record and the earlier 2025 record are both flagged as used
for published ACOM advice. That flag does not establish current validity of
the 2026 advice record or management application. All completeness statuses
remain partial: the full source catch-length-frequency inputs, exact native
rule files and underlying survey processing have not been recovered. Neither
assessment provides fitted population N/F/M-at-age under the published rule.

The 2025 and 2026 advice PDFs and SAG XML, 2026 HAWG report, and the relevant
2025 report pages are cached locally with URLs and checksums. The 2025 full
HAWG PDF is shared with the sandeel cache and identified in the manifest.

## Translation status

The current rule has no estimated population N/F/M-at-age or recruitment
surface. A tinyAM age-structured model would be a new assessment rather than a
faithful translation of this rule, and there are no official population states
for the requested comparison. No tinyAM fit or comparison dashboard is
currently supported.

## Sources

- [HAWG 2026 report](https://doi.org/10.17895/ices.pub.31424315), section 5 and Tables 5.2.1.1, 5.3.1.1–3 and 5.4.1.1–2.
- [HAWG 2025 report](https://doi.org/10.17895/ices.pub.28389008.v5), section 5.
- [ICES 2025 advice](https://doi.org/10.17895/ices.advice.27202635) and [SAG key 19342](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19342).
- [ICES 2026 advice](https://doi.org/10.17895/ices.advice.32133673), [SAG key 21289](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21289), and [ASD record 4061](https://asd.ices.dk/viewAdvice/4061), currently marked Invalid.
- [ICES 1994 working-group report](https://imr.brage.unit.no/imr-xmlui/bitstream/handle/11250/105230/CM_1994_Assess_13.pdf?isAllowed=y&sequence=1), search-index cross-check only; full local download failed.
