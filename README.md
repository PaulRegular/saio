# SAIO — Stock Assessment Inputs and Outputs Database

SAIO brings together publicly available data and results from official fish stock assessments. It is intended for stock assessment biologists and researchers who want to find, understand and reuse assessment inputs and outputs.

The collection currently focuses on finfish and age-disaggregated information: catch and survey data, weights, maturity, mortality assumptions, and estimates of abundance, recruitment, fishing mortality and spawning-stock biomass. Coverage varies among stocks. Records retain their source units, biological definitions and references to the original assessment material.

## Use SAIO

Install the package once in R. You can then use SAIO from any project.

```r
install.packages("pak")
pak::pak("PaulRegular/saio")
```

Download the latest data release, then search for a stock and choose an assessment:

```r
library(saio)
download_database()

list_stocks("cod")
list_assessments("dfo_cod_2j3kl")
cod <- read_database(assessment_id = "dfo_cod_2j3kl_2025")
cod$database_release
```

The catalogue searches are quick. An assessment query scans the compressed input and output tables and keeps only the matching rows in memory. This can take a minute or more for a large release. Use `cod$inputs`, `cod$assumptions`, and `cod$outputs` to work with the selected data. Record `cod$database_release` with your analysis so you can use the same data again.

To browse without R, download the two small catalogue tables from the latest release. [Stocks CSV](https://github.com/PaulRegular/saio/releases/latest/download/stocks.csv.gz) · [Assessments CSV](https://github.com/PaulRegular/saio/releases/latest/download/assessments.csv.gz)

## How the database is organized

SAIO releases contain five linked CSV tables. The Git repository holds the schema, [import and validation scripts](scripts/), [source reviews](source_reviews/), [source manifests](provenance/) and [published release manifests](database/releases/).

| Table | What it contains |
|---|---|
| `stocks.csv` | Stock names, scientific names, assessment authorities, official stock codes and geographic areas. Start here to find a stock. |
| `assessments.csv` | The assessment years and model runs available for each stock, links to the source documents and files, and the completeness of each record. |
| `inputs.csv` | Numerical inputs supplied to the official assessment, such as catch-at-age, survey indices, age or length compositions, weights, maturity and supplied natural mortality. |
| `assumptions.csv` | Biological and statistical assumptions, including mortality treatments, recruitment, selectivity, observation errors and parameter sharing. |
| `outputs.csv` | Official assessment estimates and reported indicators, with available uncertainty. Examples include numbers-at-age, fishing mortality, recruitment and spawning-stock biomass. |

Each stock has a `stock_id`. A stock can have several assessments, each with its own `assessment_id`. Use that assessment identifier to select the corresponding inputs, assumptions and outputs. Keep different assessment runs separate, even when they describe the same stock.

Inputs and outputs are stored in **long format**: each row describes one value for a particular quantity and, where applicable, year, age, fleet, survey, sex, region and season. For example, an abundance-at-age series has separate rows for each year and age. The `type` and `measure` columns identify the quantity, `value` gives its numerical value, and `unit` gives its scale.

## Finding an assessment

Find the stock in `stocks.csv`, then look up its `stock_id` in `assessments.csv`. Check the area as well as the species name: separate assessment units may share a common name.

The assessment table distinguishes:

- **`assessment_year`**: the assessment/advice year, which can differ from the publication year of the detailed report.
- **`terminal_year`**: the last year of data used by that assessment.
- **`is_current`**: the selected assessment with publicly accessible detailed information for that stock record. It may predate newer summary-only advice. Check the notes for stock-boundary changes or historical records.
- **`is_applied`**: whether the assessment was used for advice in its assessment cycle.

The `inputs_status`, `assumptions_status` and `outputs_status` columns describe how much of the official assessment has been captured. A `partial` record contains useful information but has documented gaps; `complete` refers to extraction coverage, rather than independent scientific verification. Some stocks have catalogue information only and no assessment data yet.

Assessment records link to the original reports and, where available, data files and assessment objects. The [source reviews](source_reviews/) explain what was recovered, how values were interpreted or reconstructed, and what remains unavailable. The [candidate register](database/candidates.csv) records stocks under review and progress toward adding them.

To retrace an import, use the stock ID to find its review and [processing scripts](scripts/). The [source manifest](provenance/) for the assessment ID lists the exact files, versions and checksums used. Cache those source files locally under `source_cache/<stock_id>/<assessment_id>/`. The stock ID matches the script folder. Use `source_cache/shared/` for files used by several stocks.

For the Greenland halibut unit in NAFO Subarea 2 and Divisions 3KLMNO, see the [stock source review](source_reviews/dfo_greenland_halibut_2_3klmno.md).

For NOAA Pacific Coast petrale sole, see the [stock source review](source_reviews/noaa_petrale_sole_pacific_coast.md).

## Getting the data

`download_database()` verifies the five compressed tables against the release manifest and shows where it saved them. The catalogue and read functions use your local files, including when you are offline. By default, all your RStudio projects can use the same local copy. The November 2026 release occupies about 77 MB compressed.

Use the release tag to reproduce an analysis. To store the data on another drive, choose a new folder and pass the returned path to the readers:

```r
saio_dir <- download_database(
  release = "saio-2026-11-16-curation",
  database_dir = "D:/SAIO/curation"
)
list_stocks("cod", database_dir = saio_dir)
```

A repeat download reuses an intact copy of the requested release. Choose another folder if you want to keep more than one release or the destination is already occupied.


## Accessing a stock in R

Use `assessment_id` for one assessment or `stock_id` for all assessments associated with a stock. Each run retains its assessment ID. Request only the tables you need with `tables`:

```r
cod_outputs <- read_database(stock_id = "dfo_cod_2j3kl", tables = "outputs")

ssb <- subset(cod_outputs$outputs, measure == "SSB")
head(ssb[c("assessment_id", "year", "value", "lwr", "upr", "unit")])
```

Pass `database_dir` to `read_database()` or `list_assessments()` if you stored the data in a custom folder. Calling `read_database()` without a stock or assessment ID can load the full tables into memory.

## Interpreting the records

- **Check units and observation types.** Fish counts, thousands of fish, biomass indices and composition samples have different meanings. An age composition is not an abundance index. Stock weights and catch weights serve different biological purposes.
- **Keep the source dimensions.** Fleets, surveys, sexes, regions and seasons may represent separate observations or populations. A terminal age can represent a plus group; check `age_group` and the notes. `sampling_time` records the within-year fraction where known, with approximations identified in the notes.
- **Treat missing values as missing.** A blank value is not zero. Blank years or ages can also indicate a time-invariant or aggregate quantity. The `year_basis` field identifies calendar-year, model-year or cohort indexing for inputs.
- **Check output definitions and uncertainty.** Recruitment age, spawning time, sex convention and the age range used for mean F can differ among assessments. `se` is a standard error; its scale is documented in the notes. `lwr` and `upr` retain available interval limits, with their level and construction described where known. Missing uncertainty has not been filled in.

Use `source_reference`, `source_type`, `transformation` and `notes` to trace a record to its source and understand any reconstruction. Detailed column definitions are in [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md); source-selection and recovery rules are in [PROTOCOL.md](PROTOCOL.md).

## Where SAIO started

The Charbonneau–Keith Age-structured Marine Fish Database supplied SAIO’s initial list of stocks. The optional `charbonneau_id` column preserves the link to that catalogue. Use `stock_id` to join the SAIO tables.
[Charbonneau–Keith catalogue](https://github.com/JulieCharbonneau/Age-structured-marine-fish-database) · [Pinned Master CSV](https://raw.githubusercontent.com/JulieCharbonneau/Age-structured-marine-fish-database/7e4daca3cbfc14ce7fa0b28ed824eebe7113249b/Master.csv) · [SAIO catalogue review](source_reviews/shared/charbonneau_keith_master_catalogue.md)

## Scope and verification

SAIO currently includes assessments whose detailed assessment documentation is
available in English. This is a real coverage limitation: it leaves out
assessments documented only in other languages and may underrepresent regions
where English reporting is uncommon. A stock or assessment missing from SAIO
should not be taken as evidence that no assessment or usable data exists.

SAIO is a growing collection, not an exhaustive inventory of all assessments. The database was compiled with substantial AI assistance, and not all records have been independently checked by a person. Verify the values and definitions relevant to your work against the authoritative sources before research use. Automated checks and extraction-completeness labels do not establish scientific equivalence among assessments.

Record the release tag used in your analysis and retain its manifest and assets. Cite the original assessment sources as well as SAIO, and retain their attribution and any source-specific reuse terms. No blanket licence is assigned to third-party assessment material. Repository code retains its attribution and GPL (>= 3) licence in [CODE_LICENSE.md](CODE_LICENSE.md).

For curation and archiving, see [Batch commits and snapshots](PROTOCOL.md#batch-commits-and-snapshots).
