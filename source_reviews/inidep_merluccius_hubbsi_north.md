# Northern Argentine hake (2025 assessment)

## Assessment and unit

The latest detailed assessment located for the northern *Merluccius hubbsi*
effective is INIDEP Official Technical Report 43/2025. It assesses the unit
through 2024 and provides biological catch advice for 2026. The Consejo Federal
Pesquero's Act 34/2025 identifies this report among the assessments presented
for 2026 advice. Resolution 16/2025 subsequently sets the northern unit's 2026
maximum catch at 28,700 tonnes.

The assessed biological effective is north of 41°S. The report says that the
unit is managed by the Argentina-Uruguay CTMFM in the Common Fishing Zone and by
Argentina between the southern edge of that zone and 41°S. Its catch table
includes Argentina, Uruguay and Brazil. The 2025 INIDEP assessment is recorded
as a distinct northern stock from the southern effective south of 41°S.

The official INIDEP repository record identifies the report as a 2025
Technical Report 43, with a 1986–2024 assessment period. Its original bundle
contains the report PDF. The CFP Act provides independent confirmation that the
report was used for 2026 advice; the CFP resolution records the resulting
management limit.

## Published inputs and outputs

The report describes an annual statistical catch-at-age model implemented in
AD Model Builder, with ages 1–6 and a 7+ group.

| Source | Published information | Coverage and units |
|---|---|---|
| Table 1 | Annual catches by country and, from 2000, Argentine management area; total catch and historical catch limits | 1986–2024; tonnes. The 1986–1999 Argentine subarea split is not shown. The published 2000 country components sum to 49,244 t while the reported total is 47,210 t. |
| Table 2 | Estimated catch numbers-at-age from observer and INIDEP age data | 1986–2024; ages 1–6 and 7+; thousands of fish. The methods describe the fitted age compositions as coming from the Argentine trawl fleet. |
| Table 3 | Commercial catch weight-at-age | 1986–2024; ages 1–6 and 7+; kg per fish. |
| Table 4 | Standardized Argentine fresher-trawl CPUE | 1986–2016 and 2017–2024; kg per trawl-hour. These are two separate time series. |
| Table 5 | Global-survey abundance-at-age | Selected years 1996–2016; ages 1–6 and 7+; thousands of fish. The report does not use the 2021–2022 survey age compositions because they were not representative of the full effective. The model also uses a global-survey biomass index, but its observed values are not tabulated. |
| Table 6 | Population weight-at-age from the 1997 survey, recalculated to 1 January | Ages 1–6 and 7+; kg per fish. This is distinct from the annual commercial catch weights in Table 3. |
| Table 7 | Fixed natural mortality and maturity proportion-at-age | Ages 1–6 and 7+; M = 0.3 per year for all ages and years. |
| Table 8 | Age-2 juvenile-survey index, assigned to the following January | 1995, 1996, and 1998–2000; thousands of fish per trawl-hour. The observations were collected in December of the preceding year. |
| Table 9 | Aldebarán juvenile age-1 abundance indices from spring and autumn surveys | Selected years 1991–2011; thousands of fish per square nautical mile. |
| Table 11 | Estimated total biomass, spawning biomass and recruitment under scenarios E1–E3 | 1986–2024; biomass in tonnes and recruitment in thousands of fish. The table reports no uncertainty measures. |
| Table 12 | E2 short- and medium-term catch advice for two spawning-biomass targets | 2026 biologically acceptable catch; tonnes. |

The model treats annual commercial catches as nearly exact (log-scale CV
0.001), uses multinomial age-composition likelihoods with effective sample
sizes based on the original sub-sample counts, and fits separate dome-shaped
selectivity blocks for 1986–1990, 1991–1996, 1997–2013 and 2014–2024. It uses
fixed M = 0.3, Beverton–Holt recruitment, and annual recruitment deviations.
The report specifies the global survey in September (0.75), the age-2 juvenile
index assigned to 1 January (0), the Aldebarán autumn index in May (0.417), and
the spring index in September (0.75). It does not report a within-year date for
the annual CPUE series. December age-1 juvenile observations are assigned to
age 2 at the start of the following year.

