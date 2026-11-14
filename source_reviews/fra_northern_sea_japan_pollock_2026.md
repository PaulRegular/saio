# FRA Northern Sea of Japan walleye pollock (FY2026)

## Assessment identity

The FRA FY2026 Hokkaido-block assessment meeting was held on 2026-09-05. The detailed report is FRA-SA2026-SC01-01 and estimates the stock through fishing year 2025. FRA currently labels the detailed report preliminary while formatting is finalized; check for a replacement before future reuse.

The assessed unit is the Northern Sea of Japan stock, distributed from the Noto Peninsula to the west coast of Sakhalin and centered in recent years along the Hokkaido coast. No separate FRA stock-unit code was identified. This unit is distinct from U.S.-managed Alaska walleye pollock stocks.

## Model and inputs

The assessment is a tuned Pope cohort analysis for fishing years 1980-2025. Fishing years run April-March and age is assigned on April 1. The modeled population is ages 2-10+, with age 10 as the plus group. Table 6 reports age-specific catch numbers, catch biomass, F, abundance, biomass and spawning biomass.

Catch numbers-at-age are reported in thousands of fish. The published series combines the modeled catch and does not support a finer fleet split. The report explains that Korean catch age composition is assigned the Japanese offshore-trawl age composition where direct age information is unavailable; North Honshu catch age composition is extended using the West Japan Sea composition. Table 6 catch biomass through fishing year 2007 is calculated from catch numbers and stock weights, so those values are not observed catch biomass.

Natural mortality is fixed at 0.30 per year at age 2 and 0.25 per year at ages 3+. Age-0 and age-1 April abundance are derived from age-2 abundance assuming zero catch and M equal to age-2 M; ages 0-1 are not modeled VPA ages. Terminal-year F uses ridge VPA with lambda 0.9887. F at age 10+ is set equal to age-9 F.

Three acoustic-survey-derived index series are reported:

- October spawning-stock distribution survey: biomass in tonnes for 1998-2025. The 2002 and 2012 observations are published but excluded from VPA tuning because survey coverage was insufficient. October is represented at 0.5 of the April-March year; the report does not give an exact survey date.
- New-recruitment larval/juvenile distribution survey: age-0 abundance by cohort for 2005-2026, in units of 100 million fish. The 2005 value is a reference and the 2026 value is marked as a rapid survey result, beyond the assessment's estimate terminal year.
- Juvenile distribution survey around Musashi Bank: age-0, age-1 and age-2 abundance by cohort for 2005-2024, in millions of fish. Only numeric cells are stored. Dashes remain missing. The report identifies the age-1 series from 2007 onward as a useful recruitment indicator; exact sampling dates are not reported.

## Biology

Supplementary Table 2-1 reports stock weight-at-age in g/fish for ages 2-10+, with separate schedules for fishing year 2005 and earlier and 2006 onward. Earlier weights were calculated from March-May fish measurements during 1995-2002; later weights use the growth model from Hoshino et al. (2021).

Supplementary Table 2-2 reports female maturity-at-age used for spawning biomass. Earlier values were calculated from November-January fishery measurements during 2007-2013; later values use Hoshino et al. (2021). Supplementary Table 2-3 reports combined-sex maturity used for the October spawning-stock index. Source percentages are stored as proportions.

## Outputs and completeness

Table 6 provides 1980-2025 age-specific catch biomass, F, N, biomass and SSB, plus totals for N, biomass and SSB. Because the age-specific SSB values and total are separately rounded, summing the age rows can differ from the reported total by up to 2 tonnes. Recruitment is represented by abundance at the model recruitment age, 2. The report does not tabulate numerical uncertainty intervals for the annual age-specific estimates.

The source report and its tables support all material catch, index, biology and fixed-M inputs. The likelihood and observation-error details for the index series are not fully specified in the report. Statuses are therefore: inputs complete; assumptions partial; outputs partial because uncertainty is not numerically tabulated.

## Source and validation

The detailed report is hosted on the [FRA FY2026 Hokkaido-block assessment page](https://www.fra.go.jp/shigen/fisheries_resources/meeting/stock_assessment_meeting/2026/sa2026-sc01.html). Its PDF is cached locally under the ignored source cache; the retrieval URL, date and SHA-256 are recorded in provenance/fra_northern_sea_japan_pollock_2026/manifest.csv.

The importer verifies the cached checksum, table dimensions, year and age coverage, key survey values, and retained missing cells before writing. A source test checks representative values and units, plus-group handling, output completeness, candidate status and provenance.
