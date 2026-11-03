# Herring in ICES divisions 6.a and 7.b-c (combined historical unit)

## Assessment selected

The existing Charbonneau–Keith metadata row identifies the combined ICES HAWG
assessment unit (`ICES-HAWG_harengus_CS 6a,7b,7c`). Its official stock code is
`her.27.6a7bc`. This stock had no assessment, input, or output records before
this import.

The database record uses the 2020 HAWG assessment, the latest detailed update
recovered for the combined unit, with terminal year 2019. It reports the final
multi-fleet SAM assessment following the 2019 interbenchmark. The later 2022
benchmark separated 6.a North from 6.a South/7.b-c; values from those successor
units are not combined with this historical record.

## Sources and availability

- 2020 assessment: [HAWG 2020, DOI 10.17895/ices.pub.6105](https://doi.org/10.17895/ices.pub.6105).
- Previous detailed run: [HAWG 2019, DOI 10.17895/ices.pub.5460](https://doi.org/10.17895/ices.pub.5460).
- Model framework: [2019 interbenchmark, DOI 10.17895/ices.pub.5261](https://doi.org/10.17895/ices.pub.5261).
- Stock split context: [HAWG 2022 report](https://ices-library.figshare.com/articles/report/Herring_Assessment_Working_Group_for_the_Area_South_of_62_N_HAWG_/19249010).
- The report points to TAF scripts, but no public executed fit object or
  reproducible source run was recovered. The source tables therefore remain
  the basis of this transcription; exact likelihood implementation and
  uncertainty are not available from the recovered files.

The source PDFs and their checksums are recorded in the local, gitignored
`source_cache/ck_ices_hawg_harengus_cs_6a_7b_7c/source_manifest.yml`.

## Inputs recovered

The report tables cover ages 1–9 (age 9 is the plus group) for 1957–2019.
Canonical inputs include 5,764 cells:

- Catch numbers-at-age for separate `Catch 6aN` and `Catch 6aS/7bc` fleets,
  both through 2019.
- Catch weights for both fleets, stock weights, fixed natural mortality,
  maturity, and the F/M fractions occurring before spawning.
- Age-specific indices from MS_HERAS, IBTS_Q1, and IBTS_Q4. The report marks
  index units as NA; values remain on the reported scale. Source `-1` sentinels
  are recorded as unavailable, giving 21 missing cells among 661 survey cells.

The catch-number tables do not state their unit. Values are preserved without
rescaling and labeled as thousand fish on an explicitly inferred basis. The
age-0 recruitment table uses thousands. As a reasonableness check, catch
numbers multiplied by their fleet-specific catch weights track reported
landings over years with more than 100 tonnes reported (ratio 0.897–1.547);
the differences are retained rather than adjusted away. No survey multiplier
is inferred.

Table 4.6.10 gives model ages 1–9, years 1957–2019, fixed M, no stock-recruit
relationship, age-specific q groups within surveys (with the reported older-age
sharing), lognormal survey observations, and AR(1) correlation for the three
survey observation processes. Survey sampling times are stored as midpoints of
the reported intervals: MS_HERAS 0.545 (0.52–0.57), IBTS_Q1 0.125 (0.00–0.25),
and IBTS_Q4 0.875 (0.75–1.00). These are interval midpoints, not exact survey
dates. F and M fractions before spawning are both 0.67 at each age and year.

## Outputs recovered

The canonical outputs preserve the area-specific F-at-age tables for 6.a North
and 6.a South/7.b-c, reported N-at-age, and annual recruitment, total biomass,
SSB, and Fbar for ages 3–6. Total abundance is included as a derived source
output by summing the reported age-specific N for each year; it has no
uncertainty. The report does not provide numerical SEs or confidence intervals
for these tables, so uncertainty fields remain blank. Natural mortality is a
fixed input, not an estimated output.

The 2019 summary-table parser was cross-checked against its printed values:
recruitment 708,296 thousand fish, total biomass 111,872 tonnes, SSB 41,978
tonnes, landings 3,611 tonnes, and Fbar 0.0814 per year. Reported recruitment
also agrees with age-1 N-at-age to within 0.48 in the printed scale.

## Status and translation limits

The assessment, inputs, and outputs are marked partial because the recovered
report leaves some units unresolved, does not provide the native executed run,
and has no numerical uncertainty tables. The source series are otherwise
transcribed from the report tables without fitted-parameter adjustments or
invented values. Any tinyAM translation should keep the two source catch fleets
and three survey identities visible, document approximations to SAM's process
and observation-correlation structures, and treat area-specific F comparison
as approximate if the tinyAM population is represented as one combined unit.

## tinyAM translation result

The translation combines the two catch-number fleets by year and age for the
tinyAM fit; the database retains the fleet-specific inputs. It fits one pooled
correlated F process, preserves the three surveys and their q/SD sharing, and
uses independent survey-age residuals because tinyAM does not represent the
source AR(1) correlation across survey ages. Source F-at-age is summed across
the two areas only for the common total-F comparison. The fit uses package-
default starting values; no retry was made because the default fit passed
numerical checks.

The default fit converged (optimizer code 0; maximum absolute gradient 0.000716;
positive-definite Hessian). The dashboard and fitted object are cached locally
under `results/cache/ices_herring_west_scotland_ireland_2020/`. Observation
predictions are close to their inputs on average, but the derived population
series disagree substantially with the official outputs. Mean absolute percent
differences are 276.7% for N-at-age, 217.0% for total abundance, 197.3% for
biomass, 184.6% for SSB, and 266.5% for recruitment. Their terminal differences
are especially large and trend correlations are 0.535, 0.099, 0.392, 0.457,
and 0.119, respectively. Approximate total F-at-age differs by 54.9% on average
(terminal difference -78.4%; correlation 0.430), while the common N-weighted
Fbar differs by 45.2% (terminal difference -76.4%; correlation 0.600). Fixed M
is reused from the input and is not an independent fit comparison. These
results indicate weak agreement despite numerical convergence; the age-specific
source F output remains available by area in the canonical database. The
source report provides no numerical uncertainty tables, so none are shown for
the Official series.
