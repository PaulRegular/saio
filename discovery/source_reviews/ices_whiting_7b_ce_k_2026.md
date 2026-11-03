# Celtic Sea whiting, 2026 ICES assessment

## Assessment and sources

This record represents the current ICES unit *Merlangius merlangus* in divisions 7.b, 7.c and 7.e-k, assessed by WGCSE in 2026 for 2027 advice. The latest detailed production chapter is [WGCSE 2026, chapter 27](https://doi.org/10.17895/ices.pub.32625759.v1). Its assessment outputs were cross-checked against [ICES Stock Assessment Graphs key 23780](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23780) and the machine-readable [key 23780 XML](https://sag.ices.dk/SAG_API/StockXmlDownload/23780). The [current Stock Annex v2](https://doi.org/10.17895/ices.pub.23501757.v2) provides method and input-structure detail. Source files, file identifiers, retrieval dates, byte counts and SHA-256 values are recorded in the ignored local cache at `source_cache/ices_whiting_7b_ce_k_2026/`.

The 2026 run uses observations through 2025. ICES also reports 2026 aggregate SSB and recruitment as forecasts. Age-specific catch, F and N tables cover 1999-2025; the biological tables use ages 0-7+, with age 7 as the plus group. The unit is distinct from the Irish Sea 7.a whiting record and North Sea whiting.

## Imported inputs

- **Catch:** WGCSE Table 27.3 supplies total catch numbers-at-age, ages 0-7+, 1999-2025, in thousands of fish. The Stock Annex says SAM estimated discard numbers at ages 5-7+ during 1999-2002; later discard estimates use InterCatch sampling. The age series is therefore not wholly observed at those early older ages. The XML reports annual landings and discards in tonnes for 1999-2025, but its total-catch field is blank. The aggregate components are retained as provenance and are not separate likelihood inputs alongside catch-at-age.
- **Catch weights:** Table 27.4 values are retained numerically and represented as kg/fish. The table labels them tonnes; paired with Table 27.3 values in thousands of fish, tonnes per thousand fish is numerically kg per fish. This unit interpretation is documented in each row; no number was rescaled.
- **Stock weights:** Table 27.7 provides Q1 / January 1 Rivard-corrected stock weights, ages 0-7+, 1999-2025, in kg/fish. Table 27.5 was checked and is numerically identical; only the explicitly Q1 series is stored.
- **VAST survey:** Table 27.8 provides the combined FR-EVHOE and IE-IGFS Q4 IBTS abundance-density index for ages 0-2, 2003-2025. The source unit is No/km². These are age-specific index values, not age-composition sample counts. The exact within-year survey fraction used by the assessment was not recovered.
- **Commercial index:** Table 27.9 provides the French FRA-OTB commercial biomass/LPUE index in kg/hour, 2000-2025. The Stock Annex describes its use as a biomass index to avoid reusing age-composition information in a numbers-at-age index.
- **Biology:** The production chapter prints fixed age-specific natural mortality and maturity values for ages 0-7+. These are stored as reported in the chapter rather than replaced with values from an earlier annex summary.

## Imported outputs

The production chapter provides estimated fishing mortality-at-age (Table 27.10) and stock numbers-at-age (Table 27.11), 1999-2025, ages 0-7+. ICES Standard Graphs supplies age-0 recruitment, SSB and Fbar ages 2-5 for 1999-2025 with 95% interval endpoints, plus forecast SSB and recruitment for 2026. The interval endpoints are preserved as `lwr`/`upr`; no standard errors were derived. Age-specific F and N uncertainty was not available in the reviewed tables.

## Model assumptions and source differences

The Stock Annex identifies SAM, an annual age-0 to 7+ model, a Q4 VAST survey index at ages 0-2, and a French commercial biomass index. It says F states are bound for ages 6+, survey catchability for ages 1+ is bound, age-0 survey observation error is separate from the shared ages 1-2 error, and the 2020 Annex 2 configuration uses `corFlag=2` for AR(1) correlation in F across ages. The Annex configuration is dated 2020; it is framework evidence, not a run-matched 2026 configuration. The precise 2026 likelihood weights and native fitted object were not recovered.

The production chapter's fixed M values are 1.22, 0.86, 0.65, 0.50, 0.43, 0.40, 0.38 and 0.36 per year. They match the earlier WKCELT2014 reference Lorenzen values in Stock Annex Table B.2.2; that table also lists different later mean-weight estimates. The production chapter's maturity vector is 0, 0.61, 0.94, 0.97, 0.97, 1, 1 and 1. Annex Table B.2.1 instead lists a pooled vector with 0.95 at age 5 and a WGCSE knife-edge vector. Because the chapter reports values for this production assessment, those values are preserved; the source difference remains explicit rather than silently reconciled.

The Annex lists `Lf.dat` landings fractions at age, but the run-matched numerical series was not recovered. It also notes modeled early discard numbers. The imported inputs, assumptions and outputs are therefore marked **partial**. A downstream translation can use the verified series only with explicit approximations; source completeness does not imply translation readiness.

## Validation

The importer checks the cache manifest's file sizes and SHA-256 values, the ICES stock key and assessment year, year/age coverage for each report table, the exact production M and maturity vectors, equality of stock-weight Tables 27.5 and 27.7, and 95% interval ordering in the ICES XML. The source test also checks representative catch, index, biological, F/N, SSB, recruitment and Fbar values. No missing observation or scale factor is invented.