Scenarios E1–E3 vary the assumed CV for the 2021–2022 global biomass index
(0.1 versus 0.3); E3 also increases the recruitment-error CV from 0.3 to 0.6.
Table 11 provides aggregate biomass and recruitment trajectories for all
three scenarios. The report does not provide annual numerical model-estimated
N-at-age or F-at-age tables, nor uncertainty for the reported state estimates.
Table 12 reports four E2 catch-advice values: 40,507 and 48,461 tonnes for the
150,000-tonne spawning-biomass target, and 13,593 and 31,570 tonnes for the
230,000-tonne target, for the short and medium terms respectively.

## Source checks and unresolved details

- The INIDEP repository item is the current 2025 report; no model code, fitted
  object, or separate numerical input file is attached to its original bundle.
- Table 2 is an estimated age-count series, while the likelihood is applied to
  age proportions. The report describes the composition observations as from
  the Argentine trawl fleet but does not publish a fleet-by-age breakdown.
- Table 1 distinguishes country catches and, from 2000, Argentine catches in
  the ZCPAU and adjacent Argentine waters. Its earlier Argentine subarea split
  is not available. Blank table cells are not zeros. In 2000 the published
  Argentina (19,787 t), Brazil (2,260 t), and Uruguay (27,197 t) entries sum to
  49,244 t, not the table's 47,210 t total. The published values are retained
  without correction. In 2021 the two Argentine subarea values differ from the
  reported Argentine total by 1 t, consistent with rounding.
- Table 5 age compositions are discontinuous and exclude the 2021–2022 survey
  age structures. The biomass indices for those two years are included in the
  scenario analyses with varying CV assumptions. Although the model uses a
  global-survey biomass index, the report does not provide its complete
  observed numerical series; Table 5 reports numbers-at-age, not the fitted
  biomass-index observations. Those values have not been derived or digitized.
- The model uses six abundance-index series: the global survey, two juvenile
  indices, and CPUE series for 1986–2016 and 2017–2024. The report does not
  provide annual effective sample sizes for its composition likelihoods.
- The annual F values in the report's equations are scalar multipliers of the
  age-selectivity pattern. Numerical age-specific F and N estimates are not
  tabulated, so they are not inferred here.
- The fitted q values and observation likelihood weights are not published as
  a numerical parameter table. The two CPUE periods have separate q values.
- Table 11's recruitment unit is explicitly thousands of fish. No standard
  errors or CVs are reported for its aggregate trajectories.
- The legal 2026 catch limit is a CFP management decision, not an additional
  model estimate; it is kept separate from the report's conditional CBA values.

The source supports a detailed, age-structured input and output record. Data
and assumptions should be recorded with their original distinctions: total
catch versus country-area catches, commercial versus population weights,
composition counts versus index series, and scenario-specific outputs.

## Canonical database record

The partial 2025 assessment record preserves Table 1 catch histories and
country-area components; Table 2 catch numbers-at-age; Table 3 commercial
catch weights-at-age; Table 4 CPUE; Tables 5, 8 and 9 survey inputs; Tables 6
and 7 population weights, maturity and fixed M; and Table 11 scenario outputs.
Table 12 catch advice and the CFP catch limits are stored separately as
management results. The import does not create annual N-at-age, F-at-age, or
uncertainty values that the report does not publish. The observed global
survey biomass-index values and effective age-composition sample sizes remain
unavailable, so the completeness statuses are partial.

For a source consistency check, the Table 2 numbers-at-age multiplied by the
corresponding Table 3 weights reproduce Table 1 total catches within 0.1% in
every year. The source table's 2000 country-component discrepancy is preserved
and flagged rather than reconciled by changing a published value.

## Sources

- Irusta, C. G. 2025. *Evaluación de la abundancia del efectivo norte de 41° S
  de la merluza (Merluccius hubbsi). Estimación de la CBA para el año 2026*.
  INIDEP Official Technical Report 43/2025.
  [INIDEP repository record](https://marabierto.inidep.edu.ar/handle/inidep/5103).
- Consejo Federal Pesquero. 2025. Acta 34/2025.
  [Official act](https://cfp.gob.ar/actas/ACTA%20CFP%2034-2025.pdf).
- Consejo Federal Pesquero. 2025. Resolution 16/2025, maximum permissible
  catches for 2026.
  [Official resolution](https://cfp.gob.ar/resoluciones/Resolucion%2016%20%2811-12-25%29%20CMP%20merluza%20comun%2C%20polaca%2C%20cola%20y%20negra%202026.pdf).
