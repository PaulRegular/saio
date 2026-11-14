# Yellowtail flounder, NAFO Division 4T, 2021 assessment to 2020

## Assessment identity

This is a historical full assessment of the same NAFO Division 4T stock unit represented by `dfo_yellowtail_flounder_4t`. DFO identifies the last full assessment as February 2021, using data through 2020. Its detailed companion is Research Document 2022/041, published in June 2022. The 2025 assessment remains the current assessment record and is not replaced by this historical record.

## Source-native numerical inputs recovered

Research Document 2022/041 reports:

- Annual recorded Yellowtail Flounder landings for 1985-2020 in tonnes (Table 2). The table separately lists unspecified flatfish; those values are not included as Yellowtail Flounder catch.
- September research vessel survey biomass indices by length group for 1985-2020: less than 25 cm and at least 25 cm, in kg per tow (Table 8).

The input database contains the 36 annual landings values and 72 length-group index values transcribed from those tables. The report also provides whole-area and Magdalen Islands abundance indices in numbers per tow; these companion series are not represented as likelihood inputs here.

The assessment used annual catch proportions by length group, mean weights by length group for fishery and survey, mean weight-at-age and maturity-at-age. The report identifies these input types but the numerical annual arrays were not recovered from the reviewed tables. No age compositions, weights or maturity observations are reconstructed or inferred. Commercial catch-at-length arrays are shown graphically rather than in a numerical table and are not digitized. The 2019 and 2020 landings are marked preliminary.

## Model assumptions documented by the report

The assessment used a length-based age-structured population model for ages 1-8+ and years 1985-2020. Ages 1-3 were mapped to the less-than-25-cm length group, ages 5+ to the at-least-25-cm group, and age 4 was split evenly.

Recruitment was age 1 with annual log-scale deviations having SD 0.2. Fishing selectivity was logistic and changed across 1985-2008, 2009-2012 and 2013-2020. Natural mortality was estimated for age groups 1-3 and 5+ in six six-year periods; age-4 mortality was their average. Survey catchability had logistic age selectivity and an informative log-q prior with mean -0.3566 and SD 0.15. The initial M priors were 0.8 (SD 0.05) for ages 1-3 and 0.3 (SD 0.025) for ages 5+.

The reported likelihood weights were 1.5 for the small-fish index, 1.65 for the large-fish index and 0.85 for fishery catch proportions. The report says the model used penalized maximum likelihood and 5,000 retained MCMC samples for uncertainty.

## Reported outputs

The report gives text summaries rather than numerical annual output tables. The database records only explicit summaries:

- Approximate median abundance in 2020: 520 million fish ages 1-3 and 3 million fish ages 6+.
- Approximate median abundance of ages 4-5: about 95 million in both 2019 and 2020.
- Median >=25-cm biomass in 2020: 2,230 t, adjusted to mid-September.
- The >=25-cm biomass was 39% of its limit reference point in 2020.
- The source gives Bmsy proxy, upper stock reference and limit reference point estimates with stated 95% intervals.

The abundance group summaries are approximate prose values and do not have numeric uncertainty intervals in that prose. SSB is described as averaging 26 kt in 2017-2020, not as a single annual estimate, so no annual SSB is entered. Recruitment and F/M trajectories appear in figures and are not transcribed as annual point estimates. Numerical input and output completeness therefore remains partial.

## Sources

- DFO. 2021. *Stock Assessment of Yellowtail Flounder (Limanda ferruginea) of the southern Gulf of St. Lawrence (NAFO Div. 4T) to 2020*. Science Advisory Report 2021/022.
- Rolland, N., Swain, D., and Ricard, D. 2022. *The Status of Yellowtail Flounder (Limanda ferruginea) in NAFO Division 4T to 2020*. Research Document 2022/041.
