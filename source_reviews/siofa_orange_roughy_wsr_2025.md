# SIOFA orange roughy: Walter Shoal Ridge, 2025 assessment

## Assessment and unit

The latest detailed assessment located for the Walter Shoal Ridge (WSR) area is
the 2025 Casal2 age- and sex-based assessment using data through 2023. The
assessment is published as Report 2 under project ORY-2024-01. The later SIOFA
SC11-28 final project report was published in March 2026. WSR is an assessment
area in SIOFA Statistical Area 2; the public sources do not establish it as a
separate biological stock.

The 2025 project separately assessed Long Walter's Shoal Ridge (LWSR), which
includes WSR, and the South-West Indian Ocean Ridge (SWIOR). These are
overlapping assessment areas, not additional independent stock units. This
review imports only the WSR run and does not combine its data with LWSR or
SWIOR. The SIOFA orange roughy unit is distinct geographically from New
Zealand's ORH 7A stock.

## Inputs and assumptions

The WSR assessment fits total annual catch biomass, two CPUE series, acoustic
biomass by feature, and unsexed age-frequency distributions for 2017, 2019 and
2020. The report says the raw 2017 age observations were unavailable; 2019 and
2020 scaled age frequencies were recalculated from available data. The public
assessment report identifies the series and years but does not provide all
numerical observation vectors. Catch histories are shown graphically, not in a
complete numerical table.

The separate ORY-2023-02 acoustic report publishes survey-level biomass and
sampling CVs. Its historical feature identifiers do not fully match the names
used for the 2025 WSR model (for example, the model names Bounty and Hollows
while the acoustic report labels the corresponding historical features
differently). The assessment says it averaged acoustic biomass within feature
and year with weights inversely proportional to CV. Because the public sources
do not verify every feature crosswalk, the survey table has not been presented
as a complete run-matched model input series. The Secretariat supplied source
data to the assessment authors; those source files are not attached to the
public reports.

The model represents ages 1–120 by sex with a plus group at age 120 and three
time steps (recruitment, fishing and ageing). Recruitment follows Beverton–Holt
with steepness 0.57. Maturity is an estimated logistic age curve set equal to
selectivity and shared across sexes. Natural mortality is estimated for both
sexes together. In base case R1.4, its normal prior has mean 0.045 per year and
CV 0.1; the sum of acoustic catchabilities has a normal prior with mean 0.8 and
CV 0.1. Age-frequency data use effective sample sizes and Francis reweighting;
acoustic and CPUE observations receive 20% additional process error.

Report 1 documents updated growth and length-weight analyses, but does not
publish all run-matched numerical input arrays. Survey-level dates and timing
are available for parts of the acoustic series; the assessment report does not
state a single within-year timing for every observation series.

## Reported scalar outputs

Only the R1.4 base-case MCMC summary is imported. Table 6 values are medians
unless otherwise stated. The 2023 SSB/B0 interval is the reported 95% credible
interval; no standard errors are reported for these scalar summaries.

- Initial unfished spawning biomass B0: 25,627 t (95% CI 22,409–30,034).
- 2023 spawning biomass: 59.3% of B0 (95% CI 52.4–66.1).
- Estimated combined-sex M: 0.043 per year.
- Sleeping Beauty acoustic q: 0.28.
- F40: 0.033 per year; BMSY: 30.8% of B0; FMSY: 0.045 per year.
- 2024 TAC values at F40 and FMSY: 513 t and 685 t, respectively.
- The report states that 100% of MCMC chains had 2023 biomass above 40% B0.

These model-derived TAC values are not the same as the interim SIOFA status-quo
catch limit: the later SIOFA harvest-strategy review says the interim limit is
the average annual catch in 2015–2020 and notes no further management advice had
been agreed. The public materials reviewed do not show that this particular
R1.4 run was applied directly to set management advice.

Annual numeric N-, F- and M-at-age output series are not tabulated in the
publicly available run report. The assessment input and output records therefore
remain partial: numerical catch-at-age and annual age-specific population
output series are not available in the public sources reviewed.

## Sources

- [ORY-2024-01 project page](https://siofa.org/science/sc-works/ORY-2024-01)
- [Report 1: biological parameters and model inputs](https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-1-Biological-parameters-model-inputs.pdf)
- [Report 2: WSR 2025 assessment](https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-2-WSR-stock-assessment.pdf)
- [Report 3: LWSR and SWIOR assessment](https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-3-LWSR-SWIOR-stock-assessment.pdf)
- [ORY-2023-02 acoustic biomass report](https://siofa.org/meeting-file/meeting-documents/10th_annual_meeting_of_the_siofa_scientific_committee_sc10/SC-10-41-SIOFA-ORY-2023-02-Final-Report.pdf)
- [SC11-28 final project report](https://siofa.org/system/files/meeting_documents/11th_annual_meeting_of_the_siofa_scientific_committee_sc11/SC-11-28-SIOFA-ORY-2024-01-Final-Report.pdf)
- [SIOFA harvest-strategy review, WS2025-PAM3-03](https://siofa.org/system/files/meeting_documents/third_scientific_committee_workshop_to_progress_the_siofa_precautionary_approach_and_management_projects_ws2025-pam3/WS2025-PAM3-03-Update-PAM-2024-03-progress.pdf)

Local cached copies and checksums are recorded in
`provenance/siofa_orange_roughy_2025_sources.csv`.
