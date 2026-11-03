# Bering Sea Flathead Sole–Bering Flounder stock complex

## Assessment and identity

NOAA Stock SMART ID 10015 maps to the BSAI Flathead Sole–Bering Flounder assessment, one stock-complex case. The latest detailed operational update located is the 2024 SAFE assessment, Model 18.2c (2024), with data updated through 2024. The 2026 BSAI material is an off-cycle projection rather than a new full model fit.

The 2024 [SAFE chapter](https://files.npfmc.org/SAFE/2024/BSAIflathead.pdf) and the pinned native model files and outputs are cached under `source_cache/noaa_flatfish_screening_20261029/`. The repository revision is `bafa7658d31e0b99fe11d626a58e1c01807c69ee`; `sources.csv` records source URLs and checksums. Native `Report.sso` and `natage.csv` confirm fitted age-specific outputs; the latter spans sexes and ages 0–21, including the plus group.

## Inputs and screening decision

The 2024 assessment reports combined flathead sole/Bering flounder fishery catches and flathead-sole-only marginal fishery age compositions for 2000–2001, 2004–2007, and 2009–2021. Catch-at-age is not supplied as a direct series; a tinyAM catch-age input would need to be reconstructed from catch totals and the age compositions and must disclose that the species bases differ.

The survey has aggregate biomass, marginal length compositions and conditional age-at-length (CAAL) observations. The survey marginal age compositions are not used in the likelihood. An age-specific survey index would therefore be a downstream approximation based on CAAL, lengths and the aggregate biomass, not a direct official index.

The two-sex model fixes M at 0.2, uses externally estimated maturity and weight-length biology, and reports fitted N-at-age and other outputs. The Bering Sea and Aleutian Islands trawl surveys are annual summer surveys; a single fractional timing for tinyAM would be an explicit approximation because the annual source model does not provide one common within-year observation time.

This candidate is eligible for source curation and a translation attempt with these approximations documented. Do not split the complex into separate flathead sole and Bering flounder cases or treat the derived survey age series as an official observed index.
