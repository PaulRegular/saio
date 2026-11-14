# Southern Argentine hake, south of 41°S (2025 assessment)

## Assessment and unit

The latest detailed production assessment found for the southern `Merluccius
hubbsi` unit is INIDEP Official Technical Report 47/2025, dated 26 November
2025. It assesses the population through 2024 and recommends biological catch
advice for 2026. The official Consejo Federal Pesquero Act 34/2025 cites this
report and sets the 2026 maximum catch for the southern unit. No later detailed
age-structured assessment report was located in the sources reviewed through
7 November 2026.

The assessment unit is the southern effective south of 41°S. The report says
the stock is most abundant from 42°S to 48°S, between 50 m and 400 m depth.
There is no matching stock record in the current database.

The assessment report is a signed INIDEP document, publicly available as a
copy hosted by Fishery Progress. The CFP act is hosted by the official
Consejo Federal Pesquero site and independently confirms the report number,
assessment year and management use. A direct INIDEP-hosted copy of the 2025
assessment report was not located.

## Published inputs and outputs

The report describes an annual statistical catch-at-age model implemented in
ADMB. It combines estimated catch-at-age from Argentine and foreign fisheries,
discard and bycatch information, survey series and commercial CPUE.

| Source | Published information | Coverage and units |
|---|---|---|
| Table 6 | Population weight-at-age at 1 January and 1 July, maturity proportion-at-age, and natural mortality | Ages 1–6 and 7+; weights in kg; M is 0.3 per year at every age |
| Table 7 | Summer indices for age-2 recruitment and reproductive biomass | Selected years from 1995–2024; age-2 abundance in fish per trawl-hour and reproductive biomass in kg per trawl-hour |
| Table 8 | Winter global-survey numbers-at-age | Selected years from 1996–2016 and 2024; ages 1–6 and 7+; thousands of fish |
| Table 9 | Estimated catch numbers-at-age and total catch | 1986–2024; ages 1–6 and 7+; thousands of fish and tonnes |
| Table 10 | Independent fresher-fleet CPUE series | 1986–1997, 1998–2007, and 2009–2024; kg per trawl-hour; the three time periods are separate estimates |
| Table 11 | Model-estimated total biomass, spawning biomass, recruitment and scalar fishing-mortality component, each with a CV | 1986–2024; biomass in tonnes; recruitment units are not stated in the table; CV is reported as a ratio |
| Table 12 | Model-estimated numbers-at-age | 1986–2024; ages 1–6 and 7+; thousands of fish |

Table 7 uses dashes where the report does not provide or use an index; they are
not zero observations. Table 8 is a discontinuous survey series. The report
explains that some surveys were incomplete or omitted. Table 9 combines
estimated catches across fisheries and sources rather than publishing a
fleet-by-age split in that table.

## Source checks and unresolved details

- The report identifies summer and winter survey seasons, but the reviewed
  material does not give a precise within-year sampling fraction.
- Tables 9 and 12 were checked against rendered report pages before import.
  In Table 12, the 2009 age-2 cell appears as `147038.0` in the printed table;
  it was transcribed as 1,470,380 thousand fish, interpreting the internal
  spacing/decimal as a thousands-grouping artifact consistent with the table's
  other entries. This is a documented reading of the source, not an independent
  model estimate.
- Table 11 reports coefficients of variation, not standard errors. These must
  retain their CV scale and must not be entered as standard errors.
- Table 11 does not state the unit of recruitment. The Table 12 abundance scale
  suggests thousands of fish: its recruitment values match Table 12 age-1
  abundance within report rounding. The database records that unit as an
  inference in the row notes rather than as an explicitly printed unit.
- Numerical annual age-specific fishing-mortality outputs were not located in
  the report tables reviewed; Table 11 reports a scalar F component only.

The import preserves the original reported series and their separate meanings:
aggregate catch-at-age and tonnes, survey abundance-at-age, two summer indices,
three period-specific CPUE series, biological inputs, reported population
outputs and their CVs. Total abundance is derived only by summing the reported
age groups; no uncertainty is assigned to that derived total. Assessment input,
output and assumption coverage are marked partial because exact survey timing,
age-specific F, fleet-level catch-at-age and several fitted-state details are
not available in the reviewed report tables.

## Sources

- Santos, B. A., M. F. Pedernera, and A. Suby. 2025. *Evaluación del estado de
  explotación del efectivo sur de 41° S de merluza (Merluccius hubbsi) y
  estimación de la captura biológicamente aceptable para 2026*. INIDEP Official
  Technical Report 47/2025, signed 26 November 2025. Public copy:
  [report PDF](https://fisheryprogress.org/system/files/INIDEP%20Official%20Technical%20Report%20No%2004742%20pp%202025.pdf).
- Consejo Federal Pesquero. 2025. Acta 34/2025:
  [official act PDF](https://cfp.gob.ar/actas/ACTA%20CFP%2034-2025.pdf).
