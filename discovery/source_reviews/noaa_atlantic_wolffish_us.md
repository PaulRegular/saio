# Atlantic wolffish, U.S. Gulf of Maine–Georges Bank (NOAA:11562)

Reviewed 2026-11-01. The pinned NOAA Stock SMART snapshot retrieved 2026-10-28 lists stock 11562 as assessment 12525, assessment year 2022, terminal data year 2021, NEFSC, and a Gulf of Maine/Georges Bank area. Stock SMART labels the result “Full acceptance” and the model `SCALE`. Its citation field still points to the 2017 operational assessment, so the 2022 report title, assessment ID, terminal year, and management-track material were used to verify the run. The 2022 report is marked as a draft working paper; the Fall 2022 panel report says the wolffish update was Level 1 direct delivery and was not peer reviewed. A 2025 Northeast Multispecies framework document still refers to the 2022 assessment.

NOAA manages one Atlantic wolffish stock in U.S. waters. It is separate from the ICES candidate `caa.27.5a` for Iceland grounds and from Canadian Atlantic wolffish assessment units. The 2009 NOAA status review describes the earlier U.S. working unit as coastal waters of Massachusetts, New Hampshire, and Maine and notes that survey records on the northeast edge of Georges Bank were excluded because of difficulties partitioning Canadian catches. The 2022 update retained the existing SCALE configuration, but the reviewed current report does not restate all spatial strata. The contemporary NOAA Stock SMART unit is therefore retained as one U.S. candidate with the historical boundary caveat recorded; no matching canonical stock was found.

## Assessment inputs and fit to the age-disaggregated screen

The 2022 management-track report updates catch, survey indices, and the SCALE model through 2021. The panel describes SCALE as a statistical catch-at-length model using total catch, catch-size distributions, growth information, and size and age data from survey recruitment and adult indices. It identifies one fishery fleet and four survey indices: NEFSC spring recruitment, NEFSC spring and fall adult indices, and a Massachusetts DMF spring adult index. The model treats zero survey catches as missing. Catch has been almost entirely discards since the 2010 no-possession rule; the 2022 report uses an 8% discard mortality assumption.

The source does not provide catch numbers-at-age or age compositions from which they can be reconstructed. It does not provide a full age-specific survey abundance series: the recruitment index is age 1, while the other indices are adult survey series. The 2009 NOAA status review explicitly says age-based abundance measures could not be developed and describes the assessment as using length-based data in SCALE. The 2022 report does not provide full age-specific weight or maturity surfaces; the 2020 update changed the maturity knife-edge from 50 to 52 cm, rather than supplying maturity-at-age. Exact age-specific natural-mortality settings and observation timing were not recovered from the current report. These limits mean that the available age and growth samples do not support the age-disaggregated inputs required for the initial comparison set.

## Reported outputs and decision

The 2022 report provides aggregate time-series figures through 2021 for SSB, fully selected F, age-1 recruitment, catch, and survey biomass indices. It reports 2021 SSB of 690 mt and fully selected F of 0.004. The report says approximate 90% lognormal intervals are not shown because MCMC is not fully developed for SCALE. It does not provide N-at-age or F-at-age surfaces. These aggregate outputs are useful for general source review but do not compensate for the missing age-disaggregated inputs.

Screening result: **new U.S. assessment unit; ineligible for the age-disaggregated candidate set**. management. No canonical stock, assessment, input, or output data were added.

The 2022 assessment PDF and Fall 2022 panel report are cached under the gitignored `source_cache/discovery_noaa_atlantic_wolffish_2022/`. The NOAA Institutional Repository page and source text for the 2009 status review were accessible, but its direct PDF download returned Access Denied; that attempt and source URL are recorded in the cache manifest. NOAA Stock SMART metadata are available from the pinned snapshot cached under `source_cache/discovery_noaa_stocksmart/`.

## Sources

- [NOAA 2022 Atlantic wolffish management-track assessment](https://d23h0vhsm26o6d.cloudfront.net/5_2022_CAT_UNIT_RPT_UPDATED.pdf).
- [NEFSC Fall 2022 Management Track panel report](https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf), including the Level 1 review status, model inputs, and the note that wolffish was not peer reviewed.
- [NOAA 2009 Atlantic wolffish status review](https://repository.library.noaa.gov/view/noaa/17699), for the SCALE method and historical U.S. spatial definition.
- [NOAA Atlantic wolffish management page](https://www.fisheries.noaa.gov/species/atlantic-wolffish/management), which identifies one U.S.-managed stock.
- [NOAA 2025 Framework Adjustment 69](https://repository.library.noaa.gov/view/noaa/73153/noaa_73153_DS1.pdf), which continues to cite the 2022 wolffish assessment.
