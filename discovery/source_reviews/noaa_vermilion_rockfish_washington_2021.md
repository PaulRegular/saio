# NOAA Washington vermilion rockfish, 2021 component assessment

## Current stock unit and assessment run

The Pacific Fishery Management Council's June 2025 meeting record retains the
managed stock as **Vermilion rockfish (OR/WA)**. Its 2021 benchmark work used
separate Oregon and Washington Stock Synthesis assessments, alongside separate
northern and southern California vermilion/sunset assessments. The STAR panel
describes the four areas as components covering the U.S. management range and
explains that Oregon and Washington were modeled separately because of their
geographic, habitat, exploitation, and management differences. NOAA Stock SMART
ID 15339 is the Washington component; ID 15338 is the Oregon component. They are
linked to one current OR/WA candidate unit, while retaining their distinct
source areas and model outputs.

Stock SMART records the Washington benchmark as fully accepted, with data
through 2020 and Stock Synthesis 3.30.16. The 2026 preliminary NMFS assessment
recommendations identify 2021 as the last vermilion/sunset benchmark and place
the next work in the 2027 planning cycle. No newer completed production run was
located.

## Washington component inputs and assumptions

The accepted run is a two-sex, one-fleet model for 1949–2020 with one annual
season. The model input archive records recreational removals in thousands of
fish. Its historical catch series includes a documented pre-1979 reconstruction
based on the vermilion-to-black-rockfish catch ratio and discard estimates
derived from later discard-to-retained relationships.

Annual recreational length compositions span selected years from 1977–2020.
The model uses only sampled years with more than ten fish. Conditional
age-at-length observations are available from 1998–2020, with no age structures
in 2003 and most of the collected ages from 2015–2020. The native input file
includes age bins 0–68, sex-specific conditional age-at-length records, ageing
error, and the associated length bins. These inputs permit catch-at-age to be
reconstructed only for years where the catch, length, and age information are
compatible. They are not direct catch-at-age observations for the full
1949–2020 series.

The assessment uses fixed sex-specific weight-at-length relationships (length
in cm, weight in kg): female `1.36e-05 * L^3.1` and male `2.38e-05 * L^2.96`.
Maturity-at-length is fixed from Oregon data, with L50 = 39.4 cm and an assumed
95% maturity length of 48 cm. Natural mortality is estimated separately by
sex, with a lognormal prior based on a composite of empirical estimates; the
reference estimates are 0.085 per year for females and 0.087 for males. The
assessment also fixes fecundity-at-length, steepness, and recruitment variance.

No abundance index is used for Washington. The report considered a WDFW
nearshore survey but did not use it because its methods had not been reviewed
and the data were not sufficiently robust. The Oregon component does use an
aggregate recreational CPUE index; its age-specific reconstruction is
approximate and the documented timing does not resolve a fractional-year value.

## Outputs and screening decision

The accepted Washington `Report.sso` includes annual numbers-at-age,
catch-at-age, fishing mortality-at-age, and biomass-at-age, as well as spawning
output, recruitment, and exploitation summaries. These are fitted population
outputs, not observed abundance inputs. The Oregon report and model archive
provide separate component inputs and outputs; the two fits must not be
described as one pooled assessment.

The current OR/WA stock is **eligible for source curation** because both 2021
component archives preserve catch and age/length information from which
age-specific catch can be reconstructed for supported sample years, and the
official outputs are available. The main limitations are incomplete age
coverage, the absence of an abundance index in Washington, the approximate
age-specific form of the Oregon recreational CPUE series, and separate
component models. Eligibility does not imply direct catch-at-age likelihood
inputs, a pooled OR/WA model, or a ready tinyAM translation. No canonical
records have been added.

## Sources and local cache

- [Washington vermilion rockfish 2021 assessment](https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-washington-state-coast-in-2021.pdf/)
- [Washington 2021 model files](https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-wa-zip-file/)
- [Oregon vermilion rockfish 2021 assessment](https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-oregon-coast-in-2021.pdf/)
- [Oregon 2021 model files](https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-or-zip-file/)
- [Vermilion and Sunset 2021 STAR panel report](https://www.pcouncil.org/documents/2021/10/vermilion-and-sunset-rockfishes-stock-assessment-review-star-panel-report.pdf/)
- [PFMC June 2025 meeting record](https://www.pcouncil.org/documents/2026/01/june-2025-meeting-record.pdf/)
- [NMFS preliminary recommendations for 2027 assessments](https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/)
- [NOAA Stock SMART record 15339](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=15339)

Washington sources are cached locally in the gitignored directory
`source_cache/discovery_noaa_vermilion_rockfish_washington_2021/`; the
`sources.csv` manifest records URLs, retrieval date, revisions, file sizes, and
SHA-256 checksums. Oregon component files and the shared STAR review are cached
in `source_cache/discovery_noaa_oregon_vermilion_2021/`.
