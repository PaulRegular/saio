# Historical Norwegian coastal cod catalogue unit

## Identity and selected assessment

The Charbonneau–Keith entry `ICES-AFWG_morhua_COASTNOR 1,2` represents the
former combined ICES unit `cod.27.1-2coast`, covering Norwegian coastal waters
north of 62°N. The 2021 WKBARFAR benchmark split the unit at 67°N. The current
northern and southern stocks are recorded separately as
`ices_cod_northern_coastal_2026` and `ices_cod_southern_coastal_2026`; neither
can substitute for observations for the former combined unit.

The last pre-split assessment was the **2020 AFWG assessment**, with data
through 2019. The report identifies a final user-defined VPA (SVPA), using a
terminal F derived from acoustic survey mortality, and a trial XSA for the
calibration. It discusses both commercial-catch and total-catch runs. This
corrects the earlier review, which considered only the 2018 graph record and
mistakenly concluded that no age-structured assessment was available.
The historical record `ices_cod_norwegian_coastal_combined_2020` is selected
for this catalogue unit; it is not a current assessment of either successor stock.

## Recovered data and assumptions

- AFWG Table 2.1a: commercial landings-at-age 2–10+ and annual total landings,
  1984–2019. The report describes these as ECA-estimated catches; the last
  several years are coarsely rounded. The total is not an independent series
  from the catch-at-age.
- Tables 2.13–2.15: model stock and catch weights, 1984–2019, and constant
  maturity for ages 2–10+. M is fixed at 0.2 per year. Fractions of F and M
  before spawning are zero. Survey stock weights are autumn measurements and
  may overestimate start-of-year stock weight.
- Table 2.6: acoustic abundance indices, ages 2–10+, 1995–2019, in thousands
  of fish. Ages 2–8 were used in the trial XSA and age 9 also contributes to
  survey mortality calculations; age 10+ is retained as a source observation,
  not represented as another XSA input. The survey was in September before
  2003 and October–November afterwards; exact timing is unresolved. Fjords in
  area 07 were not covered in 2013.
- ICES SAG key 13720 reports age-2 recruitment and F ages 4–7 for 1984–2019,
  plus the acoustic spawning-biomass index for 1995–2019. This index is not
  an estimate of SSB. No uncertainty is supplied for these graph values.

Table 2.19 calls its summary commercial-catch SVPA, but its reported 2019
landings (52,807 t) equal the total including recreation, not the commercial
40,107 t in Table 2.1a. Its 2019 SSB (149,598 t) also differs from the roughly
114,000 t shown for the commercial run in the narrative on printed page 23.
Its terminal F of 0.2002 matches the commercial-catch value in Table 2.18;
the total-catch terminal F is 0.2862. SAG recruitment and F match Table 2.19,
but this contradiction prevents confident attribution of the full Table 2.19
summary. The published SAG series are retained as reported indicators, with
this caveat; Table 2.19 SSB and total biomass are withheld pending verification
against the native run. The SAG biomass index must not be substituted for them.

Catch and biological inputs, assumptions and outputs remain **partial**. The
native assessment files, final population and F-at-age surfaces, precise
survey timing, and detailed VPA configuration remain unresolved. The report
also describes an alternative total-catch run including estimated recreational
catches; those age-specific values are not imported as independent inputs to
the commercial run. Their relationship to the conflicting summary needs further
checking. A tinyAM translation may be possible as an approximation using the
age-specific observations, but comparison is limited by the unresolved official
SSB and age-specific outputs; no fit or dashboard has been produced yet.

## Sources and cache

The report PDF and the 2020 SAG XML are cached locally in the gitignored
`source_cache/ck_ices_afwg_morhua_coastnor_1_2/assessment_2020/`, with source
URLs, retrieval date and SHA-256 checksums in `manifest.csv`. The R importer
also verifies the checksum of its layout-preserving text extraction from the
PDF. An earlier 2018 SAG XML remains in its separate cache directory.

- [ICES 2020 AFWG report, section 2 and tables 2.1a, 2.6 and 2.13–2.19](https://doi.org/10.17895/ices.pub.6050)
- [ICES 2020 graph XML, assessment key 13720](https://sag.ices.dk/SAG_API/StockXmlDownload/13720)
- [ICES 2020 advice](https://doi.org/10.17895/ices.advice.5893)
- [WKBARFAR 2021 benchmark](https://doi.org/10.17895/ices.pub.7920)
- [Northern coastal cod 2026](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22637)
- [Southern coastal cod 2026](https://standardgraphs.ices.dk/ViewCharts.aspx?key=23775)
