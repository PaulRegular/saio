# Southern blue whiting, Campbell Island Rise (SBW 6I) — 2024 assessment

## Stock unit and assessment run

Fisheries New Zealand assesses the four New Zealand southern blue whiting spawning areas separately. SBW 6I is the Campbell Island Rise unit; it is not combined with Bounty Platform (SBW 6B), Pukaki Rise (SBW 6R), Auckland Islands Shelf (SBW 6A), or the residual SBW 1 management area.

FAR 2024/37 is the latest detailed full assessment located for SBW 6I. It is the assessment used in the May 2025 Fisheries Assessment Plenary: that Plenary lists the latest assessment publication year as 2024 and the next assessment as 2026. The report fits data through the 2022–23 fishing year (model year 2022). The official FAR 2026/38 report adds 2025 fishery age and length data, but it is a data report rather than a new assessment. FAR 2025/44 is likewise a catch-age data report. Neither is mixed into the 2024 assessment record. No newer full production assessment or native Casal2 run files were located in the reviewed Fisheries New Zealand sources as of 6 November 2026.

The production model is a two-sex, single-stock, single-area Bayesian statistical catch-at-age model implemented in Casal2. It has immature and mature partitions, ages 2–15 with a plus group at age 15, and model years 1960–2022. The Base run starts from an equilibrium age distribution in 1960, estimates year-class strengths for 1960–2021, uses catch history for 1971–2022, and fixes natural mortality at 0.20 per year.

## Numerical assessment inputs recovered

- **Catch biomass:** FAR 2024/37 Table 2 reports 52 estimated catch values for 1971 through 2022–23 in tonnes. The source labels variable fishing periods, including a short 1978 period, 1978–79 to 1997–98, the transitional 1998–2000 period, and 2000–01 onward. The 1971–1977 stock catches are reconstructed using the 0.70 stock share estimated for 1978–2016/17. These values are not catch numbers-at-age.
- **Acoustic indices:** Table 3 reports immature and mature biomass estimates and sampling CVs for 14 RV *Tangaroa* surveys from 1993 to 2022. Units are tonnes. The assessment uses the immature and mature series as relative mid-season biomass indices with lognormal likelihoods; it excludes the juvenile index. The assessment adds separately estimated process error to the sampling CVs. No exact fractional-year observation time is stated.
- **Commercial age compositions:** The production assessment uses proportions-at-age by sex for 1979–2022, excluding 1987, with ages 1–15+ and bootstrap CVs. The proportions and CVs are displayed in figures, not in numerical tables, in FAR 2024/37 and the 2023 input-data review. They are not imported as approximate readings from plots. The report describes multinomial likelihoods and effective sample-size adjustment for process error.
- **Biology:** The assessment uses an empirical, sex-specific length-at-age matrix and fixed sex-specific length-weight relationships: males use `weight = 0.00515 * length^3.092`; females use `weight = 0.00407 * length^3.152`, with length in centimetres and weight in kilograms. A full numeric annual matrix was not found in the reviewed reports. Maturation is represented by sex-specific logistic parameters A50 and Ato95; numeric age-specific maturity values for the Base run are not tabulated.
- **Other specifications:** The model has two annual time steps: November–August with 90% of M, then September–October with the remaining 10%, age advancement, recruitment at age two, spawning, F, and the acoustic observations. Recruitment follows Beverton–Holt with fixed steepness 0.9 and a 0.5 male fraction at age two. Acoustic catchability for mature biomass has a lognormal prior with mean 0.54 and CV 0.44; immature catchability is estimated under a uniform prior. Base-case natural mortality is fixed; the 0.15, 0.25, estimated-M, and time-varying-maturity runs are sensitivities.

The partial database import retains all 52 Table 2 catch biomass entries, both Table 3 acoustic biomass series and their sampling CVs, the reported Base-run assumptions, and the numerical estimates and intervals from Tables 8–10. Catch rows use the first four-digit year in the printed fishing-period label as the model-year index and preserve the full label in `observation_id`. This retains two distinct periods beginning in 1978 and the source's combined `1998-00` period; it does not split or reallocate the multi-year period. The canonical rows do not contain catch numbers-at-age or age compositions.

## Reported assessment outputs

FAR 2024/37 Table 8 reports Base-run MPD B0 as 308 thousand tonnes and 2022 SSB as 63% of B0. Table 9 reports the Base-run MCMC median B0 as 323 thousand tonnes (95% credible interval 292–369) and 2022 SSB as 63% of B0 (95% credible interval 47–82). Table 10 reports MCMC acoustic catchability medians of 0.23 (0.20–0.28) for immature biomass and 0.41 (0.33–0.49) for mature biomass. The source reports annual SSB, exploitation and year-class-strength trajectories as figures; complete numerical annual N-at-age, F-at-age, M-at-age, recruitment and SSB outputs were not found.

## Remaining source gaps

The reviewed public documents do not provide numerical commercial proportions-at-age and associated bootstrap CVs, the full assessment length-at-age matrix, a numerical age-specific maturity surface, native Casal2 inputs or fitted outputs, or full annual age-specific population trajectories. As a result, catch-at-age cannot be reconstructed from the imported catch biomass and the available compositions without inventing values or substituting later fishery samples. The candidate remains unresolved for age-structured translation readiness. The later 2025 and 2026 catch-age reports can support future assessment updates, but not the 2022–23 run represented here.

## Source files

The assessment report, the 2023 input-data review, the 2022 acoustic-survey report, the May 2025 Plenary, and the 2024–25 and 2025–26 catch-age data reports are cached locally. URLs, retrieval dates and SHA-256 checksums are listed in `provenance/mpi_sbw_sbw6i_2024_sources.csv`.
