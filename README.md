# SAIO — Stock Assessment Inputs and Outputs Database

SAIO brings together publicly available data and results from official fish stock assessments. It is intended for stock assessment biologists and researchers who want to find, understand and reuse assessment inputs and outputs.

The collection currently focuses on finfish and age-disaggregated information: catch and survey data, weights, maturity, mortality assumptions, and estimates of abundance, recruitment, fishing mortality and spawning-stock biomass. Coverage varies among stocks. Records retain their source units, biological definitions and references to the original assessment material.

## How the database is organized

The database consists of five linked CSV tables in the [database folder](database/).

| Table | What it contains |
|---|---|
| [stocks.csv](database/stocks.csv) | Stock names, scientific names, assessment authorities, official stock codes and geographic areas. Start here to find a stock. |
| [assessments.csv](database/assessments.csv) | The assessment years and model runs available for each stock, links to the source documents and files, and the completeness of each record. |
| [inputs.csv](database/inputs.csv) | Numerical inputs supplied to the official assessment, such as catch-at-age, survey indices, age or length compositions, weights, maturity and supplied natural mortality. |
| [assumptions.csv](database/assumptions.csv) | Biological and statistical assumptions, including mortality treatments, recruitment, selectivity, observation errors and parameter sharing. |
| [outputs.csv](database/outputs.csv) | Official assessment estimates and reported indicators, with available uncertainty. Examples include numbers-at-age, fishing mortality, recruitment and spawning-stock biomass. |

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

Assessment records link to the original reports and, where available, data files and assessment objects. The [source reviews](source_reviews/) explain what was recovered, how values were interpreted or reconstructed, and what remains unavailable. Additional stocks being investigated are listed separately under [discovery](discovery/).

For the Greenland halibut unit in NAFO Subarea 2 and Divisions 3KLMNO, see the [stock source review](source_reviews/dfo_greenland_halibut_2_3klmno.md).

## Getting the data

For individual tables, open a CSV from the [database folder](database/) and use GitHub's **Download raw file** control. Save the files you need locally. The smaller stock and assessment tables can be inspected in a spreadsheet; R is more practical for the large input and output tables.

For a complete local copy, use Git with [Git LFS](https://git-lfs.com/) installed. Git LFS retrieves the large CSV files:

```sh
git lfs install
git clone https://github.com/PaulRegular/saio.git
```

The CSV files remain ordinary text tables on your computer. Downloaded assessment PDFs and other cached source documents are not included; use the source links in the assessment records to obtain the originals.

## Accessing a stock in R

From a local copy of SAIO, set R's working directory to the `saio` folder. You can search the two small catalogue tables before loading the larger data tables:

```r
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE)

subset(stocks, grepl("cod", common_name, ignore.case = TRUE),
  select = c(stock_id, common_name, area, authority))

subset(assessments, stock_id == "dfo_cod_2j3kl",
  select = c(assessment_id, assessment_year, terminal_year,
    is_current, inputs_status, outputs_status))
```

For example, the detailed 2025 Northern cod assessment has the identifier `dfo_cod_2j3kl_2025`. The supplied R helpers read the five tables and select the records for that assessment:

```r
source("R/read_database.R")
database <- read_database()
cod <- read_assessment("dfo_cod_2j3kl_2025", database)

unique(cod$inputs[c("type", "measure", "unit")])
unique(cod$outputs[c("type", "measure", "unit")])

ssb <- subset(cod$outputs, measure == "SSB")
head(ssb[c("year", "value", "lwr", "upr", "unit", "notes")])
```

The helpers load the full database before selecting an assessment, so allow time and memory for the large tables. The selected records are available as `cod$stocks`, `cod$assessment`, `cod$inputs`, `cod$assumptions` and `cod$outputs`. You can also read any CSV directly with your preferred software.

## Interpreting the records

- **Check units and observation types.** Fish counts, thousands of fish, biomass indices and composition samples have different meanings. An age composition is not an abundance index. Stock weights and catch weights serve different biological purposes.
- **Keep the source dimensions.** Fleets, surveys, sexes, regions and seasons may represent separate observations or populations. A terminal age can represent a plus group; check `age_group` and the notes. `sampling_time` records the within-year fraction where known, with approximations identified in the notes.
- **Treat missing values as missing.** A blank value is not zero. Blank years or ages can also indicate a time-invariant or aggregate quantity. The `year_basis` field identifies calendar-year, model-year or cohort indexing for inputs.
- **Check output definitions and uncertainty.** Recruitment age, spawning time, sex convention and the age range used for mean F can differ among assessments. `se` is a standard error; its scale is documented in the notes. `lwr` and `upr` retain available interval limits, with their level and construction described where known. Missing uncertainty has not been filled in.

Use `source_reference`, `source_type`, `transformation` and `notes` to trace a record to its source and understand any reconstruction. Detailed column definitions are in [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md); source-selection and recovery rules are in [PROTOCOL.md](PROTOCOL.md).

## Scope and verification

SAIO is a growing collection, not an exhaustive inventory of all assessments. The database was compiled with substantial AI assistance, and not all records have been independently checked by a person. Verify the values and definitions relevant to your work against the authoritative sources before research use. Automated checks and extraction-completeness labels do not establish scientific equivalence among assessments.

Record the database revision used in your analysis and retain a copy of those tables so later updates do not change your results. Cite the original assessment sources as well as SAIO, and retain their attribution and any source-specific reuse terms. No blanket licence is assigned to third-party assessment material. Repository code retains its attribution and GPL (>= 3) licence in [CODE_LICENSE.md](CODE_LICENSE.md).
