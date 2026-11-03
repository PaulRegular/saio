# NOAA Gulf of Mexico Gray Snapper source screen

**Screened:** 2026-10-30  
**Candidate:** NOAA Stock SMART 10221, Gulf of Mexico Gray Snapper (*Lutjanus griseus*)  
**Scope:** Discovery screen only; no canonical stock, assessment, input, assumption, or output rows are added.

## Current assessment and source run

Stock SMART identifies assessment 12831 as the 2022 Gulf of Mexico Gray Snapper operational assessment, using data through 2020 and receiving full acceptance. SEDAR 75 was conducted as an operational Stock Synthesis assessment. The Gulf Council's SSC accepted the assessment as consistent with the best scientific information available in January 2023.

The assessed unit is Gulf of Mexico Gray Snapper from the Texas/Mexico border eastward to the Atlantic side of Monroe County, including the documented Florida Bay and adjacent fishing areas. No canonical database stock or candidate unit with this species and Gulf boundary was found. Keep this Gulf unit separate from the Southern Atlantic unit.

## Recoverable inputs and outputs

SEDAR 75 models population ages 0-28 and uses composition bins through 21+. It includes commercial vertical-line and longline age compositions and recreational private and charter/headboat age compositions. The report says recreational shore age compositions were available but removed during model development; they should not be treated as an input to the accepted model. Annual fleet landings and age-composition information are published in the assessment report and its data papers. The published compositions and catch totals can support a documented catch-at-age reconstruction, but their native likelihood weighting and fleet-specific definitions must be retained during source curation.

The model uses two age-specific FWRI Fishery-Independent Monitoring abundance indices. The age-0 index covers 1998-2020 and is based on 21.3-m seines sampled during July-December; the age-1 index covers 1996-2020 and is based on 183-m shoreline seines sampled throughout January-December. Both are reported as fish per set, with annual uncertainty and scaled means. Additional indices include fishery-dependent CPUE and fishery-independent trawl and video indices. Survey timing for each non-FWRI series still needs to be checked against its source documentation; the assessment assumes continuous, year-round fishing and no seasonal fishing component.

The age-specific natural-mortality vector is printed in the assessment report and was carried forward from SEDAR 51. Maturity is described by an updated functional-maturity model, and the report and life-history paper document growth and length-weight information for deriving the required age-specific weights. The exact model-ready weight and maturity matrices should be checked against the assessment report tables before import.

The assessment report provides numeric annual biomass, spawning biomass, exploited abundance, age-0 recruitment, and stock-status series through 2020. Numeric fitted N-at-age and F-at-age tables were not located in the screened sources; those age-specific outputs should not be assumed available for direct comparison.

## Identity and screening decision

This is a **new, provisionally distinct Gulf of Mexico unit** with no matching canonical stock. It is **eligible for source curation**: the accepted operational assessment has fleet catch totals and age compositions, age-specific abundance indices, documented age-specific M and biological inputs, and comparable aggregate population outputs. The direct source inputs are spread across reports and working papers and will require transcription or documented reconstruction. Retain the FWRI index units, survey windows, fleet-specific age-composition treatment, M vector, and all missing or removed compositions. Do not substitute fitted outputs for observed inputs.

The SEDAR 75 report, age-composition and life-history papers, abundance-index papers, SSC review, and executive summary are cached in the gitignored `source_cache/discovery_noaa_gray_snapper_2022/` directory. Its `sources.csv` records URLs, document revisions, retrieval date, file sizes, and SHA-256 hashes. The discovery register is updated; the canonical database remains unchanged.
