# ICES four-spot megrim in divisions 8.c and 9.a

## Stock and assessment

`ldb.27.8c9a` is the current four-spot megrim (*Lepidorhombus boscii*) unit in
ICES divisions 8.c and 9.a. No matching canonical stock was found before this
import. The current official assessment is the 2026 assessment for 2027 advice
(SAG key 26018). Its detailed WGBIE report chapter was added in November 2026;
the current report is version 2, and the 2026 Stock Annex revision 2 documents
the production model used for that cycle.

## Age-specific model evidence

The Stock Annex describes an a4a statistical catch-at-age assessment using
Fla4a 1.8.2 in R 4.1.2. Landings and discards-at-age in numbers are fitted
from 1986 onward. Landings age compositions use Spanish annual age-length keys
from 1990; the 1986–1989 compositions use a survey age-length key combined
with the annual key. WGBIE Table 6.4.2b provides Spanish-trawler discard
numbers-at-age (thousands) for 1986–2025, reported as age classes 0–7. This is
only one discard component, not a complete fleet catch-at-age array. The
Stock Annex describes model ages as 0–6+, so the terminal-age crosswalk is
unresolved. Blank source cells are retained as missing values.

WGBIE Table 6.4.2a also reports Spanish onboard-sampling discard-to-total-catch
ratios by weight and number for 27 years from 1994 to 2025. These supporting
catch summaries are retained separately from the age-specific discards and are
not treated as an additional fleet or likelihood observation. The table reports
CVs alongside the weight ratios through 2017; those CV percentages are divided
by 100 and stored as ratios. The eight blank 2018–2025 cells are retained as
missing values, not treated as zero or filled by inference.
The 2011 footnote marker and the table's revision notes are retained in the
input descriptions.

WGBIE Table 6.4.5 supplies annual aggregate landings, discards, and catch in
tonnes for 1986–2025. These totals do not replace the missing full fleet
catch-at-age likelihood data.

The assessment uses age-specific indices from the Spanish SpGFS-WIBTS-Q4 survey
(G2784) and the Portuguese crustacean survey (PT-CTS-UWTV-FU 28–29). The Annex
describes the Spanish survey as available from 1983, while its model input
table starts the fitted index in 1990. Its survey summary lists ages 1–6,
while the model input table lists ages 0–6. The Portuguese fitted index covers
1997–2018. The Spanish 2003 index and 2013 abundance value are excluded for
the reasons stated in WGBIE 2026; the Portuguese crustacean series ends in 2018
and its 2021–2022 values are excluded. The reports identify both fitted surveys
as fourth-quarter surveys, but do not provide exact fractional-year timing.
Numeric run-matched age-index matrices were not recovered.

Catch weights-at-age are also used as stock weights-at-age, but numeric
historical weights-at-age were not recovered. Natural mortality is fixed at
0.2 for all ages and years. The fixed female maturity-at-age vector is
0, 0.05, 0.32, 0.83, 0.98, and 1 for ages 0, 1, 2, 3, 4, and 5+.

ICES SAG key 26018 provides historical recruitment, SSB, total biomass,
landings, discards, and Fbar ages 2–4 through 2025. The SAG XML defines the
recruitment, SSB, and Fbar bounds as a **90% confidence interval**; these are
not 95% intervals and are not standard errors. Annual SSB and recruitment CVs
in WGBIE Table 6.4.5 are distinct from the SAG bounds. The 2026 SAG row is a
projection and is not included in the historical output series. WGBIE Table
6.4.6 separately reports 2026–2027 short-term forecast values. Numeric
historical N-at-age and F-at-age surfaces were not found.

## Screening decision

This is a **new, eligible source-curation candidate** with a partial canonical
import. Verified records include Spanish discard ratios and CVs,
Spanish-trawler discard numbers-at-age, aggregate catch totals, fixed M and
female maturity, and official historical
aggregate outputs with 90% intervals where reported. The full fleet
catch-at-age arrays, numerical weights-at-age, run-matched survey age-index
matrices, and exact survey timing remain unavailable. The record remains
partial; the imported values do not imply that the current assessment can be
reconstructed from the available data.

## Sources

| Evidence | Source |
|---|---|
| Current assessment and catch data | [WGBIE 2026 report, version 2, November 2026](https://doi.org/10.17895/ices.pub.32790321.v2) |
| Assessment model and biological assumptions | [ICES Stock Annex, revision 2, July 2026](https://doi.org/10.17895/ices.pub.23261030.v2) |
| Assessment year, current advice, and advice delay | [ICES advice record 7266](https://asd.ices.dk/viewAdvice/7266) |
| Historical output series and reported 90% interval endpoints | [ICES Standard Graphs source data, key 26018](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=26018) |

The WGBIE report, Stock Annex, SAG XML, and graph page used for the import are
cached under the gitignored `source_cache/ices_four_spot_megrim_8c9a_2026/`.
Their retrieval dates, revisions, byte sizes, URLs, and SHA-256 checksums are
recorded in `provenance/ices_four_spot_megrim_8c9a_2026/sources.csv`.
