# NOAA Southeastern U.S. Mutton Snapper (Stock SMART 11342)

## Assessment and stock unit

SEDAR 79 is the latest completed detailed assessment identified for NOAA Stock
SMART 11342. The final assessment report was disseminated in October 2024 and
uses data through 2023. In March 2025, the joint Gulf of Mexico and South
Atlantic SSC review concluded that SEDAR 79 was consistent with best scientific
information. The report models a single closed Southeastern U.S. population
across the Gulf and South Atlantic council jurisdictions. It treats the
Caribbean population boundary as separate.

The Stock SMART area text names the South Atlantic and Gulf, but SEDAR 79 is one
combined assessment unit, not two candidate stocks. No canonical record or
other candidate with scientific name Lutjanus analis was found.

## Age-structured source evidence

The production assessment is an annual, single-area Stock Synthesis model with
ages 1–40+, combined sexes, four directed fleets, one commercial longline CPUE
index and six fishery-independent indices. Its observation inputs are not
marginal catch-at-age: it fits catch-weighted length compositions and
conditional age-at-length (CAAL). The final report plots directed-fleet CAAL
in Section III Figures 9–12 and fishery-independent CAAL in Figure 17. The
Data Workshop report documents age samples by year and source, while the
assessment report describes catch and length inputs.

Annual catch-at-age can be reconstructed approximately from the published
catch/length inputs and CAAL surfaces, but doing so requires digitizing the
report figures. The reviewed public materials did not include the complete
numeric model-ready CAAL arrays or a run-matched Stock Synthesis data/control
archive. This is a source-supported but labor-intensive reconstruction, not a
directly observed catch-at-age series. The fishery-independent abundance
indices are aggregate annual series; the age-0 index is a recruitment index,
not a full age-specific abundance index.

## Biology, mortality, and timing

SEDAR 79 SAR Section III Table 10 specifies the fixed maximum-total-length to
whole-weight relationship (a = 6.63e-06, b = 3.1601, weight in kg and length
in cm), a fixed logistic maturity-at-age with A50 = 3.48 years, and a fixed
female fraction of 0.5. Growth is estimated in the assessment and is used to
calculate age-specific weight and maturity surfaces. The same table sets the
natural-mortality reference rate to 0.129 per year; age-specific M is
calculated using the growth relationship and is shown in Table 11. The
supporting SEDAR 79-DW-12 report documents the reproductive analysis, and
SEDAR 79-DW-22 documents age, growth, and mortality methods.

The assessment is annual, spawning peaks in June, and juvenile settlement is
assigned to January. A shared within-year fraction for all abundance indices
is not established by the reviewed sources; individual index timing should be
verified from the source files.

## Reported outputs and limitations

Section III Table 16 reports annual total biomass, female spawning-stock
biomass, total abundance (thousands of fish), age-1 recruitment (thousands of
fish), and depletion for 1981–2023. Table 15 reports fleet-specific apical F
and combined age-3 F. These support direct aggregate-output comparisons. Numeric
annual N-at-age and F-at-age tables were not located in the reviewed report;
age-specific values would require matching native output files or careful
figure extraction. No canonical assessment, input, or output values have been
added at this screening stage.

## Sources reviewed and cached

| Source | Relevance |
|---|---|
| [SEDAR 79 project page](https://sedarweb.org/assessments/sedar-79/) | Assessment identity and final report / supporting-document links |
| [SEDAR 79 final stock assessment report](https://sedarweb.org/documents/sedar-79-southeastern-us-mutton-snapper-final-stock-assessment-report/) | Production model, input figures, biology, assumptions, diagnostics, and output tables |
| [SEDAR 79-DW-03 size and age information](https://sedarweb.org/documents/sedar-79-dw-03-size-and-age-information-for-mutton-snapper-lutjanus-analis-collected-in-association-with-fishery-dependent-monitoring-along-floridas-coast/) | Fishery-dependent age-sample coverage and age data methods |
| [SEDAR 79-DW-12 reproduction](https://sedarweb.org/documents/sedar-79-dw-12-mutton-snapper-reproduction/) | Maturity and reproductive timing |
| [SEDAR 79-DW-22 age, growth, and natural mortality](https://sedarweb.org/documents/sedar-79-dw-22-descriptions-of-age-growth-and-natural-mortality-of-mutton-snapper-lutjanus-analis-collected-from-fisheries-independent-and-dependent-sources-in-the-southeastern-united-states-fro/) | Age coverage, morphometric conversions, growth, and mortality methods |
| [Joint SSC review of SEDAR 79](https://sedarweb.org/documents/gulf-and-sa-ssc-review-of-sedar-79-southeastern-u-s-mutton-snapper/) | Confirms the combined stock boundary, 1981–2023 run, and assessment review outcome |

Files were retrieved on 2026-10-31 and cached under
source_cache/discovery_noaa_mutton_snapper_sedar79_2024/. The cache manifest
records the source URL, byte size, and SHA-256 for each file.

Screening decision: eligible for source curation with an explicit figure-digitization limitation. A partial canonical source import was completed on 2026-11-12; see source_reviews/noaa_southeastern_us_mutton_snapper_sedar79_2024.md. The numerical composition arrays and annual age-specific indices remain unavailable.
