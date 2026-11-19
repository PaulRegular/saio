\name{download_database}
\alias{download_database}
\title{Download a SAIO data release}
\usage{
download_database(release = "latest", database_dir = .saio_user_data_dir())
}
\arguments{
  \item{release}{Use \code{"latest"} for the latest published data release,
  or supply a release tag to download a specific version.}
  \item{database_dir}{Folder for the downloaded tables. The default is
  the \file{release} subfolder of R's user data directory for SAIO.
  Supply a path such as \code{"D:/SAIO/data"} to use another drive.}
}
\description{
Download the five compressed stock assessment tables and their manifest
from a SAIO release on GitHub. Each table is checked against the size and
SHA-256 checksum in the manifest. The files can be read directly in R.
}
\details{
An intact copy of the requested release is reused. Choose a new folder
to keep another release or when the destination already contains other
data. Include the release tag when reporting an analysis.
}
\value{
The absolute path to the local data folder, invisibly. Pass this path as
\code{database_dir} to the catalogue and read functions when using a
custom folder.
}
\seealso{
\code{\link{list_stocks}}, \code{\link{list_assessments}},
\code{\link{read_database}}.
}
