# NOAA Gulf king mackerel

## Unit and latest assessment

NOAA Stock SMART identifies `NOAA:10171` as the Gulf of Mexico unit of king
mackerel (*Scomberomorus cavalla*). `NOAA:10172` is the separate Southern
Atlantic Coast unit; they are not combined. No canonical database stock for
this species was found.

The latest completed full age-structured production assessment located is the
operational Stock Synthesis SEDAR 38 Update. Stock SMART assessment 10686 was
fully accepted in 2020 and uses data through fishing year 2017-2018 (ending
June 30, 2018). Its 2020 report updates recreational catch using MRIP-FES,
revises shrimp bycatch and abundance indices, and retains SEDAR 38 life-history
and model assumptions. The later 2023 Stock Monitoring Update (assessment
13022) was reviewed as “Accept previous approach, remand new attempt”; it does
not replace the accepted age-structured run.

SEDAR 99 is the current Gulf king mackerel assessment process. Its schedule,
updated October 2026, identifies data through FY 2025 and a final assessment
report due September 2027. It is not yet a completed assessment, so its
preliminary papers must not be combined with SEDAR 38 Update outputs.

## Inputs and assumptions

- The accepted model uses annual fishing years from July 1 through June 30.
  Removals include commercial handline and gillnet in metric tons, recreational
  headboat and charter/private fisheries in numbers of fish, and dead discards
  including shrimp-bycatch estimates.
- The report lists age-composition data coverage for commercial handline in
  FY 1991–2017 and recreational charter/private in FY 1986–2017. In the model,
  age observations are conditional age-at-length data. Numeric run-matched
  conditional-age-at-length arrays are not printed in the update report; the
  report shows relative age-composition figures. Their availability in a
  public source sufficient to reconstruct catch-at-age remains unresolved.
- The model used commercial handline and recreational headboat CPUE, plus
  SEAMAP groundfish-trawl and larval/plankton indices. These indices are
  aggregate, not age-specific abundance observations. SEAMAP trawl selectivity
  was fixed to ages 0–1; shrimp bycatch selectivity was fixed to age 0.
- Sex-specific von Bertalanffy growth was estimated. Maturity-at-age,
  fecundity, and age-specific natural mortality were fixed from SEDAR 38.
  Natural mortality follows an externally calculated Lorenzen vector. M =
  0.174 is used in the stock-status reference-point definition. The assessment
  reports spawning output as millions of hydrated eggs, not conventional
  biomass SSB.
- The 2020 update report refers to the 2014 SEDAR 38 report for the retained
  biological inputs and model setup. Run-matched numeric weights-at-age and
  age-composition input arrays were not recovered in this screen.

## Available outputs and screening decision

Table 5.1 reports annual age-0 recruitment (thousands of fish), spawning output
(billions of eggs), exploitation-rate F, and retained landings through FY
2017–2018. Terminal stock-status ratios have uncertainty intervals. Numeric
annual N-at-age and F-at-age arrays were not located, and the annual population
series in Table 5.1 are point estimates.

This is a distinct screened candidate with useful aggregate outputs. Its
eligibility for source curation remains unresolved: the accepted report does
not provide numeric run-matched conditional-age-at-length inputs for a
defensible age-specific catch reconstruction, and the exact run-matched
weight-at-age inputs also remain to be recovered. This is a source-access
question, not a finding that the model lacked age data. No canonical values
were imported.

## Sources

- [SEDAR 38 Update assessment report](https://sedarweb.org/documents/2019-update-sedar-38-update-assessment-report-gulf-of-mexico-king-mackerel/),
  September 2020.
- [SEDAR 38 base assessment report](https://sedarweb.org/documents/sedar-38-final-stock-assessment-report-gulf-of-mexico-king-mackerel/),
  September 2014; retained model and life-history assumptions.
- [SEDAR 38 Update executive summary](https://sedarweb.org/documents/sedar-38-gulf-of-mexico-king-mackerel-executive-summary-update-report/),
  accepted by the Gulf Council SSC in September 2020.
- [SEDAR 99 assessment page](https://sedarweb.org/assessments/sedar-99-gulf-of-mexico-king-mackerel/)
  and [schedule updated October 2026](https://sedarweb.org/documents/sedar-99-gulf-of-mexico-king-mackerel-project-schedule/).
- NOAA [Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10171)
  metadata snapshot cached with the discovery inventory.

Reviewed 2026-10-30. The listed PDF files and checksums are in the ignored local
cache at `source_cache/discovery_noaa_gulf_king_mackerel_2020/sources.csv`.
