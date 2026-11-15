# Pacific sardine northern subpopulation (2025 update)

## Unit and inventory crosswalk

NOAA Stock SMART 10573 identifies the northern subpopulation of *Sardinops sagax*. The 2025 assessment describes its range from northern Baja California to British Columbia, offshore to 300 nautical miles. DFO's Pacific Sardine management entry refers to this same transboundary subpopulation. DFO's 2022 harvest advice uses biomass from the NOAA assessment; no separate DFO age-structured assessment was identified in the sources reviewed. Both inventory rows therefore share internal candidate key `pacific_sardine_northern_subpopulation` and represent one unit, not two.

The DFO 2024-2029 IFMP summary says the species has not been commercially harvested in British Columbia since 2012 and that the fishery has been closed since 2015. The plan remains in place for a possible return of sardines to Canadian waters.

## Latest detailed assessment

The latest detailed production run located is the 2025 NOAA update for U.S. management in 2025-2026, Stock Synthesis 3.30.22. It updates the 2024 benchmark and uses model years 2005-2024 with two semesters per model year. The report gives catch by fleet in metric tonnes and model year-semester. The three commercial fleets are MexCal S1, MexCal S2, and PNW; the assessment also uses acoustic-trawl survey biomass and age-composition data. Fishery age compositions and conditional weights-at-age are part of the model. The 2024 survey added biomass, age composition, and weights-at-age, though the assessment team flags concerns about low sample sizes and whether the sampled nearshore fish represent the full northern subpopulation.

The report states that natural mortality is estimated with a prior and gives an estimate of 0.53 per year. It reports half-year age-1+ biomass in metric tonnes and age-0 recruitment in thousands through the 2025 forecast, with aggregate uncertainty information. The 2025 assessment is reported to have converged with small gradients and a positive-definite Hessian.

## Eligibility and source limits

The 2025 report verifies that age-composition likelihoods and age-specific biological inputs are used, but it does not publish complete run-matched age-composition arrays, numerical biological surfaces, or fitted N-at-age and F-at-age tables. The available PFMC Stock Synthesis archive is for the 2024 benchmark, with terminal model year 2023. It is cached only to establish what prior-run files are available; it is not substituted for missing 2025 input or output values. Keep the current 2025 assessment as a partial source record and leave age-structured input eligibility unresolved until the matching electronic model files or age arrays are recovered.

The current DFO material supplies management context and cites the shared NOAA biomass basis, not an independent DFO model. Do not create a second assessment or a separate DFO stock record from that inventory row.

## Sources

- NOAA Technical Memorandum NMFS-SWFSC-719, [2025 Pacific sardine update](https://doi.org/10.25923/z1xh-b932).
- PFMC, [2024 benchmark model files](https://www.pcouncil.org/documents/sardine-2024-model-files-zip-file/), used only as a prior-run source-availability check.
- NOAA Technical Memorandum NMFS-SWFSC-698, [2024 benchmark assessment](https://doi.org/10.25923/jyw3-ys65).
- DFO, [2022 harvest advice for Pacific sardine in British Columbia](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41074506.pdf).
- DFO, [2024-2029 Pacific Sardine IFMP summary](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/sardine-ifmp-pgip-sm-eng.html).
- Local copies and SHA-256 checksums are in the ignored `source_cache/discovery_pacific_sardine_2025/` directory.
