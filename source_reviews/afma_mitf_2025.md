# Patagonian toothfish at Macquarie Island: 2025 assessment

## Stock unit and assessment

AFMA manages Patagonian toothfish (*Dissostichus eleginoides*) in the Macquarie Island Toothfish Fishery (MITF). The 2025 assessment represents one reproductive stock with northern and southern spatial areas. SARAG 73 advised adopting the assessment as the scientific basis for a TAC recommendation. SouthMAC 45 considered the 2025 results and recommended a 404 t TAC for the 2026/27 and 2027/28 fishing seasons.

## Inputs recovered

Table 2 reports exact catch removals in tonnes for five fleets over fishing seasons 1994/95–2024/25. The canonical input rows preserve the fleet values as reported, including explicit zero catches. The table's rounded total-catch column is used as a transcription check; TAC values are management limits, not assessment observations, and are not stored as inputs.

The model also uses length-frequency observations, conditional age-at-length compositions, and tag releases and recaptures. Conditional age-at-length data cover selected fishing seasons from 1996/97 through 2023/24. The report gives the number of age samples by season and region, but not the numeric age counts within each length bin. It provides no run-matched length-frequency or tag arrays. The Australian Antarctic Data Centre describes its fish-observer database as a secure SQL database, with access requiring agreement from AFMA's Sub-Antarctic Resource Assessment Group.

## Assumptions

The assessment is an integrated length-age population model fitted with TMB. It spans model years 1985–2025, ages 1–52, length classes 0–190 cm, and two spatial areas. Fleet catches are treated as known and exact. Length frequencies use a Dirichlet-multinomial likelihood; age within length class uses a multinomial likelihood; tag histories use a spatial, length-structured Brownie-type likelihood with Dirichlet-multinomial over-dispersion.

Base natural mortality is fixed at 0.13 per year and 0.155 is explored as a sensitivity. The report gives a length-weight relationship of weight in tonnes = 4.4e-6 × length in centimetres^3.14. Numeric run-matched growth and maturity surfaces were not located.

## Outputs recovered

The report gives terminal female SSB relative to unfished levels as 0.66 (95% credible interval 0.60–0.73) for the whole stock, 0.83 (0.76–0.91) for the North, and 0.36 (0.32–0.40) for the South. These relative estimates are imported as three summary outputs. The report shows annual SSB and recruitment trajectories as figures, but does not tabulate their numerical values; no values were digitized from the figures.

The canonical assessment record is partial: fleet catch biomass, selected model assumptions, and terminal relative SSB summaries are available. Numeric age compositions, length frequencies, tag arrays, age-specific biology, and annual population-output series remain unavailable from the reviewed public sources. Age-input eligibility therefore remains unresolved.

## Sources

- [CSIRO 2025 Macquarie Island toothfish assessment](https://www.afma.gov.au/sites/default/files/2025-09/MITF-toothfish-stock-assessment-2025.pdf), especially Table 2 and Sections 4–5.
- [SouthMAC 45 final minutes](https://www.afma.gov.au/sites/default/files/2025-11/SouthMAC-45-Meeting-Record.pdf), Agenda item 4.1.
- [AFMA Macquarie Island Toothfish Fishery](https://www.afma.gov.au/fisheries/macquarie-island-toothfish-fishery).
- [Australian Antarctic Data Centre Fish Database record](https://data.aad.gov.au/metadata/records/AADFishDatabase).

The report and SouthMAC minutes are cached under the ignored source_cache/discovery_afma_mitf_2025/ directory. Their source URLs, retrieval date, and checksums are recorded in provenance/afma_mitf_2025_sources.csv.
