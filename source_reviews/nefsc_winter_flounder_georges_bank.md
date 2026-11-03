# Georges Bank winter flounder source review

## Assessments represented

The 2025 Management Track WHAM assessment was accepted as the best scientific
information available for Georges Bank winter flounder. Its report and peer
review provide summary trajectories and reference points, but the recovered
2025 bundle contains no native WHAM fit object or detailed age-specific input
series. The 2022 Management Track VPA remains the most recent assessment with
recoverable detailed model inputs. It is the current detailed record; the
separate 2025 record is not used to fill any gap in the 2022 run.

The 2022 VPA/ADAPT 3.1 run is identified as RunSpring22, with model ID
2022MTassessmet, years 1982-2021, ages 1-6 and 7+, and fully selected F
reported over ages 4-6. The 2025 assessment updates a 2024 WHAM research-track
model and reports through 2024, with FFull over ages 4-7. Its age grid and
numerical input data were not recovered.

## 2022 input extraction

The native 2022_WFL_GB_VPA.dat file supplies 40 years of catch-at-age,
catch weights, population weights, maturity, M, and survey index series.

- Catch numbers-at-age are retained in thousand fish for ages 1-6 and the
  age-7 plus group. Annual catch weights are retained separately. Their units
  are not named in the native file; kg per fish is inferred from their scale
  and checked against the report's total catch summaries. No values are
  adjusted to force reconciliation.
- The annual BIOMASS population-weight surface is used as stock
  weight-at-age. The separate SSB matrix is numerically identical and is not
  duplicated. Both are distinct from the WEIGHT AT AGE catch-weight matrix.
- M is fixed at 0.3 per year at all ages and years. Maturity-at-age is stored
  annually as proportions.
- The 21 survey columns map to NEFSC spring (US_Sp), DFO spring (Can_Sp),
  and age-specific NEFSC fall streams (US_A0 to US_A6). The native file
  labels each series NUMBER and 1-JAN; values are stored without a
  multiplier because the index scale is not specified. 1-JAN is preserved
  as sampling time 0.0. Native stream labels remain in observation_id.
- The data file encodes zero index cells as numeric 0 but has no separate
  missingness flag. Those values remain 0 in the canonical database. The
  tinyAM recipe omits zero index cells from its lognormal likelihood because
  the source does not establish whether each cell is a true zero or a missing
  observation.
- The VPA control vector PARTIAL RECRUIT and MFSPAWN pair are retained as
  assumptions. The released files do not resolve how every control value maps
  to tinyAM's model inputs. Survey weight factors are all one.

The source report notes that Canadian bottom-trawl discards were unavailable,
Canadian scallop-dredge discard precision was uncertain, and no Canadian age
or length compositions were available. It also notes missing NEFSC spring and
fall surveys in 2020 and unavailable DFO data for the terminal year. Some
historical gaps were filled through expert decisions. The final VPA input file
contains the resulting model input values, but not enough information to
reconstruct those decisions. Inputs, assumptions, and outputs are therefore
marked partial.

## Outputs and run separation

The 2022 report provides SSB, age-1 recruitment, and FFull for 2012-2021,
where FFull covers ages 4-6. It provides 2022-2025 projection catch, SSB and
FFull, reference points, and a 90% interval for projected SSB. Numerical
N-at-age, F-at-age, M-at-age estimates, and historical uncertainty were not
recovered. The 2021 stock-status values adjusted for retrospective bias
(SSB 4,503 mt; FFull 0.076) are kept separate from the unadjusted Table 1
trajectory (SSB 7,159 mt; FFull 0.0485).

The 2025 record preserves its published aggregate catch summary for
2015-2024; SSB, FFull and age-1 recruitment for 2015-2024; reference points;
and projections for 2025-2028. It does not provide recoverable N-at-age,
F-at-age, survey indices or biological input surfaces. These rows are not
mixed with the 2022 VPA input matrices.

## tinyAM translation

The recipe fits the detailed 2022 VPA input period, years 1982-2021 and ages
1-7, with age 7 as the plus group. It uses the source catch numbers, annual
weights and maturity, fixed M=0.3, and the three native survey series. tinyAM
uses an IID abundance process, an AR1 F process, survey- and age-specific q,
and a shared catch observation SD. These are documented approximations to the
VPA estimation procedure.

The native MFSPAWN = 0.25 0.25 pair is preserved but not interpreted as a
tinyAM spawning time. The SSB comparison is therefore approximate. Recruitment
uses the same age-1 calendar-year definition. FFull is compared only as an
approximate ages-4-6 metric because official age-specific F values are not
available to rebuild a common weighted average. Fixed M agreement checks the
source input mapping, not estimation.

The first fit used package default initialization with no `start_par`. It
returned optimizer code 1 (false convergence), objective 1618.301, maximum
absolute gradient 0.000215, a successful `sdreport`, and a positive-definite
Hessian; it is not classified as converged. One retry from the first fit's
estimates returned optimizer code 0 (relative convergence), but the Hessian
was not positive definite and fixed-parameter covariance was unavailable.
The default fit is retained for the exploratory dashboard; neither fit passes
the numerical checks. No source observation or model assumption was changed
to improve agreement.

## Sources and cached files

- [2022 Georges Bank winter flounder Management Track assessment](https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf)
- [2025 Georges Bank winter flounder Management Track assessment](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10433)
- [NOAA 2025 September Management Track peer review](https://www.fisheries.noaa.gov/event/peer-review-2025-september-management-track-assessments)
- [2022 native VPA and report bundle](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=10&stock_id=1&review_type_id=2&filename=2022_FLW_GB.zip)
- [2025 assessment bundle](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=10&stock_id=1&review_type_id=3&filename=2025_FLW_GB.zip)

The source files are cached locally under the gitignored
source_cache/ck_nefsc_americanus_5z/. The local
manifest records retrieval date, source URLs, file contents and checksums.

## Additional 2025 historical trajectories

NOAA Stock SMART assessment 14074 provides annual total catch, SSB, fully
selected F at ages 4–7 and age-1 recruitment for 1982–2024. All 2015–2024
values agree with the report table within its rounding. The earlier values are
now in the 2025 record; report values, projections and their uncertainty are
unchanged. F is rounded to three decimal places to remove binary storage noise;
no uncertainty is inferred. The 2025 age-specific inputs and fitted age
surfaces remain unavailable, so the existing 2022 translation is unaffected.

The [NOAA Stock SMART snapshot](https://github.com/NOAA-EDAB/stocksmart/tree/664c4237e26520b260a090e1821a2cee5d1cdf07)
is cached locally under `source_cache/ck_nefsc_americanus_5z/` with revision
and checksum in `stocksmart_manifest.csv`.
