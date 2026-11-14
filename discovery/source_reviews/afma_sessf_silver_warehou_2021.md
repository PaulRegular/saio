# AFMA SESSF silver warehou, 2021 assessment

## Stock unit and assessment selected

AFMA manages silver warehou (*Seriolella punctata*) as one stock in the Southern and Eastern Scalefish and Shark Fishery (SESSF). The 2021 assessment models one population with separate east and west trawl fleets. No matching canonical SAIO stock was found.

The detailed report covers data through 2020. AFMA's 2026 species summary states that the later 2024 Tier 1 assessment was not accepted and that the 2026–27 TAC continues to use fixed-catch projections from the 2021 assessment. The 2021 report is therefore selected as the current detailed assessment used for advice; the rejected 2024 run is not substituted for it.

## Sources

- [2020–21 SESSF assessment report, Part 1](https://www.afma.gov.au/sites/default/files/2023-02/Stock%20Assessments%20for%20SESSF%202020%E2%80%9321%20-%20Part%201.pdf), Silver Warehou chapter 13, report pages 623–681. Cached locally as `source_cache/afma_silver_warehou_2021/SESSF_2020-21_Part_1.pdf` (SHA-256 `5F549D0B0E9B072CC88E5F042D6626075ABB2319E4792C8020DCCC0E3C0A3BCB`).
- [SESSF Species Summaries 2026](https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf), Silver Warehou section. Cached locally as `source_cache/afma_silver_warehou_2021/SESSF_Species_Summaries_2026.pdf` (SHA-256 `17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3`).
- AFMA [SESSF fishery page](https://www.afma.gov.au/fisheries/southern-and-eastern-scalefish-and-shark-fishery), current management-area and TAC context.

## Reported data and model structure

The 2021 model is a Stock Synthesis age- and length-structured assessment, version 3.30.17. It uses a single stock with separate east and west trawl fleets. Catch is in calendar years; assessment data end in 2020. The report's 2021 catch row repeats the 2020 catch for projection purposes and is not an additional fitted-year observation.

Table 13.2 reports annual total catch by east and west fleet, with SESSF and state components shown separately. Table 13.3 gives 1992–2020 discard proportions and sample sizes; its `used` flag identifies observations omitted for small sample size or near-zero discard proportion. Tables 13.4–13.5 give retained and discarded length-sample counts by fleet and year. Table 13.6 reports conditional age-at-length sample counts by east/west fleet for 1988 and 1993–2020. Table 13.7 gives age-reading-error SDs for ages 0–23.

The model uses aggregate standardized CPUE for the east and west fleets over 1986–2020. The report shows those series as figures rather than numerical annual tables. The initially assigned CPUE CVs are 0.174 east and 0.178 west, then model tuning re-estimates the observation errors. The observed conditional age-at-length cells and numerical length compositions are not tabulated.

Table 13.1 fixes natural mortality at 0.30 per year, stock-recruit steepness at 0.75 and the age plus group at 23 years. Maturity is a fixed logistic function of length with 50% maturity at 37 cm. The report gives length-weight coefficients and estimates growth parameters in the model; it does not provide a numeric weight-at-age surface.

Tables 13.8 and 13.12 report fitted parameters, likelihood, unfished SSB, projected 2022 SSB and the SSB-to-unfished ratio. The base case estimates total male-plus-female SSB0 at 18,806 t, SSB2022 at 5,374 t and SSB2022/SSB0 at 0.29. Table 13.10 reports the low-recruitment harvest-control-rule projections and Table 13.11 gives 2022–2040 projections under alternative fixed catches. These table values are source point estimates; the report does not provide uncertainty intervals for these summary rows.

## Source gaps and curation status

## Imported source values

The canonical record preserves the Table 13.2 east and west assessment catch histories for 1980-2020 in tonnes, excluding the repeated 2021 projection value. It also preserves both fleet discard proportions, their reported sample counts and used flags from Table 13.3; fleet-year conditional-age-at-length sample counts from Table 13.6; and the fishery-wide age-reading-error SD vector for ages 0-23 from Table 13.7. These sample counts are not composition vectors or effective likelihood sample sizes.

The reported fitted parameters in Table 13.8 are stored on their source scale without back-transforming the catchability values. Tables 13.10-13.12 provide the imported low-recruitment stock-status and catch projections, plus the reported unfished and projected 2022 spawning biomass. These are point estimates without uncertainty intervals. The Table 13.10 and 13.11 status values are kept distinct because the tables report them at different precision and do not agree exactly for every overlapping year.

The report's numerical CPUE series, retained/discard length-frequency cells, and conditional age-at-length cells remain unavailable in the reviewed sources. The sample-count tables do not replace those observations. The report also presents annual population estimates and retrospective trajectories as figures rather than numerical age-specific arrays; no values were digitized. No native Stock Synthesis input or output files were located in the reviewed public sources. The source search does not establish whether such files are available elsewhere, so this remains a gap to pursue.

Age-input eligibility remains unresolved. The official model uses age-at-length observations, but the published assessment does not give the actual observed composition cells needed to reconstruct them. The source record should preserve those sample counts and model outputs without treating the assessment's age structure as proof that the missing age inputs are available. No tinyAM fit is selected at this stage.
