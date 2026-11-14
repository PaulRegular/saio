# Chatham Rise orange roughy (ORH 3B), 2025 assessment

## Stock unit and assessment

ORH 3B is the Fisheries New Zealand management unit. The 2025 assessment fitted separate population models for East & South Chatham Rise (ESCR) and Northwest Chatham Rise (NWCR). The assessment covers these Chatham Rise components, not every biological sub-stock within the wider ORH 3B management area. This review treats ESCR and NWCR as modelled regions within one ORH 3B record, not as two additional stocks.

FAR 2025/46 is the latest detailed production assessment located. It uses data through the 2023–24 fishing year and estimates stock status for 2024–25. The CASAL2 appendices specify model years 1911–2025 and ages 1–100 with age 100 as a plus group. The 2026 independent international review evaluates the 2025 assessment and orange roughy methods; it is not a replacement assessment or a new input run.

## Official sources and provenance

- [FAR 2025/46: stock assessment](https://fs.fish.govt.nz/Page.aspx?dk=26145&pk=113)
- [FAR 2025/18: additional analyses](https://fs.fish.govt.nz/Page.aspx?dk=25870&pk=113)
- [FAR 2025/23: 2022 acoustic survey report](https://fs.fish.govt.nz/Page.aspx?dk=25881&pk=113)
- [FSR 2026/02: independent orange roughy assessment review](https://fs.fish.govt.nz/Page.aspx?dk=26256&pk=113)

The four reports are cached under the ignored `source_cache/mpi_orh3b_2025/` directory. Retrieval dates, URLs, and SHA-256 checksums are recorded in `provenance/mpi_orh3b_2025_sources.csv`.

## Assessment inputs and assumptions

The final ESCR models use annual catch biomass by modeled fishing area, acoustic spawning-biomass observations, and alternative recruitment assumptions. The selected final scenarios include the Old Spawning Plume vessel 38 kHz series for 2002–2010 and one later acoustic series: 38 kHz for 2011–2024 or AOS 120 kHz for 2013–2024. Four reported ESCR scenarios combine those two acoustic choices with either acoustic-only data or acoustic data plus age frequencies. The unresolved divergence between the 38 and 120 kHz series is retained as a scenario distinction. Catch histories are scaled to modeled fishing areas using estimated catch distributions and include assumed catch over-runs.

The ESCR appendix reports sampled fishery age-frequency proportions for the Old Spawning Plume (1984, 2003, 2012, 2013, 2016, 2022, and 2024), Rekohu (2012–2024), and Mt. Muck/Crack (2013–2024), across ages 18–100+. These samples came from target fishing in spawning areas; they are not acoustic survey age indices. They are included only in the acoustic-plus-age-frequency scenarios. Effective sample sizes are 10 except for the Old Spawning Plume 2003 sample, which is 2. The assessment notes inconsistencies in those samples. The final NWCR assessment scenarios use acoustic biomass observations only and estimate M; its age and length data are discussed but are not included in those final runs.

The assessment appendices provide native catch-biomass tables, acoustic biomass observations and CVs, and the ESCR age-frequency vectors. The extraction is recorded under `mpi_orh3b_2025`: 328 catch-biomass rows across six ESCR model fishing areas and one NWCR area; 26 acoustic observations with 26 matching CV rows across five series; and 1,310 age-composition cells in 16 sampled fishery observations. Catch rows preserve the model's year labels through 2025. The report describes observations only through fishing year 2023–24; the CASAL2 inputs repeat each area's 2024 catch in model year 2025. Those repeated values are retained as assumed current-year model inputs and labelled as unobserved in the database.

Acoustic CVs exclude the separate process error specified by the model. Acoustic observations and age compositions use 0.75 of the annual time step. The CASAL2 files describe von Bertalanffy growth, a length-weight relationship, and maturity/selectivity ogives; these are equations and parameters rather than supplied annual weight-at-age or maturity-at-age tables. The report does not explicitly identify the model length unit, so equation parameters are preserved without conversion. The database records the missing standalone biological surfaces and unresolved unit as limits on the assumptions record.

For the final ESCR models, M is fixed at 0.045 per year and recruitment has a change point at 1980, with steepness fixed at 1. The NWCR final models use acoustic-only data and estimate M with a normal prior centred at 0.045 per year and CV 0.333; the stock-recruit steepness is fixed at 0.75. The assessment reports catch histories by modelled area, rather than catch numbers-at-age. The fishery age-frequency vectors are multinomial sample compositions from target fishing at spawning areas, not acoustic survey age indices; they are not converted to catch numbers-at-age. The source input specifies effective sample sizes of 10 except for the 2003 OSP sample (2), preserved in `sample_size`.

## Reported outputs and limitations

FAR 2025/46 Tables 4, 7, and 10 report MCMC recruitment levels, B0, 2025 spawning biomass, and stock status for four ESCR scenarios and two NWCR scenarios, with 95% credible intervals. The database captures these scalar summaries and stock-status probabilities with their run labels. It retains the source's thousand-tonne and percent scales; reported percentages for probabilities are converted to 0–1 probabilities with the conversion stated in row notes. The Table 7 value “<1%” is kept as a textual source note and is not entered as a numeric output.

Annual numeric SSB, recruitment, N-at-age, F-at-age, and M-at-age trajectories were not located; these results are presented as figures or remain model outputs. The public sources reviewed do not provide catch numbers-at-age. The assessment is recorded with `inputs_status=complete` because the reviewed model appendices provide the fitted catch, acoustic and age-composition arrays for both regions and their source dimensions. `assumptions_status=partial` reflects the lack of a versioned native run and standalone weight-at-age/maturity-at-age surfaces, the unresolved model length unit, and run-specific selectivity details. `outputs_status=partial` reflects the absence of annual numerical population surfaces and age-specific uncertainty. Cached source URLs, retrieval dates, and checksums are in `provenance/mpi_orh3b_2025_sources.csv`; the cache itself remains local and gitignored.

The 2026 independent review identifies the 38/120 kHz divergence, ageing data, M, and acoustic catchability as important sources of uncertainty. Its findings are context for the 2025 assessment, not substitute numerical inputs or outputs.
