# Eastern Australian sea mullet: 2026 assessment

## Stock and assessment

The 2026 Queensland–New South Wales assessment covers the shared eastern Australian sea mullet stock (*Mugil cephalus*), assessed using data through December 2024. The model reports status at the beginning of 2025. Queensland's current stock page identifies the 2026 assessment as the basis for management decisions. The unit is represented once, not as separate state stocks.

The fourth assessment used Stock Synthesis 3.30.24.2 and an annual, two-sex, age-structured population model. It combined four fishing fleets (New South Wales estuarine and ocean-beach, and Queensland estuarine and ocean-beach) in a 24-scenario ensemble. The model uses catch through 2024 and estimates into 2025.

## Numerical inputs and assumptions recovered

- The report says total retained catch declined to 3,021 tonnes in 2024. This is the only exact annual catch total stated in the report text; it is an aggregate of the four fleet inputs, which are not published as numerical annual series. The report shows the longer 1899–2024 catch history in figures.
- The model fits standardized annual catch-rate indices and age and length compositions for the four fleets. The report plots these observations but does not provide the numerical likelihood vectors or the full catch-rate series. Age compositions are shown for ages 1–9; the report notes that sampled fish can reach age 16. Sex-specific composition distributions were fitted separately, and the NSW samples do not identify the actual sex ratio.
- Natural mortality is common across sexes, ages and years. The ensemble considers 0.28, 0.33 and 0.37 per year, centred on the report's 0.33 estimate from a maximum age of 16.5 years. Steepness is 0.75. Other biological model relationships are described and illustrated, but the full numerical age-specific surfaces are not published in the report.
- Catch-rate timing is annual. The report does not state fractional-year timing for the indices.

The cached report does not provide numerical age-composition arrays, annual fleet-specific catch and CPUE arrays, or a native Stock Synthesis input/output bundle. Values have not been digitized from plots or reconstructed from fitted results.

## Outputs recovered

Table 1 reports the beginning-of-2025 spawning-biomass ratio relative to unfished biomass: median 39%, with a 95% credible interval of 25–76%. It also reports probabilities of 0.1% below 20%, 53.9% between 20% and 40%, 35.1% between 40% and 60%, and 10.9% above 60%. These are relative biomass outputs; the table does not report absolute spawning biomass.

The reported annual harvest rate over 2020–2024 has a median of 15% and a 95% credible interval of 10–21%. The report does not provide numerical annual N-at-age or F-at-age arrays.

The canonical partial record stores the aggregate 2024 catch as one catch-biomass row, the model assumptions above, and six Table 1 output rows. The SSB/B0 estimate and interval retain the source percent scale; status probabilities and harvest rate are stored as proportions with the conversions documented in their notes. No uncertainty is added to the 2024 catch, and no annual population surfaces are inferred.

## Source-curation decision

The latest current-unit assessment is added as a partial record because the official report provides a numeric 2024 aggregate catch, explicit model assumptions and comparable stock-status outputs. Age-input eligibility remains unresolved: the assessment is age structured, but its numerical catch, age-composition, CPUE and full biology inputs are not published in the cached report. These gaps also prevent an exact input reconstruction. The record preserves only source-reported values and keeps the fleet and sex structure explicit in its notes.

## Sources and cache

- Lovett, R. A., M. F. O'Neill, A. J. Prosser, and J. Stewart. 2026. *Stock assessment of Australian east coast sea mullet (Mugil cephalus), with data to December 2024*. [Official report record and PDF](https://era.dpi.qld.gov.au/id/eprint/16056/).
- Fisheries Queensland. [Sea mullet stock page](https://www.dpi.qld.gov.au/services/fisheries/monitor/stock/species/sea-mullet), which identifies the 2026 assessment as used to inform management decisions.

The assessment PDF is cached under the ignored `source_cache/australia_east_coast_sea_mullet_2024/` folder. Its URL, retrieval date and SHA-256 are recorded in `provenance/australia_east_coast_sea_mullet_2026_sources.csv`. The Queensland stock page was reviewed online but could not be cached because the site returned an automated browser challenge.
