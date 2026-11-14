# NOAA Pacific Coast Rex Sole

## Stock and assessment

NOAA Stock SMART identifies Pacific Coast rex sole (*Glyptocephalus zachirus*) as entity 10059, separate from Gulf of Alaska rex sole (entities 10058, 15410 and 15411). The 2023 Pacific Fishery Management Council assessment is the latest detailed production assessment located for the U.S. West Coast unit; NOAA's species summary continues to identify the Pacific Coast assessment as 2023. The selected base model is Stock Synthesis 3.30.21, with data through 2022. The model archive includes forecast output through 2034. The canonical database contains this stock and its 2023 assessment, matched to NOAA candidate 10059. The candidate register contains separate Gulf of Alaska rex sole candidates, but no DFO or ICES match for the Pacific Coast unit.

The official report describes the model as using fishery landings and discards, three aggregate abundance-index series, fishery and survey length compositions, and WCGBTS conditional age-at-length data. The archive identifies the index fleets only as `SURVEY1` to `SURVEY3`; the input data do not support assigning each generic fleet name to a specific survey beyond the WCGBTS age-at-length association with fleet 5.

## Inputs and assumptions

The native data file contains 107 annual fishery catch-biomass observations for two fleets from 1916–2022, 20 discard-fraction observations from 2002–2021, and 28 aggregate biomass-index observations from 1980–2022. Catch and index values are retained on their source scales. Stock Synthesis marks the catch units as biomass and the index units as biomass-scale indices, but the index files do not specify a physical unit suitable for conversion. The native `catch_se`, index `se_log`, and discard error fields are preserved separately. The discard error code is a Student's t likelihood with 30 degrees of freedom; its source error value is retained as a CV. The data provide no exact fractional-year survey timing: month/season value 1 is the model's annual-season code, not a verified calendar month.

The assessment contains 58 fishery and survey length-composition records. Its 165 age-composition records include 152 active conditional age-at-length rows for WCGBTS fleet 5 (82 female and 70 male rows, 2007–2019) and 13 full-length marginal age-composition rows with a negative fleet code. Those negative-fleet rows are retained as source data but excluded from the likelihood. Neither group is an age-specific abundance index. The fishery data contain no observed catch-at-age series. Age-specific catch or survey indices would therefore require additional reconstruction and are not represented as native inputs here.

Natural mortality is fixed at 0.186207 yr⁻¹ for both sexes in the selected control file (one constant-M parameter per sex, phase −2); it is not estimated in the base model. The control file specifies estimated sex-specific von Bertalanffy growth, fixed weight-at-length relationships, length-logistic maturity, and an egg-production relationship based on length. Weight-at-age and the time-varying age surfaces in `Report.sso` are model-derived quantities, not independent biological input observations.

## Outputs and uncertainty

The native run reports historical and forecast numbers-at-age, biomass-at-age, natural mortality-at-age, fishing mortality-at-age, dead catch-at-age, and beginning-of-year weight-at-age. These are model outputs, not observed age-specific input series. The model's spawning quantity is egg production (`SpawnBio`), not spawning biomass in tonnes. Annual `Bio_all` is total biomass in metric tonnes and `Recruit_0` is recruitment in thousands of age-0 fish.

The 2023 report's Tables ii and iii give spawning-output and recruitment estimates with 95% asymptotic intervals for 2013–2023. Age-specific surfaces have no corresponding uncertainty in the recovered report. Keep spawning output in eggs and do not label it SSB. These documented point estimates and available aggregate intervals are suitable source outputs; no uncertainty is inferred for other rows.

## Selection decision

The source import is recorded in the canonical database as a partial assessment. The official production archive preserves the original observations and extensive numerical fitted outputs. The record remains partial because the selected model does not fit observed fishery catch-at-age or an age-specific abundance index, and the survey age data are conditional age-at-length samples. Preserve these distinctions and do not manufacture age-specific observations from fitted states.

## Sources

- [2023 Status of Rex Sole along the U.S. West Coast assessment](https://www.pcouncil.org/documents/2024/02/status-of-rex-sole-glyptocephalus-zachirus-along-the-u-s-west-coast-in-2023.pdf/) (including Tables ii–iii and model description)
- [2023 Rex Sole Stock Synthesis model files](https://www.pcouncil.org/documents/2024/02/rex-sole-2023-model-files.zip/)
- [NOAA Rex Sole species information](https://www.fisheries.noaa.gov/species/rex-sole)
- NOAA Stock SMART entity 10059; the retrieved record and source manifest are in the ignored local `source_cache/discovery_noaa_pacific_rex_2023/` folder.
