# Scup (US Atlantic)

## Assessment selection

The latest official assessment is the 2025 Scup Management Track Assessment, based on ASAP run26 and data through 2024. Its assessment report is marked as a draft working paper for peer review, while the 2025 peer-review panel report states that the assessment met its terms of reference and represented best available science. The annual table reports unadjusted model estimates; the narrative separately reports rho-adjusted 2024 SSB and F. These are stored as separate assessment outputs.

The latest assessment with detailed source tables recovered for the canonical database is the 2015 SAW 60 benchmark, final run S60_BASE_18. It was recommended for status evaluation by the SARC. The 2025 update is recorded separately and does not replace the 2015 detailed record.

## Sources and cached files

- 2015 SAW 60 report, NEFSC Reference Document 15-08: <https://repository.library.noaa.gov/view/noaa/4975>; DOI <https://doi.org/10.7289/V5W37T9T>.
- 2025 Management Track report: <https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=28&stock_id=6&review_type_id=2&info_type_id=-1&map_type_id=&filename=2025_SCUP_UNIT_REPORT_2025-06-20.pdf>.
- 2025 peer-review panel report: <https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf>.
- 2023 update materials were reviewed as an intermediate assessment and do not supersede the 2025 update or the 2015 detailed record.

The reports and NOAA SASI bundles are cached locally under the gitignored `source_cache/nefsc_scup_2015/` and `source_cache/nefsc_scup_2025/` folders. The local `source_cache/nefsc_scup_source_manifest.json` records assessment/run identities, retrieval dates and SHA-256 checksums. Direct attachment URLs for the 2023 and 2025 bundles were not retained; their extracted documents are attributed to the NOAA SASI bundles, and this gap is explicit in the manifest.

## 2015 run structure and imported records

Run S60_BASE_18 modeled 1963–2014 with four fishery fleets. The model assumed M = 0.20 for all ages and years. Its modeled age groups were true ages 0–7+, and recruitment was at age 0. The report's fishery catch-at-age tables give finer source ages 0–10 for 1984–2014; those raw ages are retained separately. The eventual translation must sum source ages 7–10 to the model's 7+ group. Tables A22 and A25 supply annual fleet catch biomass; only the non-overlapping Table A25 period 1963–1980 is imported alongside Table A22 for 1981–2014. Early Table A25 DWF landings and combined recreational catch remain separately identified because their mapping to the four later fleet series is not established.

The database contains the four reported catch-at-age series (Tables A13, A16, A18 and A20), the available fleet catch biomass (Tables A22 and A25), annual catch-weighted weight-at-age (Table A24), the MAT3 maturity schedule, fixed M = 0.20 at ages 0-7+, N-at-age (Table A56), F-at-age (Table A57), SSB and age-0 recruitment (Table A55). The 2014 SSB and F 90% MCMC probability intervals are entered only where the report gives them. The report's age-specific outputs use a 7+ plus group. The 2015 report's explicit fixed maturity schedule for pre-1981 years is recorded as a reconstructed source input and labeled accordingly.

Table A32 adds the NEFSC fall survey stratified mean numbers per tow at ages 0-8 for 1984-2014. The two-page table was recovered using the PDF's column positions because plain-text extraction drops blank age columns. Blank cells were recorded as zero; the age values reproduce each annual total within 0.05 fish per tow, allowing for printed rounding. Age 8 remains a source age and must be combined with age 7 when translating to the model's 7+ group. The report says HBB index lengths were calibrated to ALB equivalents from 2009 onward. The official report describes fall sampling in September-November; the tinyAM approximation uses 0.8 as the seasonal midpoint.

The final run omitted NEFSC spring, MADMF spring, RIDFW spring and fall, and VIMS ChesMMAP indices. Table A32 supplies one active NEFSC fall age-index series, but the remaining active survey streams, their aggregate indices and CV adjustments, and complete ASAP control settings have not yet been imported. Consequently the 2015 record remains partial for assumptions, inputs and outputs. No native S60_BASE_18 data/model archive was found in the available NOAA and SASI materials.

## 2025 update

The 2025 report provides four fleet catch totals and unadjusted SSB, Ffull at source age 4, and age-0 recruitment for 2015–2024. It also reports rho-adjusted 2024 SSB of 235,613 mt and Ffull of 0.098, distinct from unadjusted Table 1 values of 163,470 mt and 0.167. The 2024 unadjusted values have approximate 90% intervals of 142,932–194,496 mt for SSB and 0.125–0.226 for F. The 2025 output record remains partial because age-specific estimates, full input series and model control details are not present in the downloaded bundle.

The 2025 assessment reports a seven-year Mohn's rho of -0.31 for SSB and 0.70 for F, with the rho-adjusted terminal estimates outside the stated 90% confidence regions. This is a material comparison limitation: any later dashboard must show the unadjusted annual series and label the adjusted terminal values separately.

## Additional 2025 historical series

NOAA Stock SMART assessment 13935 provides total catch, recruitment, SSB and
fully selected F for 1984–2024. The 2015–2024 catch and recruitment values
agree with the assessment report; 1984–2014 values are now in the database.
Catch is an aggregate and must not be combined with overlapping fleet values.

Stock SMART labels its biomass and F series retrospectively adjusted, yet
2015–2023 values agree with the report's unadjusted table while its 2024 values
match the adjusted terminal estimates. The 1984–2014 archive values are stored
as `stocksmart_reported_SSB` and `stocksmart_reported_Ffull`, separate from
the unadjusted assessment series, until their historical adjustment convention
can be verified. F is rounded to three decimals to remove binary storage
noise; no uncertainty is inferred. These values do not supply missing 2025
age compositions or model controls.

The [NOAA archive snapshot](https://github.com/NOAA-EDAB/stocksmart/tree/664c4237e26520b260a090e1821a2cee5d1cdf07)
is cached in `source_cache/nefsc_scup_2025/` with its revision and checksum in
`stocksmart_manifest.csv`.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/ck_nefsc_saw_chrysops_usatl.md). They do not determine source completeness or official run selection.
