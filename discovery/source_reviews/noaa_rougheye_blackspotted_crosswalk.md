# NOAA Rougheye/Blackspotted Rockfish Unit Crosswalk — 2026-11-12

## Current assessment units

NOAA's rougheye and blackspotted complex labels refer to separate regional
management units in the U.S. West Coast, Gulf of Alaska (GOA), and Bering
Sea/Aleutian Islands (BSAI). These are three regional assessment units, not one
North Pacific stock and not two species-level candidates per region.

| Current unit | Current NOAA row | Related inventory rows | Latest detailed official assessment located | Screening result |
|---|---|---|---|---|
| U.S. West Coast | `NOAA:14516` | `NOAA:10539` (2010 legacy label) | 2025 adopted assessment, data through 2024 | Eligible; the age-structured assessment pools both species. |
| Gulf of Alaska | `NOAA:11443` | `NOAA:10538` (2007 legacy label) | 2023 full age-structured assessment; 2024 SAFE is a harvest projection based on it | Eligible for source curation; exact survey timing remains unverified. |
| BSAI | `NOAA:11382` | `NOAA:15394` (EBS component); `NOAA:15395` (historical AI row) | 2024 SAFE update, retaining the 2022 full assessment | Eligible only for the Aleutian Islands age-structured component; EBS uses Tier 5 and has no age-specific population output. |

The historical West Coast label is linked to the current U.S. coastwide complex
because the 2013 formal assessment pooled rougheye and blackspotted data and
defined the outer U.S. West Coast area. It explicitly excludes Alaska and
Canadian waters. The current 2025 assessment preserves this regional unit.
NOAA:10539 is therefore retained as a historical inventory row under the same
candidate unit, not counted as another current stock.

The GOA is a distinct current unit. NOAA:10538 is the older single-species
inventory label for the same GOA area and is linked to the current combined
complex entry NOAA:11443. The 2023 report recommends age-structured Model
23.1b, using fishery age compositions and bottom-trawl survey age compositions;
it reports numbers-at-age, weight-at-age, maturity-at-age, recruitment,
spawning biomass and uncertainty. The longline survey provides an abundance
index and length data, but no longline age data. The 2024 SAFE chapter is a
harvest projection based on the 2023 fit, rather than a new full assessment.
The December 2025 GOA catch report states that the 2023 run remained the latest
full assessment and no assessment was conducted in 2025. A 2026 full-assessment
document was uploaded on November 9 for review at the November 18–20 Plan Team
meeting; as of November 12 it had not yet been reviewed or accepted.

The 2024 BSAI SAFE describes one regional complex with two model components:
an age-structured model for Aleutian Islands and a non-age-structured Tier 5
method for eastern Bering Sea. The 2024 update adds fishery age compositions
and AI survey observations to the retained AI model and reports AI
numbers-at-age, biomass, spawning biomass, recruitment and uncertainty. The
2022 full assessment is the underlying full model. NOAA:15394 is the EBS
component record, not an additional current stock and not an age-structured
candidate on its own. NOAA:15395 is the historical 2008 Aleutian Islands
inventory row. The official 2016 full assessment describes the age-structured
AI model history for 2008-2015; this row is retained as a historical component
under the current BSAI unit, not a separate case. The 2026 schedule lists a
BSAI update for later review; it was not final at the review date.

## Cross-source boundary checks

The DFO British Columbia rougheye/blackspotted records represent Canadian
waters and remain separate from all three NOAA U.S. units. The 2013 U.S. West
Coast assessment expressly excludes British Columbia and Alaska. GOA and BSAI
also remain separate from one another because NOAA publishes distinct
regional assessment units and models.

No corresponding canonical NOAA stock record was found for these three U.S.
units. The candidate register uses one stable `candidate_unit_id` per current
regional unit and links historical or component rows to it, preventing the
same regional unit from being counted twice. `eligibility` remains row-level:
historical and non-age-structured component rows are ineligible as stand-alone
cases, while the current GOA and West Coast rows and the AI component of BSAI
are eligible for source curation. This does not select them for the later
20-stock batch.

Exact fractional-year timing for the GOA and BSAI surveys remains unresolved. Eligibility here records evidence for recoverable age-disaggregated inputs and comparable age-specific outputs, not complete numerical source recovery.

## Sources and local cache

The locally cached PDFs, retrieval date, source URLs, file sizes and SHA-256
checksums are in the ignored manifest
`source_cache/discovery_noaa_rougheye_alaska_20261031/sources.csv`.

- [2013 U.S. West Coast rougheye/blackspotted assessment](https://www.pcouncil.org/documents/2014/01/the-status-of-rougheye-rockfish-sebastes-aleutianus-and-blackspotted-rockfish-s-melanostictus-as-a-complex-along-the-u-s-west-coast-in-2013-published-january-6-2014.pdf)
- [2025 U.S. West Coast assessment and model files](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [2023 GOA full assessment](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOArougheye.pdf)
- [2024 GOA harvest projection](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10291)
- [2024 BSAI assessment update](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIrougheye.pdf)
- [2016 full BSAI assessment](https://apps-afsc.fisheries.noaa.gov/REFM/Docs/2016/BSAIrougheye.pdf)
- [2026 North Pacific assessment priorities](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=D2+Groundfish+Stock+Assessment+Priorities.pdf&p=ff7dee7e-242d-42e7-85c7-2479d7eeac96.pdf)
