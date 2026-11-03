# Western Baltic spring-spawning herring (her.27.20-24), 2026

## Translation revision (2026-10-13)

The tinyAM translation was revised to address an inconsistency between the age structure of the official SAM population model and its survey indices.

The official assessment models ages 0–8+, whereas the HERAS index has a plus group at age 6 and the IBTS/BITS Q1 index has a plus group at age 5. The earlier tinyAM translation retained the population age range of 0–8+ but treated these survey plus-group observations as if they represented individual ages. This was inconsistent with the observation definitions in the official SAM model.

The revised translation fits ages **0–5+**, making the population plus group coincide with the earliest survey plus group. The translation helper aggregates catch and survey observations above the selected maximum age.

Specifically:

- **HERAS:** The age-5 index and age-6+ index are summed into a single age-5+ observation.
- **IBTS/BITS Q1:** The existing age-5+ observation is retained without additional age aggregation.
- **GERAS and N20:** Their observed age ranges are unchanged.
- **Commercial catch:** Catch numbers for ages 5–8+ are summed into the new age-5+ group.

This approximation preserves the aggregate observed quantities while avoiding the incorrect interpretation of plus-group survey indices as observations of individual ages.

The population and fishing mortality processes were also revised. The tinyAM N process now uses `iid` rather than `rw`, with `init = "free"`. The F process now uses `cor_rw` instead of independent random walks, allowing correlated temporal F changes across ages.

These changes bring the translation closer to the source SAM process structure, although the official hockey-stick recruitment relationship, complete F-state configuration, and correlated observation errors are not reproduced exactly.

### Consequences of the reduced age structure

The revised plus group represents ages 5 and older, whereas the official population model estimates ages 5–7 separately and retains age 8 as its plus group.

The aggregation is exact for additive catch numbers and observed survey-index totals, subject to the source index definitions and unit consistency. It is not an exact reduction of the official population model.

In particular, the translation helper does not automatically calculate population-weighted stock weights, maturity, natural mortality, or fishing mortality for the new 5+ group. The translated model uses the source biological inputs at age 5 as an approximation for the combined older ages.

Combining survey observations also changes their statistical properties. The sum of correlated lognormal observations does not generally follow the same likelihood as its separate components. The revised translation therefore preserves the aggregate index values but not the official model's complete survey observation-error structure.

Comparisons involving abundance, SSB, and Fbar require particular care. Official age-specific abundance should be aggregated consistently to 5+ before comparison. The source age-5 F estimate is not directly equivalent to the effective F for the translated 5+ group, and the translated Fbar over ages 2–5 includes an aggregate terminal age rather than the official model's individual age-5 state.

The revised translation is intended as a simpler, internally consistent approximation of the official assessment, not an exact reproduction of its age structure or likelihood.

## Assessment represented

The canonical record represents the official 2026 ICES HAWG assessment, fitted for 1991–2025.

The production run is identified as `WBSS_HAWG_2026`, a single-fleet SAM assessment available from stockassessment.org.

The official native model object is cached locally with the full HAWG 2026 report and the ICES Stock Assessment Graphs source page.

The native object reports SAM 0.12.0, optimizer convergence code 0, and objective value 414.9946.

The canonical assessment database retains the original official-model definitions and age structure. The reduced 0–5+ representation is a downstream tinyAM translation decision, not a change to the official assessment records.

## Inputs and assumptions

The cached official fit contains 315 total catch-at-age observations and 372 finite survey observations, with five HERAS observations missing in 1999.

It also contains annual stock and catch weights, maturity, fixed natural mortality, spawning fractions, and observation precision weights.

Survey identities, original age ranges, plus groups, and sampling fractions are retained in the canonical database.

Natural mortality is fixed, time-invariant, and age-specific, based on North Sea autumn-spawning herring and profiled during the 2025 benchmark. The official production model specifies `mortalityModel = 0`.

Maturity is time-invariant. The fractions of annual fishing and natural mortality occurring before spawning are 0.168 and 0.25, respectively.

The official SAM model uses a hockey-stick stock-recruitment relationship (`stockRecruitmentModelCode = 61`), separate recruitment-process variance, and a shared survival-process variance across ages 1–8.

Fishing mortality states exhibit AR(1) correlation across ages, with ages 7 and 8 sharing a single F state.

HERAS, GERAS, and IBTS/BITS Q1 use correlated age-specific observation errors, while N20 errors are independent.

The official `keyLogFpar` configuration defines catchability sharing across survey and age groups. The revised tinyAM translation preserves the corresponding groups where possible following age aggregation.

## Output checks

Official recruitment, SSB, Fbar for ages 2–5, and total stock biomass extracted from report Table 3.6.11 agree with the native SAM fit after expanding F states using `keyLogFsta`.

Differences are less than one unit for counts and biomass, and less than 0.00051 for Fbar, consistent with report rounding.

The native numbers-at-age and F-at-age estimates agree with report Tables 3.6.12–3.6.13 to displayed precision.

For 2025, the official assessment reports:

- Recruitment: 20,038,259 thousand fish.
- SSB: 110,526 tonnes (95% CI 85,439–142,978).
- Fbar: 0.011 (95% CI 0.008–0.015).
- Total stock biomass: 266,183 tonnes.

These are official-model outputs, not results from the revised tinyAM fit.

## Source references

- ICES HAWG 2026, *Report of the Herring Assessment Working Group*, Section 3.6, pp. 173–174 and Tables 3.6.4–3.6.13, pp. 247–256: [cached report](../source_cache/ices_herring_western_baltic_2026/HAWG_2026_Full_Report.pdf).
- ICES Benchmark Workshop on Selected Herring and Sprat Stocks (WKBHERSPRAT), 2025, DOI [10.17895/ices.pub.31538287](https://doi.org/10.17895/ices.pub.31538287).
- Official native SAM object `WBSS_HAWG_2026/run/model.RData`, cached at [model.RData](../source_cache/ices_herring_western_baltic_2026/model.RData).
- ICES Stock Assessment Graphs, source-data key 21294: [official source page](https://sg.ices.dk/ViewSourceData.aspx?key=21294), cached at [HTML copy](../source_cache/ices_herring_western_baltic_2026/ICES_Stock_Assessment_Graphs_key_21294.html).

## Remaining limitations

The original age-specific survey plus-group inconsistency has been addressed by aggregating the tinyAM population and observation age structure to 0–5+.

Remaining differences include the official hockey-stick recruitment relationship, cross-age survey observation correlations, the full age-specific F-state structure, and the use of source age-5 biology for the translated 5+ population group.

The source report does not provide complete age-specific uncertainty for the population and mortality surfaces.

Official model states may be used to initialize the tinyAM fit, but any starting values for the translated 5+ state should represent the aggregated older ages rather than the official model's individual age-5 values.

Inspect the current diagnostics and comparison definitions before interpreting this translation.
