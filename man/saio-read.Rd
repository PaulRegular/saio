\name{read_database}
\alias{read_database}
\title{Read stock assessment data from SAIO}
\usage{
read_database(
  database_dir = NULL,
  stock_id = NULL,
  assessment_id = NULL,
  tables = c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
}
\arguments{
  \item{database_dir}{Folder containing the local tables. Omit it to use
  the default download location. In an SAIO curation checkout, local
  plain CSV working tables take precedence when present.}
  \item{stock_id}{One exact stock identifier. Selects all available
  assessment runs for the stock. Find stock IDs with
  \code{\link{list_stocks}}.}
  \item{assessment_id}{One exact assessment identifier. Selects a single
  assessment run and its stock. Find assessment IDs with
  \code{\link{list_assessments}}.}
  \item{tables}{Names of the tables to return. For example, use
  \code{c("inputs", "outputs")} to request those two tables.}
}
\description{
Read the local SAIO tables for one stock, one assessment run, or the
whole database. Use either \code{stock_id} or \code{assessment_id}.
Omit both to read all rows of the requested tables.
}
\details{
The compressed tables are read directly from disk. A stock or assessment
query keeps only the matching records in memory, but scanning a large
table takes time. Reading the complete input and output tables can use
substantial memory. Use \code{\link{download_database}} to obtain a data
release before reading it locally.
}
\value{
A named list with a data frame for each requested table, plus
\code{database_source} and \code{commit} provenance fields. For a
compressed data release, the list also includes \code{database_release},
the release tag to record with your analysis. The \code{commit} field
is \code{NA} for a compressed data release.
}
\seealso{
\code{\link{download_database}}, \code{\link{list_stocks}},
\code{\link{list_assessments}}.
}
