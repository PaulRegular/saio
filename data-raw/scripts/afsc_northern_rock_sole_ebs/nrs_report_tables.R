nrs_report_tables <- function(path) {
  text <- pdftools::pdf_text(path)
  lines <- unlist(strsplit(paste(text,collapse="\n"),"\n"))
  table <- function(label,end,columns=NULL) {
    first <- grep(label,lines)[1]
    last <- grep(end,lines)
    last <- min(last[last>first])
    z <- lines[seq.int(first+1L,last-1L)]
    z <- z[grepl("^\\s*(19[789][0-9]|20[012][0-9])\\s+(-?[0-9]|NA)",z)]
    rows <- lapply(z,function(x)scan(text=x,quiet=TRUE))
    if(is.null(columns)) {
      out <- do.call(rbind,lapply(rows,function(x)c(x[1],tail(x,2))))
    } else {
      stopifnot(all(lengths(rows)==columns))
      out <- do.call(rbind,rows)
    }
    stopifnot(nrow(out)==50,identical(as.integer(out[,1]),1975:2024))
    out
  }
  cells <- pdftools::pdf_data(path)
  # In the published table some minus signs wrap above their numbers.
  # Read each Model 24.2 cell geometrically, retaining both pieces of its sign.
  deviations <- function(pages,start,end,right) {
    rows <- list()
    for(page in pages) {
      z <- cells[[page]]
      low <- if(page==pages[1]) min(z$y[z$text==start]) else 0
      high <- if(any(z$text==end)) min(z$y[z$text==end]) else Inf
      yy <- z[grepl("^(19[789][0-9]|20[012][0-9])$",z$text) & z$x<100 &
        z$y>low & z$y<high, ]
      yy <- yy[order(yy$y), ]
      for(i in seq_len(nrow(yy))) {
        top <- yy$y[i]
        bottom <- if(i<nrow(yy)) yy$y[i+1] else min(top+stats::median(diff(yy$y)),high)
        row <- vapply(right,function(column) {
          v <- z[z$y>=top-2 & z$y<bottom-2 & abs(z$x+z$width-column)<=2, ]
          value <- paste(v$text[order(v$y)],collapse="")
          if(!grepl("^-?[0-9]+\\.[0-9]+$",value)) {
            cli::cli_abort("Cannot read Model 24.2 deviation cell: page {page}, year {yy$text[i]}, column {column}: '{value}'.")
          }
          as.numeric(value)
        },numeric(1))
        rows[[length(rows)+1L]] <- c(as.numeric(yy$text[i]),row)
      }
    }
    out <- do.call(rbind,rows)
    stopifnot(nrow(out)==50,identical(as.integer(out[,1]),1975:2024))
    out
  }
  fdev <- deviations(38:39,"8.17.","8.18.",220)
  a50 <- deviations(40:41,"8.18.","8.19.",c(205,424))
  slope <- deviations(41:42,"8.19.","8.20.",c(178,336))
  stopifnot(slope[slope[,1]==1998,2]==-.32,slope[slope[,1]==1998,3]==.10)
  f <- lapply(1:2,function(sex) {
    b <- c(.976,1.222)[sex]*exp(slope[,sex+1])
    a <- c(9.250,7.804)[sex]*exp(a50[,sex+1])
    selectivity <- plogis(b*outer(a,pmin(1:20,17),function(x,y)y-x))
    value <- exp(-2.348+fdev[,2])*selectivity
    if(sex==2) value <- value*exp(-.110)
    dimnames(value) <- list(1975:2024,1:20)
    value
  })
  list(
    n=lapply(c("female","male"),function(sex) {
      label <- if(sex=="female")"Table 8\\.23\\..*Estimated female" else "Table 8\\.24\\..*Estimated male"
      end <- if(sex=="female")"Table 8\\.24\\." else "Table 8\\.25"
      value <- table(label,end,21)[,-1]
      dimnames(value) <- list(1975:2024,1:20)
      value
    }),
    f=f,
    ssb=table("Table 8\\.20\\..*Estimated spawning","Table 8\\.21\\."),
    biomass=table("Table 8\\.21\\..*Estimated total biomass","Table 8\\.22\\."),
    recruitment=table("Table 8\\.22\\..*Estimated age 1","Table 8\\.23\\."),
    fdev=fdev,a50=a50,slope=slope)
}
