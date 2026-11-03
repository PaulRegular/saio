# Western Baltic spring-spawning herring (her.27.20-24), 2026

## Assessment represented

The canonical record represents the official 2026 ICES HAWG assessment, fitted for 1991–2025.

The production run is identified as `WBSS_HAWG_2026`, a single-fleet SAM assessment available from stockassessment.org.

The official native model object is cached locally with the full HAWG 2026 report and the ICES Stock Assessment Graphs source page.

The native object reports SAM 0.12.0, optimizer convergence code 0, and objective value 414.9946.

The canonical assessment database retains the original official-model definitions and age structure. The reduced 0–5+ representation is a downstream decision, not a change to the official assessment records.

## Inputs and assumptions

The cached official fit contains 315 total catch-at-age observations and 372 finite survey observations, with five HERAS observations missing in 1999.

It also contains annual stock and catch weights, maturity, fixed natural mortality, spawning fractions, and observation precision weights.

Survey identities, original age ranges, plus groups, and sampling fractions are retained in the canonical database.

Natural mortality is fixed, time-invariant, and age-specific, based on North Sea autumn-spawning herring and profiled during the 2025 benchmark. The official production model specifies `mortalityModel = 0`.

Maturity is time-invariant. The fractions of annual fishing and natural mortality occurring before spawning are 0.168 and 0.25, respectively.

The official SAM model uses a hockey-stick stock-recruitment relationship (`stockRecruitmentModelCode = 61`), separate recruitment-process variance, and a shared survival-process variance across ages 1–8.

Fishing mortality states exhibit AR(1) correlation across ages, with ages 7 and 8 sharing a single F state.

HERAS, GERAS, and IBTS/BITS Q1 use correlated age-specific observation errors, while N20 errors are independent.

The official `keyLogFpar` configuration defines catchability sharing across survey and age groups. The revised preserves the corresponding groups where possible following age aggregation.

## Output checks

Official recruitment, SSB, Fbar for ages 2–5, and total stock biomass extracted from report Table 3.6.11 agree with the native SAM fit after expanding F states using `keyLogFsta`.

Differences are less than one unit for counts and biomass, and less than 0.00051 for Fbar, consistent with report rounding.

The native numbers-at-age and F-at-age estimates agree with report Tables 3.6.12–3.6.13 to displayed precision.

For 2025, the official assessment reports:

- Recruitment: 20,038,259 thousand fish.
- SSB: 110,526 tonnes (95% CI 85,439–142,978).
- Fbar: 0.011 (95% CI 0.008–0.015).
- Total stock biomass: 266,183 tonnes.

## Source references

- ICES HAWG 2026, *Report of the Herring Assessment Working Group*, Section 3.6, pp. 173–174 and Tables 3.6.4–3.6.13, pp. 247–256: [cached report](../source_cache/ices_herring_western_baltic_2026/HAWG_2026_Full_Report.pdf).
- ICES Benchmark Workshop on Selected Herring and Sprat Stocks (WKBHERSPRAT), 2025, DOI [10.17895/ices.pub.31538287](https://doi.org/10.17895/ices.pub.31538287).
- Official native SAM object `WBSS_HAWG_2026/run/model.RData`, cached at [model.RData](../source_cache/ices_herring_western_baltic_2026/model.RData).
- ICES Stock Assessment Graphs, source-data key 21294: [official source page](https://sg.ices.dk/ViewSourceData.aspx?key=21294), cached at [HTML copy](../source_cache/ices_herring_western_baltic_2026/ICES_Stock_Assessment_Graphs_key_21294.html).

## Remaining limitations

Remaining differences include the official hockey-stick recruitment relationship, cross-age survey observation correlations, the full age-specific F-state structure, and the use of source age-5 biology for the translated 5+ population group.

The source report does not provide complete age-specific uncertainty for the population and mortality surfaces.

Inspect the current diagnostics and comparison definitions before interpreting this translation.
