# Celtic Sea herring: 2026 source review

## Assessment unit and run

ICES stock `her.27.irls` is the Celtic Sea autumn and winter spawning herring assessment unit: Division 7.a south of 52°30′N and divisions 7.g, 7.h, 7.j, and 7.k. The 2026 HAWG update is the current applied ASAP assessment, with terminal year 2025. The assessment year runs from 1 April through 31 March and is labelled by its first year. Ages are winter rings; age 9 is the plus group.

This is a distinct management assessment from Irish Sea herring (`her.27.nirs`). The 2026 HAWG report describes unquantified mixing between the two units and uncertainty about whether 7.h belongs in the Celtic Sea stock area. Existing 6.a and 6.aS/7.b-c herring records are different assessment units, not aliases.

## Recovered inputs

The HAWG 2026 report contains detailed numeric tables for the applied run. The source import preserves the tabulated values, units, years, ages, missing cells, and distinctions between input observations and biological samples.

| Input | Coverage | Source and treatment |
|---|---|---|
| Catch numbers-at-age | 1958–2025; winter-ring ages 1–9+ | Table 6.6.1.1; values retained in thousands of fish, as represented in the ASAP input table. |
| Total catch in weight | 1958–2025 | Table 6.6.1.1; tonnes, retained separately from catch numbers-at-age. The printed 2025 value is 987 t. |
| Catch weight-at-age | 1958–2025; ages 1–9+ | Table 6.6.1.1; kg per fish. The 2025 age-9+ cell is blank and remains absent. |
| Stock weight-at-age | 1958–2025; ages 1–9+ | Table 6.6.1.1; kg per fish, at spawning time. The 2025 age-9+ cell is blank and remains absent. Biological samples for stock weights are from Q4. |
| Maturity-at-age | Time-invariant; ages 1–9+ | Table 6.6.1.1; 0.5 at age 1 and 1 at ages 2–9+. |
| Natural mortality-at-age | Time-invariant; ages 1–9+ | Table 6.6.1.1; fixed at 0.767, 0.385, 0.356, 0.339, 0.319, 0.314, 0.307, 0.307, and 0.307 per year. The report attributes these values to the HAWG 2015 procedure using an SMS run from 2011. |
| Acoustic abundance index | 2002–2025; winter-ring ages 2–7 plus total | Table 6.6.1.2; values are retained as printed in thousands of fish. CV is 0.5 in survey years. The table's total and age-specific values are overlapping summaries of the same index, not independent series. |
| Acoustic sample count | 2002–2025 | Table 6.6.1.2 sample-size column is the number of hauls with sufficient herring. It is preserved on the aggregate index rows and is not treated as the index's effective likelihood sample size. |
| Catch-total CV | 1958–2025 | Table 6.6.1.3 states 0.2 for all years; the assessment fits total catch in weight. |

The assessment excludes survey data for 2004 (no survey), 2017 (insufficient biological data), and 2024 (no mature fish encountered). The table prints -1 for the first two unavailable years and zero for 2024; missing years are not imported as observations, while the printed 2024 zero rows and zero CV are retained with an explicit note that they were excluded from tuning. A single unavailable age-7 observation in 2006 is omitted.

The ASAP settings specify an October index month. Because the model year begins in April, the import represents October at the midpoint of that model year (`sampling_time = 0.5`). Exact annual sampling-time fractions were not recovered; the 2025 survey ran from 9–29 October.

## Recovered assumptions and outputs

Table 6.6.1.3 identifies no discards, Fbar ages 2–5, survey tuning ages 2–7, survey selectivity fixed at ages 3–5, fishery selectivity fixed at age 3, survey CV 0.5, total-catch CV 0.2, and likelihood weights of 1 for the acoustic index and total catch. Catch-composition sample sizes use Irish sampling-programme sample counts and are down-weighted to 5 for 2015–2025; exact year-specific effective sample sizes are not given. The published maturity and M vectors are retained as fixed time-invariant inputs.

Table 6.6.1.4 provides annual catch, SSB, total biomass, Fbar ages 2–5, and age-1 recruitment for 1958–2025. The import records point estimates only: the table does not provide uncertainty intervals. SSB and total biomass are in tonnes; recruitment is represented in thousand fish, consistent with the ASAP population scale. Fitted numerical N-at-age and F-at-age values were not recovered.

## Source conflicts and limits

Two numerical conflicts in the published input/output tables remain unresolved. The 2019 acoustic input table prints age-2 abundance as 98,229 while its total index is 8,873; the age-2 value exceeds the reported total. The 2025 ASAP input table prints total catch as 987 t, while the assessment summary table reports 687 t. Both values are imported in their separate source contexts without correction. The pinned public TAF snapshot does not contain the raw Lowestoft bootstrap files, applied ASAP DAT/executable, or fitted numerical result object needed to determine whether the conflicts are table errors, revisions, or differences in model-year/data treatment. These conflicts must be reviewed before attempting a close translation.

The TAF output script writes N-at-age and F-at-age files, but those generated arrays are not in the pinned public repository snapshot. The annual summary table also has no uncertainty intervals. Exact year-specific catch effective sample sizes, annual survey timing, and the applied software build remain unavailable.

The input tables report no 9-ring fish in 2025; corresponding catch-weight and stock-weight cells for age 9+ are blank. No value is imputed.

## Provenance

The locally cached HAWG full report, ICES SAG and advice pages, and scripts from the pinned TAF snapshot are listed with URLs, retrieval dates, and SHA-256 checksums in the gitignored `source_cache/discovery_ices_celtic_sea_herring_2026/sources.csv` manifest. The import is pinned to the report SHA-256 `A0C3928FDE2693CBBCC176ABFB7450E7F426E47898D2020529E1FB563542BB66` and extracted-table text SHA-256 `8CBE6EFE0D82F03F9D4F87EDF4D16FBCC48B491017532140803DD8A69A557FC6`.

- [ICES HAWG 2026 full report, section 6 and Tables 6.6.1.1–6.6.1.4](https://doi.org/10.17895/ices.pub.31424315)
- [ICES SAG assessment graphs, key 21307](https://standardgraphs.ices.dk/ViewCharts.aspx?key=21307)
- [ICES Advice and Scenarios Database, Celtic Sea herring 2026](https://asd.ices.dk/viewAdvice/4064?handler=SubComm)
- [Pinned ICES advice TAF snapshot](https://github.com/ices-advice/2026_her.27.irls/tree/cf29535caedd3b97d1912a1fd5b37be350e3d916/2026_her.27.irls_assessment)

## Curation status

The source import is **partial**. Detailed age-specific inputs, fixed biology and mortality, selected model settings, and aggregate official outputs are present. The source-table conflicts, absent raw run files, missing fitted age-specific outputs, and unavailable uncertainty prevent a complete validation of the applied assessment.
