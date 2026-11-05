# Chatham Rise ling (LIN 3&4), 2025 assessment

## Assessment and sources

Fisheries New Zealand's 2025 LIN 3&4 assessment is the latest detailed assessment located for the Chatham Rise stock. It was used for 2025 advice and was published as FAR 2025/48. The companion FAR 2025/47 describes the fishery and supporting data. The 2025 Fisheries Assessment Plenary, volume 2, provides an official cross-check of the assessment's assumptions and results.

The assessment is a two-sex, single-area Casal2 age-structured model. It uses ages 3–25, with age 25 as a plus group. The model input files are reproduced in Appendix A of FAR 2025/48. Their parameter, observation, and population settings were retained as assumptions; the source's observation tables were imported in their native likelihood forms.

The three reports are cached under the ignored `source_cache/mpi_ling_lin34_2025/` directory. Retrieval dates, URLs, and SHA-256 checksums are recorded in `provenance/mpi_ling_lin34_2025_sources.csv`.

## Inputs recorded

- **Fishery catches:** 162 catch-biomass rows for trawl, longline, and pot fisheries from 1972–2025, in tonnes. The source input table has zeroes before each fishery's reported start (trawl 1973, longline 1975, pot 2000). The 2025 catch values are the 2022–2024 average and are not observed catches.
- **Tangaroa survey:** 28 January biomass observations and paired CVs from 1992–2014, 2016, 2018, 2020, 2022, and 2024. Biomass is in tonnes; CVs are stored as ratios. The survey is placed at 0.2 of the calendar year and has a separately specified process error.
- **Age compositions:** 28 sex-specific survey samples, 31 combined-sex trawl samples, and 17 combined-sex longline samples. The 2,296 cells retain the source age proportions, ages, sex treatment, and raw sample sizes. The model's separate error-value multipliers are retained as assumptions. These data are composition observations, not direct catch numbers-at-age or age-specific abundance indices.
- **Maturity:** 26 values preserve the base model's male and female Horn (2005) ogives for ages 3–14 and the 15+ group. The age-7 ogive considered in the maturity sensitivity is not mixed into the base assessment.
- **Growth and mortality:** The model's sex-specific von Bertalanffy and length-weight parameters are retained as assumptions. No separate weight-at-age table was found in the model inputs. Natural mortality is estimated as sex-specific and constant at age; the selected base model's MPD estimates are Mavg = 0.150 yr⁻¹ and Mdiff = −0.007 yr⁻¹. The assessment does not tabulate an annual M-at-age surface.

The 2025 base model uses the Tangaroa biomass series and survey age compositions. Commercial trawl and longline compositions are combined across sexes in the selected base run. Longline CPUE and scampi-target trawl CPUE were explored but not included in that run.

## Outputs recorded

FAR 2025/48 Table 9 reports Bayesian medians and 95% credible intervals for B0 (114,384 t; 103,473–138,315 t), B2025 (66,638 t; 50,671–94,693 t), and B2025/B0 (58.3%; 48.8–68.9%). The reported probabilities that B2025 is above 40% of B0 and below 20% of B0 are also recorded.

Table 10 reports B2030, B2030/B0, B2030/B2025, and the two reference-point probabilities for four catch and recruitment scenarios. Each result is stored with a distinct `scenario` value and the source scenario in its output note. Table 8's selected base-run MPD estimates for Mavg and Mdiff are also retained. No uncertainty interval for those M parameters is tabulated there.

The report shows annual biomass, exploitation, and year-class-strength trajectories as figures, but does not provide numerical annual N-at-age, F-at-age, or M-at-age arrays. Those values have not been digitized from plots.

## Source gaps and status

The official model input appendix provides the native catch, survey, and age-composition inputs used in the base run. It does not provide fishery numbers-at-age or a standalone weight-at-age matrix. The model's sex-specific growth and length-weight functions and its age compositions are preserved instead of adding reconstructed catch numbers or weights.

There is a timing difference within the source report: the commercial age-composition blocks in Appendix A.2 specify `time_step S1`, while Table 1 places commercial catch-at-age observations in step 2 (July–December). No within-year sampling fraction is stated for those commercial compositions. The imported inputs preserve the model-file setting and leave `sampling_time` blank; the discrepancy remains unresolved.

The canonical assessment is marked `assumptions_status = complete`, `inputs_status = complete`, and `outputs_status = partial`. The output status is partial because the detailed report does not tabulate annual age-specific population and mortality estimates.
