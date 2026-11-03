# Main Hawaiian Islands Deep 7 bottomfish complex (`NOAA:11827`), 2024

## Assessment identity and current run

NOAA Stock SMART identifies ID 11827 as the Main Hawaiian Islands Deep 7
Bottomfish Multi-species Complex, under PIFSC. Its latest listed assessment is
run 13362, conducted in 2024, using data through fishing year 2023. Stock SMART
marks the run fully accepted and identifies JABBA as the model. The complex is
one management and assessment unit made up of seven species, not seven separate
candidate units. The database contains no canonical Deep 7 record.

The accepted model is an aggregate Bayesian surplus-production model. Its
observations are species-level total catches and aggregate abundance indices;
it estimates exploitable biomass, harvest rate, stock status and reference
points. The fishing year runs July through June, and the historical model
extends from 1949 through 2023. BFISH relative-abundance data come from early
fall surveys in 2016–2022, corresponding to fishing years 2017–2023. The model
does not estimate an age-structured population trajectory.

The report also evaluates an Opakapaka-only model separately. Its reported
Stock Synthesis data inputs include commercial and non-commercial catch,
fishery CPUE, aggregate BFISH camera and research-fishing indices, length
compositions from BFISH, and commercial-fishery weight compositions. Life-
history information is fixed. The report does not document observed
catch-at-age or age-composition likelihood inputs. Although this supplemental
model is age structured and converged, its observed data structure does not
meet the age-disaggregated-input requirement for this inventory.

## Inputs, assumptions, and outputs

- **Catch:** species-specific reported and reconstructed unreported total
  catch in weight, not catch numbers-at-age.
- **Abundance:** aggregate standardized fishery CPUE and the aggregate BFISH
  relative biomass index; neither index is age-specific.
- **Biology:** Deep 7 life-history parameters are summarized by species. For
  the supplemental Opakapaka Stock Synthesis model, life-history information
  including natural mortality, growth and reproduction is fixed; the report
  lists commercial weight compositions but no weight-at-age likelihood.
- **Timing:** July–June fishing years. BFISH is conducted in early fall and
  assigned to the fishing year that begins in the same calendar year.
- **Outputs:** the accepted JABBA model reports annual aggregate exploitable
  biomass, harvest rate, status, reference points and projections. The
  supplemental Opakapaka model reports aggregate biomass, harvest rate and
  status; the report does not supply the observed age inputs needed for a
  defensible tinyAM age-based fit.

The case is screened **ineligible** for the age-disaggregated assessment set.
This decision is about the observed likelihood data, not whether the report
contains age-related life-history information or an auxiliary age-structured
model. No stock, assessment, input or output records were added to the
canonical database.

NOAA Stock SMART also lists a separate Opakapaka candidate (`NOAA:12442`). The
2024 report's supplemental species model is described as a comparison within
the Deep 7 assessment, so it is not merged into the multi-species complex's
identity or counted as a new Deep 7 component record.

## Sources and local cache

- [NOAA Stock SMART record](https://apps-st.fisheries.noaa.gov/stocksmart)
  (ID 11827, assessment 13362, fully accepted, 2024, data through 2023).
- [2024 Deep 7 benchmark report](https://repository.library.noaa.gov/view/noaa/56878/noaa_56878_DS1.pdf),
  NOAA Technical Memorandum NMFS-PIFSC-157, especially Sections 2.7, 3.3,
  4.5, Figure 12, and Tables 1–2.
- [NOAA report landing page](https://www.fisheries.noaa.gov/resource/document/benchmark-stock-assessment-main-hawaiian-islands-deep-7-bottomfish-complex-2024).
- [WPSAR panel chair report](https://www.fisheries.noaa.gov/s3/2024-07/Benchmark-Stock-Assessment-for-the-Main-Hawaiian-Islands-Deep-7-Bottomfish-Complex-in-2024-Chair-Report-508.pdf).

The landing page and panel report are cached in the ignored local directory
`source_cache/discovery_noaa_mhi_deep7_2024/`; the manifest records their URLs,
retrieval date and SHA-256 checksums. The primary technical memorandum is
publicly available online and was reviewed there, but the local download
endpoint returned HTTP 403. The rejected error response was removed and the
cache manifest records this limitation.
