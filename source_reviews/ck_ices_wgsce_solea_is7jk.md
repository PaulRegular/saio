# Sole catalogue entry `IS7jk`: current advice is not age-structured

## Identity and current assessment

The Charbonneau–Keith identifier is `ICES-WGSCE_solea_IS7jk`. Its area label
does not exactly match the current ICES advice unit, sole in divisions 7.h–k
(`sol.27.7h-k`), which includes 7.h and 7.i as well as 7.j–k. The catalogue
suffix alone therefore does not establish a one-to-one stock-boundary match.

The latest ICES advice located is the 2026 triennial advice, category 5, for
`sol.27.7h-k`. The 2026 WGCSE report identifies this as one of its category-5
stocks; it is not among the age-structured assessments. The 2026 Advice and
Scenarios Database record advises catches of 136 tonnes in each of 2027–2029.
The 2023 stock-assessment graph series contains landings and discard history,
not fitted abundance, recruitment, SSB, or fishing-mortality-at-age surfaces.

## Database and translation decision

The historical catalogue label and the current 7.h–k advice unit have not
been established as identical. The broader current unit is represented
separately as `ices_sole_celtic_south_7hk`; see its
[source review](ices_sole_celtic_south_7hk.md). No broader-unit values are
relabeled as 7.j–k-only observations.

The 2019 WGCSE report contains an XSA run fitted to the 7.j–k component,
used for relative trends in 7.h–k advice. The 2020 benchmark replaced it
because 7.h was inadequately represented and model fits were poor. The
database retains it as `ices_sole_7jk_2019_xsa`, a historical run, not a
current assessment of 7.h–k. Its `is_current` flag selects the detailed
historical run for this separate 7.j–k catalogue record only.

## Recovered historical inputs and outputs

The 2019 report provides landings numbers and weights at ages 2–16+ for
1993–2018, an Irish VMS commercial index and the fixed M and maturity ogive.
The XSA combined ages 10+ and used index ages 3–9 in 2006–2018. The original
age tables are preserved without assuming how the 10+ weights were computed.
Weights are in kg, as labelled in Figure 33.5. The landings table does not
label its numbers scale. Multiplying numbers by weights gives approximately
246 tonnes in 1993, matching the reported 246 tonnes if the numbers are in
thousands. But the same calculation gives approximately 296 tonnes for 1999,
while the reported total is 200 tonnes. Until the discrepancy and number
scale are resolved, the table is retained on its reported, unspecified scale
and must not be silently converted into tinyAM observations.

The source reports annual SSB, recruitment and Fbar for 1993–2018 and N and
F at age for 2009–2018. These are historical 7.j–k XSA values; 2019 advice
used the assessment for relative trends. The report and 2019 SAG XML disagree
on the 2019 recruitment figure, so 2019 projection values are omitted. The
reported 2018 age-2 weight and several observations are zero; they are
preserved as published, with no replacement values invented.

## Translation status

The 2019 assessment is a potential historical comparison, but a defensible
fit requires resolving the number scale and catch-total inconsistency, the
10+ group construction, and zero weights/observations. No model or dashboard
is claimed until those issues are resolved and the relevant translation
instructions have been followed.

The WGCSE 2026 report, advice page, and their checksums are cached under
`source_cache/ck_ices_wgsce_solea_is7jk_2026/`.

## Sources

- [WGCSE 2026 report](https://doi.org/10.17895/ices.pub.32625759)
- [ICES 2026 advice record 6146](https://asd.ices.dk/viewAdvice/6146)
- [ICES SAG source data, assessment key 23719](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23719)
- [ICES 2023 active advice record 3460](https://asd.ices.dk/viewAdvice/3460)
- [2019 WGCSE report](https://archimer.ifremer.fr/doc/00505/61665/65580.pdf), section 38 and Tables 33.2, 7.14.3, 39.4, 7.14.5 and 33.6.
- [2020 WKFlatNSCS benchmark](https://doi.org/10.17895/ices.pub.5976), section 6.
