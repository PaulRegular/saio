# ICES four-spot megrim in divisions 8.c and 9.a

## Stock and assessment

`ldb.27.8c9a` is the current four-spot megrim (*Lepidorhombus boscii*) unit in
southern Bay of Biscay and Atlantic Iberian waters East. No matching canonical
stock was found. The latest official advice is the 2026 assessment (SAG key
26018), published after the spring working-group report had postponed advice
for this stock until autumn. The 2026 Stock Annex, revised in May and published
in July, documents the production model used for that cycle.

## Age-specific model evidence

The Stock Annex describes an a4a statistical catch-at-age assessment. Landings
and discards-at-age in numbers are fitted for ages 0–6+ from 1986 onward.
Landings age compositions use annual Spanish age-length keys from 1990; the
1986–1989 compositions use a survey age-length key combined with the annual
key. The annual numeric catch-at-age arrays are not reproduced in the annex.

The assessment uses age-specific indices from the Spanish SpGFS-WIBTS-Q4 survey
(G2784) and the Portuguese crustacean survey (PT-CTS-UWTV-FU 28–29). The annex
describes the Spanish survey as available from 1983, while its model input table
starts the fitted index in 1990. Its survey summary lists ages 1-6, while the
model input table lists ages 0-6. The Portuguese fitted index covers 1997–2018.
Both surveys are fourth-quarter surveys, but the exact fractional-year timing
is not stated. The numeric run-matched age-index matrices were not recovered.

Catch weights-at-age are also used as stock weights-at-age. The model uses
constant female maturity-at-age of 0, 0.05, 0.32, 0.83, 0.98, and 1 for ages
0, 1, 2, 3, 4, and 5+, respectively, and fixed natural mortality M = 0.2 for
all ages and years.

The current SAG source table (key 26018) reports age-0 recruitment, SSB, total
biomass, landings, discards, and F for ages 2–4. Historical estimates extend
through 2025; the 2026 row is a projection. Recruitment, SSB, and F have
reported low/high bounds. Numeric historical N-at-age and F-at-age surfaces
were not found.

## Screening decision

This is a **new, eligible source-curation candidate**. The current Stock Annex
documents the age-specific catch and survey inputs, weights, maturity, and M;
the current assessment graph supplies comparable official outputs. The missing
run-matched numerical catch and survey matrices and exact survey timing remain
source follow-ups. Eligibility indicates that the assessment merits source
curation; it does not mean every numerical matrix has already been recovered.
No canonical database rows or tinyAM translation were added.

## Sources

| Evidence | Source |
|---|---|
| Current assessment and age-specific inputs | [ICES Stock Annex, revision 2, July 2026](https://doi.org/10.17895/ices.pub.23261030.v2) |
| Assessment year, current advice, and advice delay | [ICES advice record 7266](https://asd.ices.dk/viewAdvice/7266) |
| Historical output series and reported bounds | [ICES Standard Graphs source data, key 26018](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=26018) |
| Regional assessment status and age-structured model context | [ICES WGBIE 2026 report](https://doi.org/10.17895/ices.pub.32790321.v1) |

The current Stock Annex, advice page, and SAG source page are cached in the
gitignored `source_cache/discovery_ices_four_spot_megrim_8c9a_2026/`;
its `sources.csv` records retrieval dates, source revisions, byte sizes, and
SHA-256 checksums. The WGBIE report and related southern-megrim materials are
cached under `source_cache/discovery_ices_wgbie_2026/`.
