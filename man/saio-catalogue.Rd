\name{list_stocks}
\alias{list_stocks}
\alias{list_assessments}
\title{Find stocks and assessment runs}
\usage{
list_stocks(search = NULL, database_dir = NULL)

list_assessments(stock_id = NULL, database_dir = NULL)
}
\arguments{
  \item{search}{Text to look for in stock names or identifiers. The
  search ignores case. Omit it to list all stocks.}
  \item{database_dir}{Folder containing the local tables. Omit it to use
  the default location, or pass the path returned by
  \code{\link{download_database}} if you chose a custom folder.}
  \item{stock_id}{One exact stock identifier, as shown in the
  \code{stock_id} column of \code{list_stocks()}. Omit it to list all
  assessments.}
}
\description{
Search the stock catalogue and find the assessment runs associated with
each stock. These functions use the small local catalogue tables.
}
\details{
Check the stock area and assessment year before selecting an assessment.
The assessment table includes source links and shows which inputs,
assumptions and outputs are available.
}
\value{
A data frame with one row per matching stock or assessment run.
Use its \code{stock_id} or \code{assessment_id} with
\code{\link{read_database}}.
}
\seealso{\code{\link{download_database}}, \code{\link{read_database}}.}
