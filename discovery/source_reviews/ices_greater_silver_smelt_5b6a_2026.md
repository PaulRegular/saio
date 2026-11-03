# ICES greater silver smelt, divisions 5.b and 6.a (2026)

ICES stock aru.27.5b6a is the current greater silver smelt unit for the
Faroes grounds and west of Scotland. It is distinct from the ICES units
aru.27.5a14, aru.27.123a4, and aru.27.6b7-1012; no canonical database
stock matches this area.

## Source screen

The 2026 WGDEEP report describes a SAM assessment initiated in 1995 using
catch numbers-at-age for ages 5–21+. Table 6.3.5 provides annual catch
numbers-at-age in thousands through 2025. The 1995–2004 age data were raised
from Faroese samples to international catches; later inputs use InterCatch,
with age observations contributed by the Faroes and the Netherlands. Ages 2–4
are available in InterCatch but are not used by this assessment. Ten cells in
the printed catch table are blank (ages 19–21 in 2003–2007 and 2018); those
values remain missing in the canonical data rather than being inferred.

The assessment uses two age-specific Faroese survey series: the summer survey,
ages 5–12 in 1998–2025 (Tables 6.3.8), and the deepwater survey, ages 5–14 in
2014–2020 and 2022–2025 (Table 6.3.9). The latter is conducted in September;
2021 is explicitly marked as no survey and its -1 sentinels are not imported.
The Scottish MSS Deepwater Slope and combined Faroese–EU CPUE series are
aggregate biomass indices in Table 6.3.10. The Scottish index has 18 finite
observations from 1998–2025; the CPUE series has 21 observations from
2005–2025. Table 6.3.6 gives annual catch weights-at-age for ages 5–9.
Figure 6.3.8 plots annual weights for all assessed ages, 5–21+, in kg, so
ages 10–21+ remain unavailable as numeric rows. The report says stock weights
are assumed equal to catch weights. It cautions that weights for fish older
than 15 in 2019 may be unreliable because of a small age sample. Table 6.3.7
supplies fixed maturity proportions by age. Natural mortality is fixed at
0.15 for all ages and years.

The report provides annual SSB, recruitment-at-age-5, and Fbar-at-ages 6–14
with 95% intervals in Table 6.4.13, plus F-at-age in Table 6.3.14 and
stock-numbers-at-age in Table 6.4.15. The two age-specific output tables cover
1995–2025 and ages 5–21; age 21 is the terminal group corresponding to the
assessment's 21+ group. Table 6.4.15 has ten -1 missing-value sentinels, which
are omitted, leaving 517 reported N-at-age values. Their thousand-fish scale
is consistent with the units assigned to stock numbers in the pinned TAF
preprocessing code. No age-specific uncertainty is published for N or F.
Although the pinned public TAF repository lacks its numeric input files,
fitted RData, and generated outputs, these report tables recover the official
point estimates for N-at-age and F-at-age.

The report identifies the summer survey by season and the deepwater survey as
a September survey. The TAF code obtains survey start/end fractions from
survey.dat, but that raw file is absent from the pinned public repository.
The published survey table does not identify the measurement unit, and the
numeric survey file is not public. Exact annual survey timing fractions
therefore remain unresolved and must be checked during source curation before
a tinyAM translation.

## Decision

Eligible for source curation as a new assessment unit. This is not yet a
translation-readiness decision. The detailed report supports the core catch,
survey, biology, and mortality records, plus comparable official outputs for
SSB, recruitment, Fbar, N-at-age, and F-at-age. The canonical input series
remain partial because numeric weights for ages 10–21+, ten blank catch-age
cells, exact annual survey timing fractions, and the raw fitted model inputs
were not recovered. Output uncertainty is available only for SSB, recruitment,
and Fbar. The TAF scripts and report values do not include a fitted SAM object.

## Sources and cache

The authoritative 2026 WGDEEP report is ICES Scientific Reports 8:30,
DOI 10.17895/ices.pub.32051352.v1:
https://doi.org/10.17895/ices.pub.32051352.v1

The current advice is ICES advice record 7183:
https://asd.ices.dk/viewAdvice/7183

Standard Graphs source data key 23736:
https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23736

SAG XML:
https://sg.ices.dk/SAG_API/StockXmlDownload/23736

The public assessment scripts are pinned to TAF commit
7b7436c9e90c66c18411b7bf53bdf3ff096e5b33:
https://github.com/ices-advice/2026_aru.27.5b6a/tree/7b7436c9e90c66c18411b7bf53bdf3ff096e5b33

Downloaded sources, retrieval dates, byte counts, URLs, revisions, and SHA-256
checksums are recorded in
source_cache/discovery_ices_gss_5b6a_2026/sources.csv; the cache is
gitignored.
