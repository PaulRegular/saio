# NOAA Atlantic cod management units assessed in 2024

## Unit identity and selected runs

The 2023 Atlantic Cod Research Track assessment established separate spatial units. NOAA's June 2024 Management Track assessed Eastern Gulf of Maine (Stock SMART 17281), Western Gulf of Maine (17280), Georges Bank, and Southern New England (17282). The final Amendment 25 environmental assessment lists the statistical reporting areas for the four new/current units: EGOM 465, 467, 511, 512; WGOM 513, 514, 515, 521, 526, 541; GB 464, 522, 525, 542, 543, 551, 552, 561, 562; and SNE 533, 534, 537-539, 611-616, and 621-639. These are distinct present-day units, not four aliases for the legacy combined Gulf of Maine/Georges Bank records.

The June 2024 Management Track peer-review panel found the selected models suitable for management advice. The post-review material identifies the runs through 2023: Western Gulf of Maine `Update 4`, Eastern Gulf of Maine `Post Review`, and Southern New England `revised projections`. The panel selected the Western Gulf of Maine model excluding the 2023 spring BLLS observation. It recommended changes to the SNE bridge-year projection catch; this affects the projection calculation, not the distinction between its assessment unit and the previous broader Georges Bank unit. NOAA's current assessment-area table was used to reconcile boundaries; the historical combined Gulf of Maine candidate remains a predecessor, not a one-to-one match to either current Gulf unit. The current NOAA Georges Bank record already represents the revised domestic GB unit. Eastern Georges Bank (NOAA ID 12805) is a separate transboundary match to the existing DFO EGB record (see `noaa_eastern_georges_bank_2023_identity.md`).

## Input and output coverage

The management-track models are WHAM state-space assessments over 1981-2023. The WGM and EGOM support PDFs show age groups 1-9+ and annual age-composition panels; WGM displays commercial and recreational catch compositions and multiple survey compositions. EGOM also has survey-age compositions, including updated Eastern Gulf of Maine Sentinel Survey compositions for 2012-2021. Recent EGOM commercial and recreational age compositions were not characterized after 2013. SNE support plots contain catch and survey age-composition diagnostics, but its report notes sparse recent commercial ages, no recreational ages, and limited spring-survey age samples.

The input-data materials plot age-specific stock/fleet/index weights and maturity, but do not provide their numeric run-matched matrices. Survey indices are shown as aggregate series; no numeric age-composition likelihood arrays or source tables were found in the recovered support packages. The reports give terminal-year assessment data through 2023 and aggregate status outputs (SSB in metric tonnes, fully selected F as a rate, and recruitment in thousands of fish) for 2014-2023. Age-specific population and mortality figures/diagnostics are available as plots, not numeric annual fitted surfaces. Exact model-configured within-year survey timing and selected M vectors were not recovered.

Accordingly, all three units are **screened with eligibility unresolved**. The evidence confirms age-structured production models and age-composition inputs, but the available public support files do not include the numeric arrays needed for a faithful source import. Figures are not digitized or treated as original input data, and age-based values from earlier research-track runs are not substituted for the accepted 2024 model.

## Sources and local cache

- [June 2024 Management Track peer-review panel report](https://d23h0vhsm26o6d.cloudfront.net/2.a.xi_2024-June-Management-Track-Peer-Review-Panel-Report_508_7_18_24.pdf)
- [Western Gulf of Maine 2024 report](https://d23h0vhsm26o6d.cloudfront.net/2.a.vi_Western_Gulf_of_Maine_cod_Update_4.pdf)
- [Eastern Gulf of Maine 2024 report](https://d23h0vhsm26o6d.cloudfront.net/2.a.viii_Eastern_Gulf_of_Maine_Atlantic_Cod_Update_2024_Post_Review.pdf)
- [Southern New England 2024 report](https://d23h0vhsm26o6d.cloudfront.net/2.a.iv_Southern_New_England_Cod_2024_report_revised_projections.pdf)
- [SASI support portal](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php)
- [Final Amendment 25 environmental assessment](https://repository.library.noaa.gov/view/noaa/73154/noaa_73154_DS1.pdf)

The three 2024 support ZIPs, individual reports and final peer-review report are cached under `source_cache/noaa_cod_new_units_2024/`; `sources.csv` records retrieval dates and SHA-256 checksums. The NOAA institutional repository denied direct download of the 247-page Amendment 25 PDF in this session; its source link is retained in the candidate record and this review.
