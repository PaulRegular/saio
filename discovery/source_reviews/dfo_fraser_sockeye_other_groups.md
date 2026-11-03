# Fraser River Early Summer, Summer, and Late Sockeye

## Unit boundaries

The DFO inventory rows Fraser Early Summer, Fraser Summer, and Fraser Late
refer to Fraser Sockeye management/run-timing groups. The PSC Stock-Recruit Data
Documentation maps individual production stock groups to Conservation Units and
then to four management groups. The Early Summer, Summer, and Late management
groups each contain multiple production groups and conservation units. The PSC
detailed file reports recruits by individual production group; it does not
publish one aggregate production-stock row for each of these three DFO inventory
labels.

These inventory rows therefore do not each identify one current assessment
stock unit. The source mapping is useful for matching the groups, but it does
not justify combining all constituent data or treating each broad group as a
single stock-level assessment. Their candidate-unit fields remain blank and
their identity status is ambiguous until an exact current assessment unit is
identified.

## Assessment inputs and output coverage

The PSC file contains age-specific recruit estimates for individual production
groups, alongside brood-year spawner estimates. The DFO 2025/021 science
advisory discusses the broader Fraser Sockeye run-size process. These data are
age-specific run-size/stock-recruit products, not an independent age-specific
abundance survey or a complete catch-at-age likelihood for a population
assessment. No single set of weights, maturity, annual F/M assumptions, timing,
and comparable age-structured output series can be assigned to any of the
three broad inventory rows without first resolving their constituent stock
units and source model boundaries.

Screen all three inventory rows as identity-ambiguous with age-input
eligibility unresolved. This records the boundary issue; it does not assert
that the underlying production groups lack data. Do not create canonical stock
or assessment records, aggregate production groups, or count the three broad
rows as three verified new stock units.

## Sources and cache

- [PSC Fraser Sockeye Stock-Recruit Dataset](https://www.psc.org/publications/data/fraser-sockeye-stock-recruit-dataset/)
- [PSC Stock-Recruit Data Documentation](https://www.psc.org/download/130/frp-data/19739/stock-recruit-data-documentation.pdf)
- [DFO Science Advisory Report 2025/021](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294622.pdf)
- [Pacific Salmon Outlook 2026](https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs141-9-2026-eng.pdf)

The PSC detailed CSV, its documentation and the DFO advisory are cached in
source_cache/discovery_dfo_fraser_sockeye with retrieval dates, file sizes and
checksums. The Pacific Salmon Outlook was reviewed online; the direct local
download returned an HTML page rather than the PDF and was discarded.
