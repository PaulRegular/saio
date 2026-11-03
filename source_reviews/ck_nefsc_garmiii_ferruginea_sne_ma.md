# Southern New England/Mid-Atlantic yellowtail flounder

## Source identification

Stock `ck_nefsc_garmiii_ferruginea_sne_ma` (*Limanda ferruginea*) preserves
Charbonneau–Keith `NEFSC-GARMIII_ferruginea_SNE, MA` and its original source
label `SNE MA Limada ferrugina.pdf`. It is distinct from Georges Bank and
Cape Cod/Gulf of Maine yellowtail flounder.

The database separates two partial records:

- **`nefsc_yellowtail_snema_2024_framework`**: the detailed research-track
  framework selected in November 2024, through 2022. It remains the current
  detailed record because the 2025 update does not expose the complete input
  arrays, biological surfaces, or fitted age-specific outputs needed to
  replace it. The 2024 framework was selected for subsequent management use;
  it was not the advice run used in 2024.
- **`nefsc_yellowtail_snema_2025`**: the applied management-track update through
  2024. The final September 2025 peer-review panel found that it met all TORs
  and represented the best scientific information available (BSIA); the April
  2026 Framework 72 submission also confirms its application. The updated
  assessment report retains a draft watermark, so that provenance is noted.
  Its summary values and reference points are kept separate from the 2024
  framework.

The final panel selected the **revised age-specific-M model**, replacing the
original candidate's constant M = 0.5. The previous stock review described
that constant-M candidate as final; this import corrects the distinction.
The panel reports other inputs and settings unchanged for the M comparison.
Original candidate annual estimates are not imported as revised-run outputs.

The framework uses one combined landings/dead-discards fleet, 1973–2022,
ages 1–6+, combined sexes and three NEFSC trawl surveys: spring, fall and
winter. Larval indices were considered and excluded. Older-cohort N has
two-dimensional AR1 process error. Recruitment is decoupled, with temporal
AR1 variation and a controlling effect of one-year-lagged Gulf Stream Index
(GSI), itself modelled as AR1. It is not Beverton–Holt recruitment. Fleet
selectivity is logistic with IID random effects; spring/winter survey
selectivity is logistic and fall selectivity age-specific. Survey q has no
random effects. Age compositions use logistic-normal AR1 `miss0`, which
treats composition zeros as missing within that likelihood.

The 2025 update **removed fleet-selectivity IID random effects** to address
convergence problems, switched the WHAM lognormal adjustment off, and revised
CAMS discards, maturity and GSI. Its terminal five years have no catch age
composition information. Although the report says age-specific M was
retained, it does not restate the numeric vector; the 2024 values are not
copied into the 2025 record without confirmation. Other earlier arrays and
settings are not attached to it.

For the 2024 framework, Alade and Hansell recommend using a time-series mean
of female proportion-at-age for SNEMA because of limited sample sizes. Their
Figure 7 displays seven-year moving-window values for 1970–2022; it is a
descriptive analysis, not the fixed vector used by the selected model. The
accessible source does not tabulate that numeric vector, so it is not
digitized. The maturity form is now documented, while the exact vector and
annual model weights remain missing.

## Canonical coverage

`scripts/database/148_import_nefsc_snema_yellowtail.R` adds 2,152 inputs,
21 assumptions and 37 outputs across the two records. All three completeness
statuses remain **partial** for both records.

| Source | Recovered values | Qualification |
|---|---|---|
| 2024 Table 2.8.3 | Combined catch-at-age, 1973–2022, ages 1–6+, thousand fish | 2020–2022 dashes remain missing; source numbers support composition alongside a fleet total |
| 2024 revised-candidate slide 59 and Cadrin Table 3 | Fixed M-at-age for ages 1–6+: 0.97, 0.45, 0.37, 0.34, 0.33, 0.33 per year | Slide 59 identifies the values as the selected age-based candidate and states lifetime M=0.5 for SNEMA. Cadrin Table 3's caption says 0.4, while its text says 0.5 for SNEMA; the contemporaneous slide resolves the stock-specific scalar and confirms the applied vector. Age 6 is the model's 6+ group; ages 6 and 7 share 0.33. |
| Alade and Hansell maturity working paper, pp. 1–2, Figure 7 | Static time-series mean of female proportion-at-age recommended for SNEMA | The figure shows a seven-year moving window rather than the fixed model vector; exact numerical ages 1–6+ values are unavailable and are not reconstructed. |
| Tables 3.6.2a–b | Spring stratified means, 1968–2022 excluding 2020, ages 0–11, fish/tow | Preserve actual rows and fine ages; caption incorrectly starts at 1970 |
| Table 3.6.3 | Fall stratified means, 1963–2022 excluding 2017/2020, ages 1–10, fish/tow | Retain incomplete-age-key flags on seven 2013 cells; caption understates coverage |
| Table 3.6.4 | Winter stratified means, 1992–2007, ages 1–8, fish/tow | Retain source ages without pooling |
| Table 3.6.1 | Spring/fall aggregate abundance and biomass, fish/tow and kg/tow, plus CVs | Alternative representations, not duplicate independent observations; exact fitted aggregate basis unresolved |
| Final panel Table 5.5 | Revised-run F40%, SSB40% and equilibrium yield at F40%, with bounds | Reference points, not annual estimates; interval level/construction unspecified in that table |
| 2025 Table 1 | Combined landings and dead-discard catch, 2015–2024, tonnes | Retain the reported total rather than inferring unrounded components |
| 2025 Table 1 | Native SSB, age-1 recruitment and fully selected F, 2015–2024 | SSB in tonnes, R in thousand fish; Ffull ages 5–6+ is not population-weighted Fbar |
| 2025 Table 2 | F40% proxy, SSBMSY proxy, MSY and mean age-1 recruitment | F, SSB and MSY have reported 95% lognormal confidence intervals; these are management-track reference points, not annual estimates |

