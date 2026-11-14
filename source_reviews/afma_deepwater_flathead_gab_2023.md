# AFMA Deepwater Flathead, Great Australian Bight (2023)

## Stock and assessment

The assessment treats Deepwater Flathead (*Neoplatycephalus conatus*) as one stock across the Great Australian Bight. The 2023 model used separate trawl and Danish-seine fleets.

AFMA's 2026 SESSF species summary identifies the stock as last assessed by GABRAG in November 2023 and says it is assessed as a single stock. The summary notes that another assessment was scheduled for 2026, but AFMA's species page continues to list the 2023 report as the detailed assessment. I did not find a later detailed assessment or public native model files. The 2023 technical report calls its model a suggested or preliminary base case; GABRAG agreed to include Danish seine as a separate fleet for RBC advice.

The assessment is an annual, two-sex, age- and size-structured Stock Synthesis model, version 3.30.21.00. It uses ages 0–29, with age 29 as a plus group. It assumes the stock was unexploited before 1988/89.

## Sources and provenance

- [AFMA, Stock Assessment for Deepwater Flathead 2023](https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-deepwater-flathead-2023.pdf)
- [AFMA, 2026 SESSF Species Summaries](https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf)
- [Australian Hydrographic Office, Limits of oceans and seas around Australia](https://www.hydro.gov.au/factsheets/FS_Hydrographic_Surveying-Limits_of_oceans_and_seas_around_Aus.pdf)

The report and 2026 summary are cached under the ignored source_cache/australia_afma_deepwater_flathead_2023/ directory. Their retrieval dates, URLs, and SHA-256 checksums are in provenance/afma_deepwater_flathead_gab_2023/manifest.csv. The Hydrographic Office source is used only to support the basin label; it does not supply stock-assessment data.

## Inputs and assumptions

Table 3 reports annual trawl landings and standardized trawl CPUE for 1988/89–2022/23. Catch is in tonnes. The report labels fiscal years by their first year, which is retained as the model-year label. Danish-seine catch is tabulated separately from 2010/11 onward. The table's 2023/24 catch repeats the 2022/23 value for projection and RBC calculations; that assumed value is not stored as an observed catch. The CPUE unit is not stated, so its values are preserved on the source scale without a unit conversion.

Table 4 reports nine GAB Fishery Independent Survey relative-abundance estimates in tonnes for 2004/05–2020/21, with their original CVs. The report says the CVs were subsequently re-estimated during tuning. The database preserves the tabled original CVs and does not represent them as the final fitted likelihood CVs.

Table 5 reports age-reading standard deviations for ages 0–29 for two readers. The report assigns Reader 2 to samples from 2000 and 2002–2007 and Reader 1 to other sample years. These standard deviations are preserved by reader code; they are not a full true-age-to-observed-age transition matrix.

Table 6 reports raw age-length otolith sample counts by year and fleet. The database preserves the nonblank trawl, Danish-seine, and GABFIS counts. These are sample counts, not age-composition proportions or effective likelihood sample sizes. The assessment uses length compositions and conditional age-at-length data, but the public report does not provide their numerical vectors. It does not publish catch numbers-at-age.

The assessment estimates an age- and time-invariant M. The base-case scenario label reports M = 0.24 per year, without uncertainty. Steepness is fixed at 0.75, recruitment variation at 0.7, and the sex ratio at 0.5. Female maturity is represented by a logistic curve with 50% maturity at 40 cm total length. Growth is estimated within the model; male and female growth and length-weight parameters differ. A numerical age-specific weight or maturity surface is not reported. The report does not give fractional within-year observation times.

## Outputs and remaining gaps

The report gives base-case unfished female spawning biomass (SSB0) of 9,918 tonnes, projected female SSB of 4,413 tonnes at the start of 2024/25, and a projected SSB/SSB0 ratio of 0.44. It reports annual RBC recommendations of 1,220, 1,211, 1,204, and 1,200 tonnes for 2024–2027. The point estimate of M is also preserved. The report provides no uncertainty intervals for these imported outputs.

Annual numerical recruitment, abundance-at-age, fishing-mortality-at-age, and natural-mortality-at-age outputs were not located. The only M value reported is the model's scalar estimated parameter. The source record is therefore partial. Candidate eligibility remains unresolved because the numeric conditional age-at-length vectors and the age-specific biological surfaces needed to assess translation readiness are unavailable from the reviewed public sources.