# Georges Bank cod: US 2024 management-track assessment

## Stock and official run

The starting catalogue row is `NEFSC-GARMIII_morhua_GB`, retained under
`ck_nefsc_garmiii_morhua_gb`. The 2023 research track changed the stock
definition, including exclusion of statistical areas 521 and 526, and
established separate Southern New England and eastern/western Gulf of Maine
units. The new `nefsc_cod_georges_bank` row represents that revised GB unit;
it does not inherit the historical wider unit's Master identifier.

`nefsc_cod_georges_bank_2024` is the US WHAM management-track assessment,
final **MT run 4**, with data for 1978–2023. The single fishery combines US
and Canadian catches. It is not the separate Canadian Eastern Georges Bank
assessment already represented in this database, nor the older GB empirical
PlanBsmooth assessment or rejected 2015 analytical model.

The report is watermarked as a working paper, so publication alone is not
used as evidence of selection. The final June 2024 peer-review report finds
all GB terms of reference met and the assessment suitable for management;
the supplemental report explicitly identifies MT run 4 as final. The Council
subsequently published these materials for its July 2024 SSC meeting.
Current SASINF lists 2024 as the latest GB cod assessment. NOAA's March 2026
announcement schedules the next cod management track for 2027; the earlier
announcement anticipating a June 2026 update is not treated as a new fit.

## Sources and cache

- [Current NOAA support portal](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php),
  Atlantic cod / Georges Bank / 2024 / Level 3 Enhanced Review. The older
  `/saw/sasi/sasi_report_options.php` address returns 404; it is not evidence
  that all support materials are unavailable.
- [Assessment report](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=4&stock_id=1&review_type_id=3&info_type_id=-1&filename=2024_COD_GB_Report.pdf)
  and its background/presentation, from the same portal record.
- [Final June 2024 peer review](https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf).
- [2023 research-track peer review](https://www.fisheries.noaa.gov/s3/2023-08/PanelSummaryReportoftheAtlanticCodRTPeerReviewAugust172023-mlt-508-8-23-23ajd-508gw.pdf),
  especially pp. 12–14 and 19; the current presentation confirms retained M.
- [2027 management-track announcement](https://content.govdelivery.com/accounts/USNOAAFISHERIES/bulletins/40cd54f).
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/) and the
  [NOAA-EDAB stocksmart data package](https://noaa-edab.github.io/stocksmart/).
  The cached stock_assessment_data.rda is pinned to commit
  664c4237e26520b260a090e1821a2cee5d1cdf07; the package documents a 2026-10-03
  data pull. It identifies the 2024 operational Georges Bank cod series as
  stock 10509 / assessment 13596 and is a processed extraction from the portal,
  not the native fitted WHAM object.

Original PDFs and current portal results are cached under
`source_cache/ck_nefsc_garmiii_morhua_gb_2024/`, with URLs, verification dates
and SHA-256 checksums. Fresh downloads of the current report and background
match the previously cached originals. The portal's complete current listing
has the report, background, discard tracker and presentation PDFs; its ZIP
contains those same four documents, not a fitted model. Public code searches
did not recover matching production arrays or a fitted WHAM object. This
documents a recovery gap, not a claim that those files do not exist.

## Inputs and assumptions recovered

`scripts/database/158_import_nefsc_cod_georges_bank_2024.R` imports Table 1's
2014–2023 combined catch in tonnes and the documented fixed M of 0.29 per
year for ages 1–9+. The presentation explicitly says the MT retains this
M assumption. It is not the older catalogue M value or an estimated-M output.
Rounded catch totals are kept as reported rather than recomputed from the
rounded US/Canadian components. Gear splits are not extra fitted fleets.

The native observation structure is total catch and Dirichlet-multinomial
age compositions, plus DFO spring, NEFSC spring and NEFSC fall surveys.
The DFO 2022 survey and NEFSC spring 2023 survey are missing. US fishery ages
are unavailable in 2022–2023, when the model uses Canadian composition.
None of these gaps is filled with zero or source fitted states.

The current assessment recalibrates the NEFSC survey series and CVs for gear
and Albatross/Bigelow vessel changes. It corrects Canadian fish versus
thousand-fish units before numbers-weighting fishery weights, incorporates
revised Canadian catch ages and uses Canadian weights in terminal gaps.
Maturity comes from an updated state-space model. Older original-looking
arrays would therefore require explicit verification against this vintage.
Numerical current catch/survey ages, weights, maturity, exact timing and
observation precision inputs remain unrecovered from the tables and public
files reviewed here.

Initial N-at-age is estimated independently. Recruitment is decoupled from
the older-age two-dimensional AR1 survival process, using the corrected
recruitment-correlation implementation. The RT IID formulation is not the
current model. Final MT run 4 switches off WHAM's lognormal adjustments.
Exact parameter phases and variance-sharing keys remain unresolved without
the production configuration.

The final model fixes NEFSC fall selectivity to one for ages 1–3 to achieve
convergence. The final panel explicitly flags this unusual full selection
of young fish for future investigation. It is a source-model feature, not
a reason to assume a monotone survey curve in a future translation.

## Outputs and uncertainty

Table 1 supplies ten years of SSB in tonnes, age-1 recruitment in thousand
fish, and fully selected F for ages 9+. The 2023 values are SSB 2668 t,
recruitment 605 thousand and F9+=0.13 per year. F9+ is not abundance-weighted
Fbar; no younger-age F values are invented. Only this reported age group
is retained in the mortality surface.

The report's approximate 90% **joint** SSB/F region has axis bounds
1528–4660 t and 0.073–0.233 per year. These remain explicit context in
notes; they are not converted into marginal 95% confidence limits or SEs.
The source applies no retrospective adjustment, so rho-adjusted points are
not substituted. Forecasts for 2024–2027 and reference-point uncertainty
are not mixed into the historical state series.

NOAA Stock SMART supplies 1978-2023 series for SSB, age-1 recruitment and
fully selected F. The 1978-2013 segment adds 36 historical annual values per
metric; the source units are Metric Tons, Thousand Recruits and Fully-selected F.
The 2014-2023 overlap matches Table 1 exactly for SSB and recruitment,
and to its three-decimal precision for F. The reported F series is for ages
9+, as specified in Table 1. Stock SMART provides no uncertainty for these
series; they are published assessment time series, not fitted state arrays.
No total abundance, N-at-age or age-specific F surface is available, and no
common-definition SSB is derived. Input, assumption and output completeness
remain partial.

## Translation status

The record does not support a defensible tinyAM fit yet: original catch and
survey age arrays, biological matrices and timing are missing. A catch total
and a known M do not replace those observations. No model is fitted and no
source-based starting values are generated while these gaps persist.
