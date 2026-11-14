# Southern Atlantic red snapper, 2024 SEFSC update to SEDAR 73

## Unit and current assessment

NOAA Stock SMART identifies this as stock 10231, Red snapper - Southern
Atlantic Coast, managed by the South Atlantic Fishery Management Council. It is
a distinct unit from Gulf of Mexico red snapper (NOAA:10230). The latest
completed detailed run located is the December 2024 SEFSC update to SEDAR 73,
with an assessment period of 1950-2023. The SEDAR 73 2021 assessment is the
underlying model and input reference; it ends in 2019. NOAA Stock SMART records
the 2024 run as operational with full acceptance, although the row's citation
field still points to SEDAR 41. The 2024 report says the update was prepared at
the request of the Southeast Regional Office under the exceptional
circumstance of a Secretarial Amendment. SEDAR 90 is in progress with terminal
data year 2024 and a review workshop scheduled for February 2027; its working
papers are preliminary and are not treated as the production fit.

The updated assessment uses the Beaufort Assessment Model (BAM), an integrated
statistical catch-age model. It retains the SEDAR 73 configuration and updates
the observations through 2023. The 2024 update recomputes assessment-period
benchmarks using the post-2020 discard-mortality block so the assessment and
projection benchmarks are consistent.

## Inputs and biology

The model state ages are 1-20+, with age 20 as the plus group. The model uses
annual fleet landings and discards for commercial handline, recreational
headboat, and general recreational (private and charter) fleets. Recreational
landings are in thousands of fish, commercial landings are in thousand pounds
whole weight, and discards are in numbers. The model also fits year-specific length
and age compositions. Composition ages are pooled at age 10 for headboat,
general recreational, and SERFS chevron-trap samples, and at age 13 for
commercial samples. The 2024 update extends removals through 2023 and adds
SERFS chevron-trap age compositions through 2023, with no SERFS age observations
in 2020. These totals and compositions support the catch-age model, but the
report does not provide a direct observed catch-numbers-at-age table.

Five aggregate abundance indices are fitted: commercial handline, headboat,
headboat discards, SERFS chevron trap, and SERFS video. The 2024 update extends
both SERFS indices through 2023 (with no observation in 2020). SERFS chevron
trap age compositions are also fitted; no age-specific abundance index is
reported. The chevron-trap and video likelihoods are each assigned half weight
because the two gears share sampling.

Growth curves and length-to-whole-weight relationships are supplied inputs.
Female maturity is a fixed logistic curve with an age-specific vector. The
assessment's spawning output is population fecundity in eggs, incorporating
maturity, female proportion, batch frequency, and size-based batch fecundity;
it is not conventional SSB in biomass units. Natural mortality is fixed over
time and declines with age using a Lorenzen curve. It is scaled to match
cumulative survival from age 4 through the oldest observed age (51) under
constant M = 0.11 per year. Fractional survey timing within the annual model
was not found in the reviewed sources.

## Outputs and screening decision

The 2024 report publishes annual numbers at age (1000 fish), biomass at age
(1000 lb), and instantaneous F at age (per year) for 1950-2023. Age-1
abundance is recruitment (1000 fish). Egg-based spawning output is reported in
1e8 eggs. The base run supplies point estimates; a mixed Monte Carlo/bootstrap
ensemble (MCBE) summarizes uncertainty, but the age-specific output tables do
not provide age-specific intervals.

This stock is eligible for source curation: detailed official sources document
catch/removal totals, fishery and survey age-composition inputs, aggregate
indices, age-based growth and maturity, fixed natural mortality, and
comparable annual population and mortality outputs. Source curation should
preserve the native catch totals and compositions, keep the aggregate survey
indices distinct from age compositions, and retain the egg-based spawning
output definition. It should not label reconstructed values as direct observed
catch-at-age or convert spawning output to biomass without source support. The 2024 update outputs and carried-forward age-specific life-history inputs have been imported; run-specific observation arrays remain unavailable.

## Imported records

The canonical 2024 assessment record contains 4,810 point-estimate rows from the official update: annual N-at-age (ages 1–20, with age 20 as 20+), total numbers, age-1 recruitment, biomass-at-age, instantaneous F-at-age, apical F, total biomass, and the source-defined egg-based SSB for 1950–2023. Source units, timing, age grouping, and metric definitions are preserved. The output tables do not provide age-specific uncertainty.

These are estimated outputs, not observations. A separate 140-row input import records the SEDAR 73 Table 2 age-specific length, weight, female proportion, female maturity, batch fecundity, annual batches, and fixed M for ages 1–20+, which the 2024 update carries forward as life-history inputs. The 2024 report does not publish its run-matched numerical catch, aggregate index, or age-composition vectors; those remain unavailable and have not been copied from the 2021 assessment. The assumptions rows preserve run identity, model family, age structure, egg-based spawning definition, fixed M structure, and all four discard-mortality blocks with Table 1 uncertainty ranges. Current inputs, assumptions, and outputs are partial.

Tables 11-14 and 16-18 are also imported as model-estimated outputs: annual fleet landings and discard mortalities, and age-specific landings and discards. They are not observed inputs. Cells printed as periods in Tables 13-14 are omitted rather than converted to zero. Table 15 is retained as the reported `total_removals_at_age` series, but its annual age sums match Table 11 landings rather than landings plus the positive Table 13 discard mortalities. The source table is preserved as printed and flagged; no discard series is added to it.

## Separate 2021 SEDAR 73 assessment event

The earlier SEDAR 73 operational assessment is recorded as its own 2021
assessment event, fitted through 2019. Its inputs include the reported annual
fleet removals from Table 3 and the five aggregate abundance-index series and
paired CVs from Table 4. These are source totals and aggregate indices, not
catch-at-age or age-specific abundance observations. The report's age
compositions are not available as numeric vectors in the recovered tables, so
they were not reconstructed from figures or estimated model states.

The historical event also records point-estimate outputs from Tables 9, 11, 12
and 18: abundance-at-age, biomass-at-age, annual status indicators, and
instantaneous fishing mortality-at-age. The reported spawning output remains
in eggs, and no uncertainty was added where the report tables provide none.
The 2021 observations and outputs are not assigned to, or used to fill the
missing input data for, the separate 2024 update. Both events therefore retain
their own run identity and completeness status.

## Sources

- [SEFSC 2024 update to SEDAR 73](https://sedarweb.org/documents/sefsc-2024-update-to-sedar-73-south-atlantic-red-snapper-assessment/)
- [SEDAR 73 2021 Stock Assessment Report](https://sedarweb.org/documents/sedar-73-stock-assessment-report-south-atlantic-red-snapper/)
- [SEDAR 90 project status and working papers](https://sedarweb.org/assessments/sedar-90-south-atlantic-red-snapper/)
- [NOAA Stock SMART, stock 10231](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10231)

The 2024 update and the 2021 SEDAR 73 report are cached under
`source_cache/discovery_noaa_satl_red_snapper_2024/`. Their retrieval dates,
URLs, SHA-256 checksums, and descriptions are in the local `sources.csv`.