No annual N, F-at-age or estimated M surfaces are invented from figures.
Table 1 does not provide numerical SEs or marginal intervals for historical
summary estimates. The report gives an approximate joint 90% confidence
region for terminal SSB and fully selected F (19–78 tonnes and 0.026–0.099,
respectively); because it is a joint region, those endpoints are documented
but not entered as marginal output bounds. Forecasts through 2028 are
identified in metadata but are not imported as historical observations or
estimates. Fixed source M is not an estimated M output.

## Source consistency and missing values

Four differences between age sums and published aggregate number indices
exceed the bound from rounding every cell to three decimals: spring 2012,
2015 and 2017 age sums are lower by 0.016, 0.007 and 0.012 fish/tow; fall 2013
is lower by 0.008 fish/tow. The cause is unresolved. Both representations
remain unchanged; no rescaling forces equality.

Spring 2020 prints an aggregate zero without a CV, although coverage was
incomplete and no age row is supplied. Retain it as printed, not as a
certified fitted zero observation. Fall 2017/2020 are missing. Missing CVs,
missing catch ages and source zeros remain distinct. CVs stay as ratios for
their corresponding abundance/biomass indices; they are not SEs or silently
supplied fixed likelihood SDs. Separate `abundance_index_cv` and
`biomass_index_cv` measures distinguish these two precision records without
inventing a second survey. Model sampling fractions were not recovered:
seasons are retained and `sampling_time` stays blank.

## Source cache and validation

Sources remain under `source_cache/ck_nefsc_garmiii_ferruginea_sne_ma/`.
Manifests retain SASI URLs, retrieval dates, checksums, represented run and
verification date. The 2024 and 2025 peer-review reports, SNEMA TOR
presentation and Framework 72 PDFs are cached locally. The importer pins PDF
hashes; important table pages were visually checked.

The nested 2024 `SNEMA_Runs.zip` has 259 entries: original/revised-model plot
directories and self-test PDFs, without numerical production arrays or a fit.
The valid 2025 comparison workbook documents settings, not fitted time series.
An earlier HTML response bearing an Excel filename is not used as a workbook.
WHAM tutorial and research-candidate data are not production substitutes.

The focused test checks run separation, years/ages, off-diagonal values, units,
missingness, flags, aggregate discrepancies, CV meaning, reference-point
bounds, every historical summary value and absence of manufactured biology
or fitted age surfaces. Reference conversion must not treat Ffull as Fbar.

## Remaining requirements for translation

1. Complete annual model weights and the exact numeric fixed maturity vector.
   The recommended static maturity form and fixed age-specific M vector are
   now documented, but the maturity paper does not supply the selected numeric
   vector or missing annual model biology.
2. Exact aggregate fleet/survey inputs, fitted age cells, composition weights,
   survey sampling fractions and observation-variance settings.
3. Selected GSI observations, scaling and recruitment configuration, initial
   states, bias corrections and pinned WHAM version. Production parameter
   activation remains unresolved.
4. Numerical fitted N/F and available uncertainty for the selected run. The
   2025 summary cannot be combined with the changed 2024 observations/settings.

These are source-data gaps. Independent age-index likelihoods would also
approximate aggregate/composition likelihoods. A GSI-linked recruitment
translation needs a documented mapping after its inputs are recovered.
The partial import is not a completed translation: no fit or dashboard is
claimed, and preparation remains unavailable without the missing inputs.

## Sources

- [2024 Yellowtail Flounder Research Track report and SASI files](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php?year=2024&species_id=13&stock_id=11&review_type_id=5)
- [2025 SNE/MA Management Track SASI files](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php?year=2025&species_id=13&stock_id=5&review_type_id=2)
- [2025 Management Track report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10439)
- [Final September 2025 Management Track peer-review panel report](https://www.fisheries.noaa.gov/s3/2025-11/September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf), pp. 12–13
- [Final November 2024 peer review](https://d23h0vhsm26o6d.cloudfront.net/10b.-Panel-Summary-Report_Yellowtail-Flounder_508_final_12_12_2024.pdf), pp. 17–24 and Table 5.5.
- [Final Framework 72 submission, April 2026](https://d23h0vhsm26o6d.cloudfront.net/260423_Groundfish_FW72_SIR_FINAL-Submission.pdf), p. 27, confirms the applied 2025 update.
