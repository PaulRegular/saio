# Queensland east coast saddletail snapper — 2026 assessment

## Stock and assessment

The 2026 Fisheries Queensland assessment covers the east coast Queensland biological stock of saddletail snapper (*Lutjanus malabaricus*), from the northern tip of Cape York to south of Brisbane. The report treats this as one stock and distinguishes it from northern Australian and Western Australian stocks. It uses Stock Synthesis 3.30.23.2 and data through financial year 2025 (July 2024–June 2025), estimating spawning biomass at the beginning of 2026.

The model is two-sex and annual. It fits standardised commercial and recreational catch rates, commercial and recreational length compositions, and conditional age-at-length data. Commercial and recreational/Traditional Owner/charter removals are represented by three model fleets; charter selectivity mirrors the recreational and Traditional Owner fleet.

## Inputs and assumptions available in the report

The report describes catch reconstruction from commercial logbooks, charter logbooks, recreational surveys and boat-ramp surveys, plus age, length and sex sampling. Age and length sampling is reported for 2017–2025, with additional commercial line-fishery biological monitoring for 2018–2025. Table E.1 is in the model-outputs appendix and reports model-associated catch, depredation and discard estimates for 1961–2025; these are not the observed catch inputs. The report does not publish the complete input catch series, composition arrays, or native Stock Synthesis input files. The eRA record lists the report PDF only.

The age observations used by the model are conditional age-at-length data. The report says age-only compositions were used for visual model checks and were not fitted as a separate likelihood component. No age-specific abundance survey index is described. Consequently, the report alone does not support an exact reconstruction of the numerical age-at-length likelihood inputs.

The report gives these biological relationships and scenario settings:

- Fork length is measured in centimetres. Weight is `exp(-10.5 + 2.83 * log(FL_cm))` kg.
- Maturity at length is `1 / (1 + exp((57.3 - FL_cm) / 3.72))`; the reported L50 is 57.3 cm.
- Stock Synthesis fecundity option 1 with `a = 1` and `b = 0` makes eggs equivalent to spawning biomass.
- Growth is von Bertalanffy by sex, with one growth curve per sex across the east coast.
- Natural mortality is fixed at 0.11 or 0.14 per year in separate scenarios. Beverton–Holt steepness values are 0.65, 0.75 and 0.85. The final ensemble combines all 12 scenarios equally, including two length-composition weighting methods.
- The model assumes an unfished state in 1961, a 50% female fraction at birth, and no sex change.
- Depredation is set to 1% for all fleets through 2009 and then increases linearly to 29% for the commercial fleet and 58% for other fleets by 2025.

These details are recorded in `assumptions.csv`. No numeric catch, length, conditional age-at-length or catch-rate observations were added because their arrays are not included in the public report record.

## Public commercial catch data checked

The Queensland Open Data Portal's Commercial Fishing Annual Species Summary includes aggregated financial-year East Coast logbook records for large-mouth nannygai (species code 37346007) and unspecified nannygai (37346911) from 2006–07 through 2024–25. The portal describes the data as aggregated and withholds categories with fewer than five vessels. The retrieved June 2026 version was last updated on 20 October 2026, after this assessment was completed. Its East Coast totals do not preserve the north/south split used to allocate the 1988–2009 unspecified-nannygai catch, and the public fishery grouping does not establish the assessment's explicit exclusion of the charter (CV) and multi-hook (MH) records. The assessment also applies a documented 0.83 adjustment to 1997–2004 and reconstructs other fleet catches.

The 37-row portal extract is cached locally as a source cross-check, but is not added to `inputs.csv`: it is a later, aggregated release and cannot be verified as the exact run-specific catch series. The direct workbook download was blocked by the portal's AWS web-application firewall; the filtered records were retrieved through its official DataStore API instead. No age-specific likelihood inputs can be recovered from this dataset.

## Outputs recovered

The report gives a 2026 spawning-biomass ratio median of 28% of unfished spawning biomass, with a 95% credible interval of 19–42%. It also reports a 2025 fishing-pressure ratio relative to F60 of 3.85, with a 95% credible interval of 2.48–5.84. These terminal summaries are recorded in `outputs.csv`; their intervals are credible intervals from the equally weighted 12-scenario MCMC ensemble.

The report does not provide machine-readable annual N-at-age, F-at-age or M-at-age surfaces, nor absolute terminal spawning biomass in tonnes. The imported output record is therefore partial and should not be read as a full time-series extraction.

## Source and local cache

The official report and repository record were retrieved on 2026-11-05. The report PDF and the filtered public catch-data extract are cached in the ignored local directory `source_cache/australia_qld_saddletail_snapper_2026/`. Their URLs, retrieval dates, file sizes and SHA-256 checksums are recorded in `provenance/australia_qld_saddletail_snapper_2026/manifest.csv`.

The cached PDF is 10,039,655 bytes with SHA-256 `11F13A91690742A045B3E0813E09A186BC5B5089FB10EB013F9FC4852BF5BE69`.

- [2026 assessment report (PDF)](https://era.dpi.qld.gov.au/id/eprint/15593/1/2026%20East%20Coast%20Saddletail%20Snapper%20stock%20assessment.pdf)
- [Queensland eResearch Archive record](https://era.dpi.qld.gov.au/id/eprint/15593/)
- [Queensland Fisheries Resource Data and Information](https://www.data.qld.gov.au/dataset/queensland-fisheries-resource-data-and-information)
- [Queensland stock summary](https://www.dpi.qld.gov.au/services/fisheries/monitor/stock/species/saddletail-snapper)
