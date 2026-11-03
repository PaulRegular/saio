# Southern Norwegian coastal cod, 2026

## Identity and official assessment

ICES `cod.27.2.coastS` covers the Norwegian coast between 62°N and 67°N.
The 2021 coastal-cod benchmark split the earlier combined coastal-cod unit
into northern and southern stocks. The northern stock and historical composite
catalogue entry are separate records; do not pool their inputs or outputs.

The 2024 WKBMSYSPiCT3 benchmark introduced a SPiCT surplus-production
assessment. The 2026 Arctic Fisheries Working Group (AFWG) updated it using
data through 2025, and the [2026 advice record](https://asd.ices.dk/viewAdvice/7204)
is marked Valid. Its current catch advice for 2027 is 3,472 tonnes. The
2025 advice for 2026 was 1,119 tonnes; AFWG recalculated a 2,349-tonne
reference for comparing advice changes after correcting the harvest-control
rule. That recalculation is not a new historical assessment input.

## Inputs and assumptions

The final 2026 SPiCT fit uses annual combined commercial and recreational
catch in 1977–2025 and two indices of biomass of coastal cod at least 50 cm:
the coastal acoustic-trawl survey's **trawl** index (2003–2025) and the
shallow net survey index (2013–2025). The separate acoustic index used at
the 2024 benchmark was removed from the 2026 fit. The trawl survey is in
quarter 4; exact within-year timing for either index was not recovered.

AFWG Tables 2.3.1, 2.3.2 and 2.3.4 also give commercial and total catch
numbers-at-age and commercial catch weights for ages 2–10+ in 1994–2025.
Recreational catches at age assume the commercial age proportions. These
age tables are useful supporting data, not independent observations in the
aggregate SPiCT likelihood. The annual total catch series and its components
are likewise overlapping records and must not be counted twice. Reported
rounded totals are used for 1994–2025; earlier totals are reconstructed by
adding the two published components. Recreational catch is highly uncertain
and accounts for approximately 69% of estimated total catch in 2025.
AFWG also reports replacing an implausibly low 2001 coastal-cod share in the
commercial catch with an average based on 2000 and 2002; the published
series includes that source adjustment.

The index tables provide estimates, 95% intervals and log-scale SEs. The
intervals are retained in observation notes and the SEs as separate
`log_index_sd` rows; these are not natural-scale SEs. AFWG reports that the
mean shallow-net log SE of 0.12 is used as the observation-error prior mean,
and cautions that smoothing may make it too low. Annual index SEs should not
be assumed to be directly fixed likelihood SDs. The complete 2026 native
model and prior configuration remain unavailable. The cached 2024 benchmark
describes the original priors but its three-index specification must not be
substituted for the 2026 run.

## Outputs and translation

AFWG Table 2.3.7 supplies B/Bmsy and F/Fmsy for 1977–2025 with 95% limits;
these relative quantities must not be interpreted as absolute SSB or
instantaneous F. The precise point-estimate convention for these reported
values has not been verified. The report also gives estimated MSY and its 95% interval.
The 2026 forecast is kept out of historical outputs. The official fit does
not estimate population N or F at age or recruitment. While age-specific
catch information exists, an age-structured tinyAM fit would be a new model
rather than a translation of the official SPiCT assessment, and no matching
official age-specific outputs are available for comparison. No tinyAM fit or
comparison dashboard is claimed for this assessment.

The AFWG report, extracted text, SAG XML and 2024 benchmark report are cached
locally under `source_cache/ck_ices_afwg_morhua_coastnor_1_2/assessment_2026/`
with their source URLs and checksums. Source completeness is partial: the
native production run, full priors, exact timing and recreational catch
estimation details remain unresolved.

## Sources

- [AFWG 2026 report](https://doi.org/10.17895/ices.pub.32134696.v1), sections 2.1 and 2.3; Tables 2.3.1–2.3.7.
- [ICES 2026 advice](https://asd.ices.dk/viewAdvice/7204) and [SAG XML, key 23775](https://sag.ices.dk/SAG_API/StockXmlDownload/23775).
- [WKBMSYSPiCT3 2024 benchmark](https://doi.org/10.17895/ices.pub.24998858), section 4.
- [WKBARFAR 2021 benchmark](https://doi.org/10.17895/ices.pub.7920), stock split.
