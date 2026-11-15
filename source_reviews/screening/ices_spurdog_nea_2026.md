# ICES Northeast Atlantic spurdog (2026)

**Review date:** 2026-10-31  
**Official stock code:** `dgs.27.nea`  
**Scientific name:** *Squalus acanthias*  
**Assessment year:** 2026  
**ICES assessment key:** 25850

## Stock identity and latest assessment

ICES SID, the 2026 advice records, and the 2026 SAG output identify the same
current unit: spurdog in subareas 1–10, 12, and 14. This is a Northeast Atlantic
unit and is not the NOAA/DFO Northwest Atlantic spiny dogfish unit, despite the
shared scientific name. No matching `dgs.27.nea` stock or assessment is in the
canonical database.

The 2026 SAG record is the latest official assessment output located. It uses
assessment year 2026, reports a terminal historical year of 2025, and includes
2026 forecast values. The 2025 WGEF report says the assessment was not updated
during that year's meeting and that the next advice was due in 2026. I did not
locate a detailed WGEF report or native input files for the 2026 run by this
review date. The 2024 advice and WGEF report are therefore the latest detailed
public descriptions of the model inputs located; they should not be assumed to
prove that every input value remained unchanged in 2026.

## Input evidence

| Input | Latest detailed description located | Age-specific evidence |
|---|---|---|
| Catches | 2024 assessment basis lists landings; the WGEF report also describes discard estimates. The 2026 SAG reports catches, landings, and discards in tonnes. | The 2024 input list does not identify catch numbers-at-age or fishery age compositions. The 2026 input arrays were not located. |
| Survey | Three GAM-based delta-lognormal biomass indices combined by quarter: Q1, Q3, and Q4. | The 2024 basis lists length composition by sex associated with these indices, not survey age compositions or an index-at-age. |
| Fishery compositions | Length compositions for bottom-trawl fleets and for gillnet/trammel-net fleets; fleet groupings and data begin in different periods. | These are length compositions, not age compositions. |
| Biology | Fecundity-at-length is listed. The assessment is described as age–length and sex structured. | The advice does not list weight-at-age or maturity-at-age inputs. Exact 2026 biological arrays were not located. |
| Mortality and timing | The advice's input summary does not specify the natural-mortality formulation or survey timing as fractions of a year. Survey indices are grouped by Q1, Q3, and Q4. | Exact 2026 mortality assumptions and within-quarter observation timing remain unresolved. |

The 2026 model label `Age-length and sex-structured model` describes the model
structure; it does not establish that its observations are age-disaggregated. The latest detailed input list instead identifies catch totals, survey biomass
indices, and length compositions.

## Reported outputs

The 2026 SAG output reports historical values through 2025, with the terminal
historical year explicitly set to 2025, and includes forecast values beginning
in 2026. It reports:

- SSB and total biomass in tonnes;
- recruitment at age 0, described as pups, with the SAG metadata in thousands
  and the chart label in millions;
- a relative harvest-rate measure for ages 5–30;
- catches, landings, and discards in tonnes;
- low and high values for biomass and recruitment, whose interval definition
  was not established from the reviewed output metadata.

The current published summary does not provide N-at-age, F-at-age, or M-at-age
surfaces. The ages 5–30 harvest rate is an aggregate age-range indicator, not
F-at-age. The 2026 advice recommends catches no greater than 20,124 tonnes in
2027 and 20,478 tonnes in 2028.

## Screening decision

This is a **new, screened candidate with unresolved age-input eligibility**.
The latest official output and stock identity are verified, but current-run
input arrays and a detailed 2026 assessment report were not located. The latest
detailed source describes an age–length model with aggregate catches, biomass
indices, and length compositions, but it does not establish age-disaggregated
observation inputs. Keep the candidate unresolved until the 2026 detailed
production inputs or native files are found; do not mark it eligible based on
the age–length model label alone.

The reviewed official sources and file checksums are
listed in the gitignored cache manifest at
`source_cache/discovery_ices_spurdog_nea_2026/sources.csv`. It points to the
already cached WGEF 2024 and 2025 reports rather than duplicating those large
files. The 2024 advice text file is a pypdf text extraction of the cached
official advice PDF; the original PDF is retained beside it.

## Sources

- [ICES SID, 2026](https://sid.ices.dk/services/year/2026)
- [ICES advice record 7197, assessment year 2026](https://asd.ices.dk/viewAdvice/7197)
- [ICES advice record 7198, assessment year 2026](https://asd.ices.dk/viewAdvice/7198)
- [ICES Standard Graphs source data, key 25850](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25850)
- [ICES SAG XML, key 25850](https://sag.ices.dk/SAG_API/StockXmlDownload/25850)
- [ICES advice 2024, official stock sheet](https://ices-library.figshare.com/articles/report/Spurdog_Squalus_acanthias_in_Subareas_1-10_12_and_14_the_Northeast_Atlantic_and_adjacent_waters_/25019237)
- [ICES WGEF report 2024](https://ices-library.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/26935504)
- [ICES WGEF report 2025](https://ices-library.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/30137623)
