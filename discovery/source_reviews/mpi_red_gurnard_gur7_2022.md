# Red gurnard GUR 7: 2022 source screen

## Unit and latest assessment

Fisheries New Zealand assesses GUR 7 as the Challenger management unit for red gurnard (*Chelidonichthys kumu*). The latest full quantitative assessment identified in the May 2026 Plenary is the 2022 assessment, fitted through the 2020/21 fishing year (model year 2021). The May 2026 Plenary is a status summary, not a new assessment. Fisheries New Zealand's 2026–27 research services plan an update using the 2022, 2024, and 2026 trawl surveys, with project completion scheduled for 2027.

The detailed source is FAR 2022/22. The assessment used Stock Synthesis 3.30.17, an annual model spanning 1987–2021, with ages 1–9 and 10+, two sexes, and one commercial fishery.

## Inputs and assumptions verified

- Commercial catch biomass covers 1987–2021. Table A1 reports the annual model catch in tonnes. The report explicitly states that no commercial age or length compositions were available, so catch numbers-at-age were not part of the assessment.
- The Kaharoa West Coast South Island trawl survey supplies 15 biomass indices from 1992–2021. Table 1 reports biomass in tonnes with CVs of 12%–20%; Table 3 specifies lognormal observation errors and no extra survey process error.
- Appendix Table A2 **does tabulate the numeric survey age-composition vectors** for 1994, 1995, 2003, 2005, and 2007, ages 1–9 and 10+. Female and male proportions are components of each combined sample and sum to approximately one together; they are not separately renormalized. Table 3 assigns ESS 50. A close review of the appendix corrected the earlier screen's mistaken statement that these vectors were unavailable.
- Tables A3a and A3b tabulate female and male length-composition components for the 10 other survey years, in 10–55 cm bins. Sex components sum to approximately one together per year. The model assigns ESS 50; raw sample counts and bin boundaries are not reported.
- Base-model natural mortality is fixed at 0.31 per year for both sexes. Table 2 gives sex-specific growth, a length–weight relationship, and the maturity schedule: 0 at age 1, 0.5 at age 2, and 1 at age 3 and older.
- The model is annual. The trawl surveys are conducted in March–April. The report does not specify an observation fraction within the model year.

## Outputs and source-curation decision

Tables 6–9 report MPD and MCMC biomass/status, fishing mortality, yield, and projection summaries, including source-reported 95% MCMC intervals. The annual recruitment, SSB, and F trajectories are shown in figures; numerical N-at-age and F-at-age arrays are not tabulated.

The current-unit assessment has a **partial source import** under the latest-unit rule. It preserves 35 annual catch-biomass observations, 15 survey biomass observations and their CVs, 100 age-composition cells, 920 length-composition cells, 20 fixed natural-mortality values, 10 female maturity values, 29 assumptions, and 19 aggregate output rows. The earlier screen's claim that Table A2 was not numerical was incorrect. The source record remains partial because there are no commercial age compositions or catch-at-age, no precomputed weight-at-age series, and no numerical annual N-at-age/F-at-age outputs. The case does not meet the complete catch-at-age input threshold for the age-curated batch; the partial import does not establish translation readiness.

## Sources and cached files

- [FAR 2022/22: A stock assessment of red gurnard in GUR 7 for 2022](https://fs.fish.govt.nz/Doc/25169/FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf.ashx)
- [Fisheries Assessment Plenary, May 2026, Volume 3](https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx)
- [Proposed Fisheries Research Services for 2026–27](https://www.mpi.govt.nz/dmsdocument/71944/direct)

The two assessment documents are cached under the ignored source_cache/nz_red_gurnard_gur7_2022/ directory. Their retrieval dates and SHA-256 checksums are recorded in provenance/mpi_red_gurnard_gur7_2022_sources.csv.
