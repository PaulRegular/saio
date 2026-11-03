# West of Scotland and Ireland seabass

## Catalogue identity and current advice

The Charbonneau–Keith entry `ICES-WGSCE_labrax_IS6a,7b,7j` corresponds to
European seabass (*Dicentrarchus labrax*) in ICES divisions 6.a, 7.b, and 7.j,
stock code `bss.27.6a7bj`. The current 2026 ICES advice is category 6 and
reports landings only. The published advice limits commercial landings to
1.6 tonnes in each of 2027–2029; ICES says it cannot quantify the associated
total catches.

The ICES Stock Assessment Graphs page for assessment key 22635 contains annual
landings for 2000–2025, but no abundance, recruitment, SSB, or fishing-mortality
series. The 2023 advice describes the assessment as category 6.2 and identifies
landings as its only input. The 2017 advice for the same stock code likewise
states that no abundance or exploitation information was available and no
assessment was performed.

The detailed [2026 working-group report](https://doi.org/10.17895/ices.pub.32625759),
section 4, confirms that commercial landings were the only data supplied to
the group, that no abundance index or age-specific numbers were available,
and that stock structure and mixing with neighbouring stocks remain uncertain.
It marks 2024 and 2025 landings preliminary. Its Table 4.2 rounds the annual
totals; the SAG export retains greater published precision. ICES applies a
0.8 precautionary buffer to the previous 2-tonne landings advice, giving
1.6 tonnes per year for 2027–2029. The report's prose also says “catches”,
but its advice table and the published advice specify commercial landings.

The database retains the 2000–2025 SAG landings as source context in tonnes,
not as total catches or a fitted likelihood. It records the advice rule and
source limitations separately. The 2027–2029 recommendation of 1.6 tonnes of
commercial landings in each year is also recorded as `catch_advice`; it is not
a population-model output, and associated total catches remain unquantified.
The report's 1996, 1997 and 1999 entries are
stored as displayed zeros with a note that the table rounds to tonnes. The
1995 and 1998 table entries are censored
as less than 0.5 tonnes and are not replaced by invented point estimates.
The 2026 terminal year denotes the latest reported landings, not a fitted
model year. The advice values are recorded as management outputs, but no
population-state outputs are claimed. The stock-specific working-group report
is cached locally alongside the SAG export and advice.

## Translation decision

This is not an age-structured assessment that tinyAM can translate. The
published landings history and catch limit are useful management information,
but they do not provide catch-at-age, abundance indices, biological matrices,
or fitted population states. Do not convert the aggregate landings to
age-specific catches or treat the advised landings limit as an estimated
population output. The canonical record contains the available landings
context and the advised commercial-landings limit, but no population outputs;
no tinyAM fit or comparison dashboard is appropriate for this record.

## Sources

- [ICES 2026 advice, bss.27.6a7bj](https://asd.ices.dk/viewAdvice/7207)
- [ICES 2026 Celtic Seas working-group report](https://doi.org/10.17895/ices.pub.32625759), section 4 and Table 4.2.
- [ICES Stock Assessment Graphs, assessment key 22635](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22635)
- [ICES 2023 advice, bss.27.6a7bj](https://asd.ices.dk/viewAdvice/3429)
- [ICES 2017 advice, bss.27.6a7bj](https://www.nwwac.ie/_fileupload/Seabass/2019_Dublin/ICES_Seabass_2017_6a7bj.pdf)
