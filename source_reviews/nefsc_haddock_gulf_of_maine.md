# Gulf of Maine haddock

## Stock identity and official assessment

The metadata record is `ck_nefsc_garmiii_aeglefinus_5y` (Charbonneau–Keith identifier `NEFSC-GARMIII_aeglefinus_5Y`), Gulf of Maine haddock (*Melanogrammus aeglefinus*). It is distinct from Georges Bank haddock, which has its own stock record and assessment area.

The current official assessment is NOAA's 2026 Management Track WHAM assessment, with fitted data through 2025. The September 2026 peer-review panel concluded that it was technically sufficient for stock-status evaluation and catch advice and that it met the assessment terms of reference. The assessment updates the 2024 WHAM Management Track model. Its partial numerical record is now in the canonical database; the import is maintained in `scripts/database/094_import_nefsc_gom_haddock_2026.R`.

## 2026 model and data inventory

The peer-review report describes one combined commercial/recreational fishery fleet and four abundance indices: NEFSC spring and fall bottom-trawl survey (BTS) series, 1977–2025, and spring and fall Cooperative Bottom Longline Survey (BLLS) series, 2014–2025. The model uses a Dirichlet likelihood for age compositions from the five data streams (the fishery and four surveys), estimates age-specific selectivity for each stream, fixes age-invariant natural mortality at 0.2, and uses maturity at age averaged across the time series. Recruitment deviations follow an AR1 process around a time-series mean; the N-at-age process is 2DAR1, with recruitment decoupled from ages 2+. The official report identifies the fully selected F ages as 6–9. The exact model age grid, age-composition matrices and sample sizes, survey/index values, weights, maturity values, and fitted N-at-age and F-at-age surfaces were not recovered as numerical data.

The 2026 SAR and peer-review report provide total catch for 2015–2025 and aggregate model-result tables. The following values are transcribed from Tables 1 and 2 of the SAR. Catch and SSB are metric tonnes; recruitment is thousands of age-1 fish; F is fully selected F for ages 6–9. Historical point estimates are reported without numerical intervals in the tables; 90% intervals visible in figures have not been digitized.

| Year | Total catch (t) | SSB (t) | F (ages 6–9) | Age-1 recruitment (thousand fish) |
|---:|---:|---:|---:|---:|
| 2015 | 1,512 | 52,538 | 0.046 | 9,613 |
| 2016 | 3,406 | 73,129 | 0.070 | 10,899 |
| 2017 | 4,894 | 71,833 | 0.095 | 11,922 |
| 2018 | 3,710 | 89,867 | 0.052 | 7,369 |
| 2019 | 4,542 | 69,187 | 0.072 | 4,972 |
| 2020 | 4,810 | 42,659 | 0.130 | 6,153 |
| 2021 | 4,618 | 19,673 | 0.280 | 23,209 |
| 2022 | 3,353 | 22,117 | 0.190 | 22,106 |
| 2023 | 2,734 | 14,586 | 0.274 | 2,537 |
| 2024 | 2,288 | 16,701 | 0.213 | 1,022 |
| 2025 | 1,741 | 11,339 | 0.223 | 1,704 |

The 2026 SAR also reports reference points: FMSY proxy 0.35 (90% interval 0.31–0.40), SSBMSY proxy 7,809 t (4,489–13,583), MSY proxy 1,924 t (1,101–3,360), and mean age-1 recruitment 5,649 thousand fish. Its 2026–2031 projection table gives SSB of 9,335, 7,293, 6,229, 6,208, 6,535, and 6,799 t, with respective 90% intervals (4,186–20,816), (2,463–21,593), (1,944–19,962), (1,534–25,117), (1,238–34,494), and (1,047–44,158). F for ages 6–9 is 0.268 in 2026 and 0.352 in 2027–2031. The 2026 catch of 1,944 t is a Groundfish PDT input assumption; projected catches for 2027–2031 are 2,099, 1,618, 1,481, 1,524, and 1,599 t. Projections use harvest at FMSY from 2027, five-year average weight-at-age and selectivity, and average maturity. These results are projections, not fitted historical estimates.

The peer review recommends exploring separate commercial and recreational fleets and sensitivity to recent maturity-at-age in reference points and projections. These are recommendations for future assessments, not changes to the accepted 2026 model.

## Earlier 2024 input materials

The 2024 NOAA bundle remains useful for understanding input streams but is not a substitute for the 2026 production data. `Data.zip` contains 36 PNGs, three GIFs, and two JPGs showing commercial and recreational catch-at-age, spring and fall BTS information, BLLS information, age-specific weights, and maturity. `Models.zip` contains 243 PNG diagnostic and output plots. Neither archive contains machine-readable age-composition, index, biological-input, or fitted-model tables. The plotted values do not recover exact observations, effective sample sizes, or the original survey scales and are not entered as exact inputs. Do not mix the 2022 Research Track numerical data with either Management Track run.

The 2024 summary table reports a different model's catch, SSB, full F, and recruitment through 2023. These values are not substituted for the 2026 fitted outputs, which include model changes and updated data. The 2026 peer-review report notes that additional 2018–2023 commercial age-composition and weight-at-age data were incorporated in the 2026 assessment after being excluded from the 2024 Management Track fit.

## Cache and translation status

The 2024 and 2026 NOAA Stock Assessment Information System (SASI) listings, both assessment bundles, and the September 2026 peer-review report are cached under `source_cache/nefsc_haddock_gulf_of_maine_2026/`. The local `manifest.csv` records source URLs, retrieval and verification dates, and SHA-256 checksums. The source bundles contain reports and figures, not native input tables or a fitted WHAM object.

The partial database import preserves the recent aggregate catch series, historical SSB/F/recruitment tables, reference points, and reported projections. Inputs remain partial: there are no numerical catch-at-age or survey series, survey weights, biological age surfaces, or exact model age grid. Outputs remain partial: no full N-at-age or F-at-age surfaces or numerical historical uncertainty estimates were recovered. A faithful `fit_tam()` translation and comparison dashboard therefore cannot yet be produced. Continue searching NOAA SASI and linked model/data systems; do not fill these gaps by digitizing charts or borrowing the 2024/2022 numerical model inputs.

Sources:

- [NOAA Stock Assessment Information System](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php)
- [September 2026 peer-review panel report](https://www.fisheries.noaa.gov/s3/fileserve?filepath=2026-10/september-2026-management-track-peer-review-panel-report_20261007.pdf)
- [2026 NOAA assessment bundle](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=2&review_type_id=6&filename=2026_HAD_GOM.zip)
- [2024 Gulf of Maine haddock assessment report](https://d23h0vhsm26o6d.cloudfront.net/a.iv_Gulf_of_Maine_haddock_Update_2024_09_03_193406.805521.pdf)
- [2024 September Management Track peer-review panel report](https://www.fisheries.noaa.gov/s3/2024-10/2024-Management-Track-Peer-Review-Panel-Report_10_8_24_508.pdf)
