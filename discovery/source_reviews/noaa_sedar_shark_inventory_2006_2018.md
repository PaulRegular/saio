# NOAA SEDAR shark inventory screen

**Review date:** 2026-11-02
**Inventory source:** NOAA Stock SMART snapshot retrieved 2026-10-28; latest assessment identifiers and review results are verified against the cached `stock_assessment_summary.rda`.
**Decision scope:** Screen observed age-specific inputs and accepted outputs for the latest assessment rows. Model-generated age states and age frequencies used only to define selectivity do not count as observed age-specific likelihood inputs.

## Findings

Twelve NOAA inventory rows were screened. None meets the age-input eligibility rule. Several assessments use age-structured population equations or report age-based outputs, but the source reports show that the age information was used to define life history or selectivity, while the fitted observations were aggregate catch, CPUE/effort and, in some cases, length compositions. Those model states do not supply observed catch-at-age or an age-specific survey likelihood.

The inventory includes three important boundary/reporting cases:

- **Atlantic sharpnose:** SEDAR 34 decided that Atlantic and Gulf sharpnose should be treated as one stock. The 2013 Stock SMART Atlantic and Gulf rows are each recorded as partial acceptance for status determinations only. They are crosswalked to one combined candidate unit and remain `ambiguous`; they are not counted as two accepted assessments.
- **Blacknose:** the broad 2007 Atlantic/Gulf row predates the separate Atlantic and Gulf SEDAR 21 assessments. It remains unlinked as a one-to-many historical boundary row. The 2011 Gulf blacknose run is marked rejected for uncertainty by Stock SMART; the Atlantic run is fully accepted.
- **Bonnethead:** SEDAR 34 assessed one combined Atlantic/Gulf unit for that cycle and recommended considering a future split. Stock SMART marks the 2013 assessment as remanded.

The large coastal shark complex assessment is rejected by Stock SMART, and the multi-species complex is not a single age-structured stock. The 2007 small coastal shark complex row is also distinct from the SEDAR 13 species-specific assessments and is not an age-specific population series.

## Candidate rows

| NOAA candidate | Latest run in Stock SMART | Assessment evidence | Screen result |
|---|---:|---|---|
| NOAA:10670 Atlantic sharpnose, Atlantic/Gulf | 2007 | SEDAR 13 accepted age-structured model; age-frequency information supports selectivity, not an observed catch-age likelihood. Later SEDAR 34 defines the combined stock. | Ineligible |
| NOAA:10674 dusky shark | 2016 | SEDAR 21 update uses an age-structured catch-free model because catch/discard estimates are too uncertain; relative effort/CPUE and life history drive inference. | Ineligible |
| NOAA:10676 sandbar shark | 2018 | SEDAR 54 accepted Stock Synthesis model fits catch, CPUE and length compositions. | Ineligible |
| NOAA:10677 blacknose, Atlantic/Gulf | 2007 | SEDAR 13 broad unit predates 2011 Atlantic and Gulf assessment units. Age frequencies inform selectivity. | Ambiguous historical boundary; ineligible |
| NOAA:10687 finetooth shark | 2007 | SEDAR 13 selected a Bayesian surplus-production model using total catch and aggregate CPUE. | Ineligible |
| NOAA:10692 bonnethead | 2013 | SEDAR 34 age-structured model; age-frequency/selectivity information is not a catch-age likelihood. Stock SMART result is remand. | Ineligible |
| NOAA:10967 large coastal shark complex | 2006 | Aggregate Bayesian surplus-production complex model; Stock SMART result is rejected for uncertainty. | Ineligible |
| NOAA:10969 small coastal shark complex | 2007 | Multi-species complex row; aggregate BSP model. Species-specific models are separate units. | Ineligible |
| NOAA:12130 blacknose, Atlantic | 2011 | SEDAR 21 accepted age-structured model; age frequencies inform selectivity, not the observation likelihood. | Ineligible |
| NOAA:12131 blacknose, Gulf | 2011 | SEDAR 21 age-structured model; same observation limitation. Stock SMART result is rejected for uncertainty. | Ineligible |
| NOAA:14141 Atlantic sharpnose, Atlantic region | 2013 | SEDAR 34 defines one combined stock; Stock SMART entry is status determinations only. | Ambiguous variant; ineligible |
| NOAA:14142 Atlantic sharpnose, Gulf region | 2013 | SEDAR 34 defines one combined stock; Stock SMART entry is status determinations only. | Ambiguous variant; ineligible |

## Source documentation

The official SEDAR reports were downloaded into the gitignored local cache at `source_cache/discovery_noaa_sedar_sharks_2026/`. `sources.csv` records source URLs, access date, file size and SHA-256 checksums. The Stock SMART inventory data are already cached in `source_cache/discovery_noaa_stocksmart/`.

- [SEDAR 11 assessment page and reports](https://sedarweb.org/assessments/sedar-11/)
- [SEDAR 13 assessment page and report](https://sedarweb.org/assessments/sedar-13/)
- [SEDAR 21 assessment page and reports](https://sedarweb.org/assessments/sedar-21/)
- [SEDAR 21 dusky update](https://sedarweb.org/documents/2016-update-sedar-21-hms-dusky-shark/)
- [SEDAR 34 assessment page and reports](https://sedarweb.org/assessments/sedar-34/)
- [SEDAR 54 sandbar assessment report](https://sedarweb.org/documents/sedar-54-final-assessment-report-hms-sandbar-shark/)
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/)

No canonical stock, assessment, input or output records were added or changed by this screen.
