# NOAA South Atlantic King Mackerel

## Unit and latest completed assessment

NOAA Stock SMART `10172` is the Southern Atlantic Coast management unit of
king mackerel (*Scomberomorus cavalla*). It is distinct from Gulf of Mexico
unit `10171`. The assessment documents a winter mixing zone south of the
Florida Keys, but reports separate South Atlantic and Gulf stock assessments.

The latest completed accepted age-structured run found in the Stock SMART
snapshot is operational assessment `10687`, the SEDAR 38 Update. NOAA Stock
SMART records full acceptance in 2020 and a terminal fishing year of 2017.
The report defines fishing years as March 1 through February 28 (February 29
in leap years), so the terminal year ends February 28, 2018. The SEDAR 38
Update report is dated April 2020. A February 2026 draft terms of reference
plans a new update through FY 2026–2027; it is not a completed assessment and
does not replace the 2020 outputs.

## Inputs and assumptions

- Commercial handline and gillnet landings are reported in metric tons;
  recreational headboat, charter/private, and tournament landings are in
  numbers of fish. The assessment includes discard series, including shrimp
  bycatch.
- The model uses annual conditional age-at-length observations, with age data
  for handline in FY 1991–2017, charter/private in FY 1986–2017, and tournament
  in FY 1986–2017. Age counts are grouped by 5 cm length bins and are sex
  specific where sex is known. Numeric run-matched conditional-age-at-length
  arrays were not recovered in the reviewed sources, so a catch-at-age
  reconstruction cannot yet be verified.
- The included abundance indices are commercial handline trolling, recreational
  headboat, and a fishery-independent SEAMAP age-0 trawl index. The report also
  displays a charter/private index for comparison but states it was not used in
  Stock Synthesis. These are aggregate indices (with the trawl series for age
  0), not a full age-specific survey-abundance series.
- Natural mortality is fixed by age from age 0 through 11+: 0.657, 0.247,
  0.224, 0.208, 0.195, 0.186, 0.178, 0.172, 0.167, 0.163, 0.160, and 0.157.
  The update gives a fixed length-based female maturity ogive and fecundity
  relationship. It reports sex-specific growth parameters and length-weight
  relationships carried forward from SEDAR 38. A derived weight-at-age surface
  is not tabulated, but appears reconstructible from the reported parameters
  if the Stock Synthesis calculation details are verified.
- The report does not specify a fractional within-year observation time for
  the indices.

## Available outputs and screening decision

The update reports annual exploitation rate by numbers, recruitment in
thousands of age-0 fish, and spawning output in millions of eggs through FY
2017. Terminal status ratios have confidence intervals. Numeric annual
N-at-age and instantaneous F-at-age arrays were not located. The reported
fishery-mortality series is an exploitation rate, not an age-specific
instantaneous fishing-mortality surface. Spawning output is egg based and is
not conventional biomass SSB.

This is a distinct, screened candidate with a detailed accepted assessment and
useful aggregate outputs. Eligibility remains unresolved because the numeric
run-matched conditional age-at-length and length-composition inputs needed to
verify catch-at-age reconstruction were not recovered. The report also lacks a
full age-specific survey index and numeric annual N-at-age/F-at-age outputs.
This records a source gap, not a confirmed absence of age data from the
assessment. No canonical database values were imported.

## Sources

- [SEDAR 38 Update assessment page](https://sedarweb.org/assessments/sedar-38-update/)
- [SEDAR 38 Update South Atlantic assessment report](https://sedarweb.org/documents/2019-update-sedar-38-update-assessment-report-south-atlantic-king-mackerel/), April 2020
- NOAA [Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10172) assessment metadata, from the cached agency snapshot
- [Draft SEDAR terms of reference](https://safmc.net/documents/sedar_a3_sow_tors_mar2026-pdf/), February 25, 2026
- NOAA [InPort record for the SEDAR 38 South Atlantic base report](https://www.fisheries.noaa.gov/inport/item/61265). Its listed SEDAR PDF endpoint returned 404 during retrieval; the 2020 update itself reports the fixed biological assumptions summarized above.

The downloaded update report and draft terms of reference, with retrieval dates
and SHA-256 checksums, are listed in the ignored local cache at
`source_cache/discovery_noaa_south_atlantic_king_mackerel_2020/sources.csv`.
Reviewed 2026-10-30.
