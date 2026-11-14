# Gulf golden tilefish, SEDAR 22 (2011)

**Unit:** NOAA Stock SMART 10383, Gulf of Mexico golden tilefish  
**Assessment:** SEDAR 22 central Stock Synthesis run; data through 2009
**Curation reviewed:** 2026-11-12

## Assessment identity and status

NOAA's current golden-tilefish resources page still identifies SEDAR 22 (2011)
as the latest Gulf assessment. The report specifies Stock Synthesis 3.10g and
selects the central run for reporting. NOAA Stock SMART labels it **Partial
acceptance - Status determinations only**. The Gulf SSC concluded that the
model did not capture stock dynamics well enough to support quantitative OFL
and ABC advice and recommended a landings-based approach. The outputs below are
therefore preserved assessment results, not endorsed quantitative advice.

The Gulf unit is distinct from the South Atlantic and Mid-Atlantic golden
tilefish units. NOAA's 2026 Gulf data-triage papers document newer samples but
are not a completed replacement assessment; none of their data were mixed into
the SEDAR 22 record.

## Inputs and biology recovered

The canonical import preserves the assessment's reported input structure:

- Table 2.1 commercial landings for four handline/longline and east/west
  strata, in gutted pounds, 1965-2009. The source has no 1970 row; none was
  added.
- Table 2.2 recreational landings by east/west Gulf, in gutted pounds,
  1987-2009.
- Table 2.3 commercial discard counts: 981 handline and 3,509 longline fish
  combined across 2002-2009 for confidentiality. They cannot be assigned to
  individual years or regions. The report says discards were combined with
  landings, assumed 100% mortality, and converted using 5.2 gutted pounds per
  fish; the database retains the source counts and does not invent that
  allocation.
- Table 2.5 commercial longline and NMFS bottom-longline standardized indices
  for east and west regions, with 52 non-missing index values and their
  reported log-scale standard errors. Missing index years remain absent.
- Table 2.4 age-error SDs for mean coded ages 0.5-30.5, based on two readers
  and the report's smoothed age-precision relationship.
- Appendix A raw counts at 2-cm total-length bins (20-114 cm) from 150
  fishery/survey, region, year and sex samples. The two printed length ranges
  are paired by sample. Raw sample totals are retained separately; the
  likelihood sample size applies the reported cap of 200.
- Appendix B raw age counts conditional on 2-cm length bins, ages 2-30, from
  967 strata. Age 30 is the plus group. Raw totals are retained separately;
  the likelihood sample size applies the reported cap of 100.

The report describes two regions with no movement, sex-specific growth,
fixed weight-length relationships, female maturity at 50% near age 2, and a
fixed M reference of 0.137 at age 4 with regional and sex-specific Lorenzen
curves derived from growth. The full numerical model-compatible weight-at-age,
maturity-at-age, and M-at-age surfaces were not tabulated in the reviewed
production sources and were not reconstructed. Fractional within-year survey
timing was also not specified and remains unknown.

The fitted observation structure includes length compositions and age
compositions conditional on length. The report does not provide direct annual
catch numbers-at-age or an age-specific abundance index. The canonical records
therefore preserve the conditional source tables rather than relabeling them
as catch-at-age or index-at-age series.

## Outputs recovered and limits

Table 3.7 supplies central-run estimates for 1965-2009, plus a virgin reference:
east and west total biomass, female gonad-weight spawning biomass, age-0
recruitment, and a Gulf-wide F proxy. Annual outputs have no reported standard
errors or intervals. The table's Gulf-wide “F” is exploitation rate (catch
divided by total biomass), not instantaneous or age-specific fishing mortality.
Numeric annual N-at-age and F-at-age surfaces were not found in the reviewed
report.

Spawning biomass is reported as female gonad weight in thousand pounds. It is
not conventional mature somatic biomass. This definition and the exploitation
rate proxy remain explicit in the imported output notes.

## Sources and local cache

- [NOAA Golden Tilefish resources](https://www.fisheries.noaa.gov/species/golden-tilefish/resources) — latest Gulf assessment listing.
- [SEDAR 22 Gulf Tilefish assessment report](https://sedarweb.org/documents/sedar-22-final-stock-assessment-report-gulf-of-mexico-tilefish/) — Tables 2.1-2.5, 3.7 and Appendices A-B.
- [Gulf SSC review of SEDAR 22](https://sedarweb.org/documents/report-of-the-gulf-of-mexico-ssc-review-of-the-sedar-22-tilefish-assessment/) — acceptance scope and advice limitations.
- [SEDAR 22 DW-01](https://sedarweb.org/documents/s22dw01-golden-tilefish-lopholatilus-chamaeleonticeps-age-growth-and-reproduction-from-the-northeastern-gulf-of-mexico-19851997-2009/) — age, growth and reproduction.
- [SEDAR 22 AW-01](https://sedarweb.org/documents/s22aw01-united-states-commercial-longline-vessel-standardized-catch-rates-of-golden-and-blueline-tilefish-in-the-gulf-of-mexico-1992-2009-revised/) — commercial longline index.
- [SEDAR 22 project page](https://sedarweb.org/assessments/sedar-22/) — project and later data-triage materials.

Authoritative PDFs and the NOAA resources page are cached locally under
`source_cache/discovery_noaa_gulf_tilefish_sedar22_2011/`. Retrieval dates,
revisions, sizes and SHA-256 checksums are listed in
`provenance/discovery_noaa_gulf_tilefish_sedar22_2011/sources.csv`.
