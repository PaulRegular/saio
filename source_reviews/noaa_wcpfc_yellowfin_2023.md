# Western and Central Pacific yellowfin tuna — 2023 assessment

## Stock and assessment status

This is the WCPFC Western and Central Pacific yellowfin tuna unit (NOAA Stock SMART discovery ID 11694). The 2023 WCPFC assessment, with data through 2021, remains the advice basis identified by the SC22 outcome. The newer 2026 detailed assessment is recorded separately as the latest detailed run; its management-advice review was deferred to SC23. These are separate assessment events for one stock unit.

The 2023 assessment used a 54-model structural uncertainty grid. The pinned SPC TAF repository also contains a single diagnostic reference fit. This import keeps those sources distinct: the diagnostic fit supplies age-specific and fleet-level model outputs, while the grid summary supplies the 54-model median spawning-biomass trajectory and combined grid-plus-estimation summaries for three terminal reference ratios. Diagnostic-fit values are not described as grid means.

## Source files and provenance

The local ignored cache is `source_cache/discovery_noaa_wcpo_yellowfin_2023/`. The tracked `provenance/discovery_noaa_wcpo_yellowfin_2023/sources.csv` records source URLs, retrieval date, SHA-256 checksums, byte sizes, and pinned repository revisions.

The model and TAF files are pinned to SPC repository commit `54274c0edac84e65fdbd8ef5996038e6a8714641`. The report cache is the NOAA mirror of WCPFC-SC19-2023/SA-WP-04 Rev. 02; the WCPFC meeting page remains the official report entry point. Grid summary CSVs are pinned to SPC repository commit `6b28f0bf4975895beae4df861124b30286ff6fa0`. The full grid-results archive is not needed for the summaries imported here.

## Inputs preserved

- The native MFCL fishery file contains 7,988 dated fishery records across 37 model fisheries. The first 32 are extraction fisheries and the final five are index fisheries. Catch number/weight flags are preserved: number-scaled catches remain fish, biomass-scaled catches remain metric tonnes. Non-negative effort values are retained in their native fishery-specific units; source `-1` effort codes are omitted.
- Five regional standardized longline CPUE series contain 1,400 quarterly values for 1952–2021. The TAF values match native index-fishery catch divided by effort and 1,000,000. Quarter midpoint is retained as model timing, not asserted as the exact survey date.
- Length-frequency inputs contain 135,090 rows for 1965–2021 in the source's 2 cm bins from 10–12 cm through 198–200 cm. Weight-frequency inputs contain 622,800 rows for 1956–2021 in 1 kg bins from 0–1 kg through 199–200 kg. Frequencies are preserved without renormalization; the TAF exports do not provide the unweighted sample sizes for each composition.
- The otolith export contains 1,471 individual conditional age-at-length observations from 2009–2018. It is stored as age-by-length counts within year, quarter and area, with the corresponding sample counts. These are growth data, not marginal catch-at-age or age-specific abundance observations. The TAF export contains no separate likelihood-weight field.
- Tag data contain 13,300 release-frequency rows from 1989–2020 and 5,938 recapture-count rows. Release frequencies are retained as supplied because their scale is not confirmed as raw tag counts; recaptures retain the reported count and linked release-group dimensions.

No catch-at-age or age-specific abundance-index series was recovered from these sources. Independent observed weight-at-age and maturity-at-age vectors are not provided; the model-derived biological surfaces are kept among outputs.

## Outputs preserved

The pinned TAF diagnostic export supplies 56,000 numbers-at-age rows, 16,800 annual fishing-mortality-at-age rows, 56,000 mature-biomass-at-age rows, 1,400 quarterly spawning-biomass rows, 1,400 fitted CPUE values, 8,960 fishery catch predictions, and annual summary series for 1952–2021. It also supplies model-derived length, weight, maturity and natural mortality for 40 quarterly age classes. The last class is a plus group. These are single-run point estimates and have no standard errors or intervals in the export.

The 54-model grid summary supplies a median spawning-biomass trajectory for 1952–2021. The combined grid-plus-estimation file reports mean, median, minimum, 10th percentile, 90th percentile and maximum for terminal depletion, F/FMSY and SB/SBMSY. These are preserved as distribution summaries; the 10th–90th percentile span is not labelled a confidence interval.

## Model structure and remaining gaps

The model uses quarterly time steps, five spatial model areas, and 40 quarterly age classes with class 40 as a plus group. The 54-model grid varies tag-mixing period, size-composition weighting, age-data weighting and steepness. TAF input/output surfaces reflect the single diagnostic model, not the full grid. The assessment record and candidate remain partial because no direct catch-at-age or age-specific abundance indices are available, the age compositions are conditional growth data, and diagnostic age-specific uncertainty is unavailable.

## References

- [WCPFC-SC19-2023/SA-WP-04 report page](https://meetings.wcpfc.int/node/19352)
- [NOAA mirror of the cached Rev. 02 report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9497)
- [Pinned 2023 diagnostic model repository](https://github.com/PacificCommunity/ofp-sam-yft-2023-diagnostic/tree/54274c0edac84e65fdbd8ef5996038e6a8714641)
- [Pinned 2023 grid summary repository](https://github.com/PacificCommunity/ofp-sam-yft-2023-grid/tree/6b28f0bf4975895beae4df861124b30286ff6fa0)
