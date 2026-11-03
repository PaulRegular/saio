# Barents Sea capelin: current JRN-AFWG assessment

The official JRN-AFWG 2026 report explains that Barents Sea capelin advice has been conducted outside ICES since 2022, and that this work should not be treated as ICES advice. The ICES Stock Information Database snapshot contains `cap.27.1-2` with an assessment year of 2021. That catalogue entry is a discovery key, not the current assessment authority or run. Since 2022, Barents Sea capelin assessment and advice have been conducted by the bilateral Joint Norwegian-Russian Arctic Fisheries Working Group (JRN-AFWG). The latest assessment located is the 2026 JRN-AFWG report supporting 2027 advice.

## Recoverable age information

The 2026 assessment reports acoustic stock numbers by age group (billions), total stock biomass and maturing biomass (thousand tonnes) at 1 October in Table 10.3. Table 10.4 gives CVs for age-specific acoustic estimates for 2004–2026. The 2026 survey estimate covers age groups 1–3; the historical table also has ages 4–5. These are estimated outputs from StoX, not a recovered set of raw survey likelihood inputs. The report notes that 2022 coverage was incomplete and the estimate is not adjusted for that coverage. Age-specific CVs are unavailable for some years and age groups.

The pinned IMRpelagic/bifrost source archive provides seasonal catch-at-age for ages 1–5, in million tonnes, through 2019. Its acoustic `cap` dataset provides abundance by length group and age, mean weight in grams, mean length in centimetres and biomass through 2019. Its dictionary labels these fields `sum(10e9)`, `meanweight(g)`, `meanlength(cm)` and `biomass(10e3t)`; the age-5 group is open (age 5 and older). The maturity initial-parameter dataset covers 1972–2018 and age groups 2–3 and 3–4; these are initial parameters for a maturation model, not direct annual maturity-at-age observations.

## Remaining gaps and screen decision

The current report records only 5 tonnes of 2026 catch, all Russian bycatch, without age composition. The reviewed public Bifrost data stop before the latest assessment years. The 2026 report includes a weight-at-age figure but no numeric table. Current-run catch-at-age, numeric biological surfaces and the underlying age-specific survey inputs have not been recovered. The forecast also uses survey mortality and cod-predation inputs, with SSB projected from 1 October to 1 April; a precise fractional-year survey timing is not stated.

The candidate is therefore **screened, with eligibility unresolved**. The age-specific acoustic outputs make it a strong source-recovery lead, but the available sources do not yet support a complete run-matched age-structured input set. No canonical stock, assessment, input or output rows have been added. Do not label this as an ICES advice assessment or treat the 2021 SID assessment year as current.

## Sources cached locally

The ignored local cache is `source_cache/discovery_ices_barents_capelin_2026/`. Its `sources.csv` records retrieval date, URLs, revision, byte size and SHA-256 checksums for:

- the 2026 JRN-AFWG overview, assessment page and 2027 advice page;
- the 2023 ICES WKCAPELIN benchmark report;
- the IMRpelagic/bifrost source archive pinned at commit `4d4a30aa35db71e0bc3a9ad819ac3a89ad7b189f`.

The Bifrost documentation describes acoustic data processed through StoX and the example `cap` series through 2019. The package's catch data documentation defines catch units as million tonnes.
