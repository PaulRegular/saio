import_noaa_oregon_kelp_greenling_2015 <- function(root = ".", write = FALSE) {
  id <- "noaa_kelp_greenling_oregon_2015"
  stock_id <- "noaa_kelp_greenling_oregon"
  candidate_id <- "NOAA:10462"
  cache <- file.path(root, "source_cache/discovery_noaa_oregon_kelp_greenling_2015")
  manifest <- read.csv(file.path(cache, "sources.csv"), colClasses = "character", check.names = FALSE)
  files <- file.path(cache, manifest$cached_file)
  hash <- function(path) {
    x <- system2("certutil.exe", c("-hashfile", normalizePath(path, winslash = "\\", mustWork = TRUE),
      "SHA256"), stdout = TRUE)
    trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", x, value = TRUE))
  }
  if (anyDuplicated(manifest$cached_file) || any(!file.exists(files)) ||
      any(vapply(seq_along(files), function(i) tolower(hash(files[i])) !=
        tolower(manifest$sha256[i]), logical(1)))) stop("Kelp Greenling cached sources fail provenance checks.")
  pdf <- file.path(cache, "oregon_kelp_greenling_assessment_2015.pdf")
  txt <- paste0(pdf, ".txt")
  if (!file.exists(txt)) {
    lib <- file.path(root, "source_cache/.Rlib")
    if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
    if (!requireNamespace("pdftools", quietly = TRUE)) stop("pdftools is needed to extract the cached PDF.")
    writeLines(pdftools::pdf_text(pdf), txt, useBytes = TRUE)
  }
  lines <- readLines(txt, warn = FALSE, encoding = "UTF-8")
  report <- manifest$url[match(basename(pdf), manifest$cached_file)]
  ref <- function(x) paste("2015 Oregon Kelp Greenling assessment,", x)
  nums <- function(x) {
    x <- trimws(x)
    if (!nzchar(x) || grepl("[A-Za-z#]", x) || grepl("^[0-9]{3}$", x)) return(numeric())
    tryCatch(suppressWarnings(scan(text = x, what = numeric(), quiet = TRUE)), error = function(e) numeric())
  }
  parse_block <- function(a, b, pattern, n, label) {
    ai <- grep(a, lines, perl = TRUE); bi <- grep(b, lines, perl = TRUE)
    if (length(ai) != 1L || length(bi) != 1L || ai >= bi) stop("Missing section: ", label)
    ix <- seq.int(ai + 1L, bi - 1L)
    starts <- ix[grepl(pattern, lines[ix], perl = TRUE)]
    rows <- lapply(seq_along(starts), function(j) {
      last <- if (j < length(starts)) starts[j + 1L] - 1L else bi - 1L
      x <- unlist(lapply(lines[starts[j]:last], nums), use.names = FALSE)
      if (length(x) != n) stop("Unexpected row width in ", label, ": ", length(x))
      x
    })
    do.call(rbind, rows)
  }
  len <- parse_block("^#LENGTH_COMPOSITIONS$", "^#_AGE_DATA$",
    "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+1[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+\\b",
    62L, "length compositions")
  age <- parse_block("^#_AGE_COMPOSITIONS$", "^0 #N mean size-at-age obs",
    "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+1[[:space:]]+-?[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+-?[0-9]+[[:space:]]+-?[0-9]+[[:space:]]+[0-9]+\\b",
    35L, "age compositions")
  if (nrow(len) != 100L || !all(len[,4] %in% c(0,3)) || any(len[len[,4]==0,35:62] != 0) ||
      nrow(age) != 253L || sum(age[,3] < 0) != 36L || sum(age[,3] > 0) != 217L)
    stop("Unexpected composition structure in the source model file.")
  catch_lines <- grep("^[[:space:]]*[-+.0-9][-.+0-9eE[:space:]]+$", lines, perl=TRUE, value=TRUE)
  catches <- Filter(function(x) length(x)==7L && x[6] >= 1900 && x[6] <= 2014 && x[7]==1,
    lapply(catch_lines, nums))
  catches <- do.call(rbind, catches)
  if (nrow(catches)!=115L || !identical(as.integer(catches[,6]),1900:2014)) stop("Catch years differ from Appendix A.")
  ia <- grep("^#Year Seas[[:space:]]+Fleet",lines,perl=TRUE)[1L]; ib <- grep("^#_Discards",lines)[1L]
  ix <- lapply(lines[seq.int(ia+1L,ib-1L)],nums)
  ix <- Filter(function(x) length(x)==5L && x[1]>=2001 && x[1]<=2014 && x[2]==1 && x[3] %in% 6:8,ix)
  ix <- do.call(rbind,ix)
  if (nrow(ix)!=37L) stop("CPUE rows differ from Appendix A.")
  table_rows <- function(pattern, years, label) {
    i <- grep(pattern,lines,perl=TRUE)
    if (length(i)!=1L) stop("Missing ",label)
    h <- grep("^(Table [0-9]+|Table E[0-9]+|Figure [0-9]+)\\.",lines,perl=TRUE)
    h <- h[h>i & !grepl(paste0("^",label,"( continued)?\\."),lines[h],perl=TRUE)]
    z <- lines[seq.int(i+1L,if(length(h)) min(h)-1L else length(lines))]
    z <- z[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+",z,perl=TRUE)]
    r <- lapply(z,function(s) {
      s <- gsub("([0-9])-([0-9])","\\1 \\2",s,perl=TRUE); t <- regmatches(s,gregexpr("-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?",s,perl=TRUE))[[1L]]
      as.numeric(gsub(",","",t,fixed=TRUE))
    })
    r <- Filter(function(x) length(x) && x[1] %in% years,r)
    r <- r[!duplicated(vapply(r,function(x)x[1],numeric(1)))]
    r[order(vapply(r,function(x)x[1],numeric(1)))]
  }
  t15 <- table_rows("^Table 15\\. Time-series",1915:2015,"Table 15")
  e2 <- table_rows("^Table E2\\. Recent trends",2006:2015,"Table E2")
  e3 <- table_rows("^Table E3\\. Recent trend",2006:2015,"Table E3")
  if (length(t15)!=101L || any(vapply(t15[1:100],length,integer(1))!=8L) ||
      length(t15[[101]])!=5L || length(e2)!=10L || any(vapply(e2,length,integer(1))!=7L) ||
      length(e3)!=10L || any(vapply(e3,length,integer(1))!=4L)) stop("Unexpected Table 15/E2/E3 coverage.")
  ic <- names(read.csv(file.path(root,"database/inputs.csv"),nrows=0,check.names=FALSE))
  oc <- names(read.csv(file.path(root,"database/outputs.csv"),nrows=0,check.names=FALSE))
  ac <- names(read.csv(file.path(root,"database/assumptions.csv"),nrows=0,check.names=FALSE))
  record <- function(cols,x) {
    r <- as.data.frame(setNames(lapply(cols,function(n)""),cols),check.names=FALSE)
    for(n in intersect(names(x),cols)) { v<-x[[n]]; if(!length(v)||is.na(v))v<-""; if(is.numeric(v))v<-format(v,scientific=FALSE,trim=TRUE,digits=15); r[[n]]<-as.character(v) }; r
  }
  ins <- outs <- asms <- list()
  ai <- function(type,measure,basis,value,unit,source,notes,year=NA_integer_,age=NA_real_,
      fleet="",survey="",sex="",time=.5,season="1",obs="",lb=NA_real_,lo=NA_real_,hi=NA_real_,
      n=NA_real_,ae=NA_real_,part="",stype="official_document") {
    ins[[length(ins)+1L]] <<- record(ic,list(assessment_id=id,type=type,measure=measure,basis=basis,
      fleet=fleet,survey=survey,sex=sex,region="Oregon",season=if(is.na(year))"" else season,
      year=year,year_basis=if(is.na(year))"" else "calendar_year",age=age,value=value,unit=unit,
      sampling_time=if(is.na(year))NA_real_ else time,source_type=stype,source_reference=source,
      notes=notes,observation_id=obs,length_bin=lb,length_bin_lower=lo,length_bin_upper=hi,
      sample_size=n,age_error=ae,partition=part))
  }
  ao <- function(type,measure,value,unit,source,notes,year,age=NA_integer_,lo=NA_real_,hi=NA_real_) {
    outs[[length(outs)+1L]] <<- record(oc,list(assessment_id=id,type=type,measure=measure,
      region="Oregon",year=year,age=age,value=value,se=NA_real_,lwr=lo,upr=hi,unit=unit,
      source_type="official_table",source_reference=source,notes=notes))
  }
  aa <- function(component,setting,value,source,notes) {
    asms[[length(asms)+1L]] <<- record(ac,list(assessment_id=id,component=component,
      setting=setting,value=value,source_reference=source,notes=notes,region="Oregon"))
  }
  fleets <- c("Commercial","Recreational Ocean","Recreational Estuary","Recreational Shore","Special Projects")
  for(i in seq_len(nrow(catches))) for(f in 1:5) ai("catch","catch_biomass","biomass",catches[i,f],"metric tons",
    ref("Appendix A, SS data file, pp. 151-153"),
    "Native annual total catch; values combine landings and discard mortality. Pre-1915 zero rows retained.",
    as.integer(catches[i,6]),fleet=fleets[f])
  surveys <- c("Commercial logbook CPUE","Observer CPFV CPUE","ORBS CPUE")
  unit <- c("relative index (SS biomass code 1)","relative index (SS numbers code 0)","relative index (SS numbers code 0)")
  for(i in seq_len(nrow(ix))) {
    j<-as.integer(ix[i,3])-5L
    ai("index","relative_abundance_index","index_scale",ix[i,4],unit[j],ref("Appendix A, pp. 152-153"),
      "Aggregate fishery-dependent CPUE; not an independent survey.",as.integer(ix[i,1]),survey=surveys[j])
    ai("index","log_index_sd","log_scale",ix[i,5],"log-scale SD",ref("Appendix A, pp. 152-153"),
      "Source standard error of log CPUE for the lognormal index.",as.integer(ix[i,1]),survey=surveys[j])
  }
  bins<-seq(6,60,2)
  for(i in seq_len(nrow(len))) {
    r<-len[i,]; idc<-sprintf("kelp_length_%03d",i); genders<-if(r[4]==0)0L else c(1L,2L)
    for(g in genders) {
      sx<-if(g==0)"combined" else if(g==1)"female" else "male"; first<-if(g==2)35L else 7L
      for(j in 1:28) ai(if(r[3]==5)"biology" else "catch","frequency_at_length","native_frequency",
        r[first+j-1],"source frequency",ref("Appendix A, pp. 153-166"),
        "Native length-frequency cell retained without normalization; nSamps and source partition preserved.",
        as.integer(r[1]),fleet=fleets[as.integer(r[3])],sex=sx,season=as.character(as.integer(r[2])),
        obs=idc,lb=bins[j],n=r[6],part=as.character(as.integer(r[5])))
    }
  }
  std<-age[age[,3]<0,,drop=FALSE]; cal<-age[age[,3]>0,,drop=FALSE]
  for(i in seq_len(nrow(std))) {
    r<-std[i,]; sx<-if(r[4]==1)"female" else "male"; vals<-if(r[4]==1)r[10:22] else r[23:35]
    fc<-abs(as.integer(r[3])); fl<-if(fc==1)"Commercial" else "Recreational Ocean"
    oid<-paste0("kelp_age_diagnostic_",fc,"_",as.integer(r[1]),"_",sx)
    if(abs(sum(vals)-1)>1e-5) stop("Invalid diagnostic age-composition sum.")
    for(a in 0:12) ai("catch","proportion_at_age","proportion_numbers",vals[a+1],"proportion",
      ref("Appendix A, pp. 166-170"),
      "Negative-fleet composition retained as source data; Stock Synthesis uses these rows for expected-value/diagnostic calculations, not likelihood contributions.",
      as.integer(r[1]),age=a,fleet=fl,sex=sx,obs=oid,n=r[9],ae=r[6],part=as.character(as.integer(r[5])))
  }
  for(i in seq_len(nrow(cal))) {
    r<-cal[i,]; sx<-if(r[4]==1)"female" else "male"; vals<-if(r[4]==1)r[10:22] else r[23:35]
    if(abs(sum(vals)-1)>1e-5) stop("Invalid conditional age-composition sum.")
    fc<-as.integer(r[3]); oid<-sprintf("kelp_cond_age_%03d",i)
    for(a in 0:12) ai(if(fc==5)"biology" else "catch","conditional_proportion_at_age",
      "proportion_numbers",vals[a+1],"proportion",ref("Appendix A, pp. 170-187"),
      "Native conditional age-at-length vector; Lbin_method=2 codes retained verbatim, not converted to cm. Only the row's active sex vector is stored.",
      as.integer(r[1]),age=a,fleet=fleets[fc],sex=sx,obs=oid,n=r[9],ae=r[6],
      lo=r[7],hi=r[8],part=as.character(as.integer(r[5])))
  }
  mat<-c(rep(0,13),.115,.25,.7933,.944,rep(1,14))
  if(length(mat)!=31)stop("Invalid maturity vector.")
  for(j in 1:31) ai("maturity","maturity_at_length","proportion",mat[j],"proportion",
    ref("Appendix B, p. 189"),"Fixed female empirical maturity curve; 0-60 cm bins every 2 cm.",
    sex="female",year=NA_integer_,time=NA_real_,season="",lb=(j-1)*2)
  ai("M","fixed_mortality_medium","per_year",.360,"per year",ref("Section 2.1.13; Appendix B, p. 189"),
    "Fixed base-model female M; age-invariant scalar, not estimated.",sex="female",year=NA_integer_,time=NA_real_,season="")
  ai("M","fixed_mortality_medium","per_year",.318,"per year",ref("Section 2.1.13; Appendix B, p. 189"),
    "Fixed base-model male M; age-invariant scalar, not estimated.",sex="male",year=NA_integer_,time=NA_real_,season="")
  m<-c("total_biomass","SSB","depletion","recruitment","catch_biomass","exploitation_rate","current_spawning_potential_ratio")
  ty<-c("biomass","biomass","population","recruitment","catch","mortality","mortality")
  un<-c("metric tons","metric tons","ratio","1000 fish","metric tons","ratio","ratio")
  for(r in t15) {
    y<-as.integer(r[1]); v<-r[-1]; keep<-seq_along(v)
    if(y>=2006)keep<-keep[!m[keep]%in%c("SSB","depletion","recruitment")]
    for(j in keep) ao(ty[j],m[j],v[j],un[j],ref("Table 15, pp. 67-69"),
      "Official rounded annual base-model estimate; uncertainty shown only for recent SSB, depletion and recruitment.",
      y,age=if(m[j]=="recruitment")0L else NA_integer_)
  }
  for(r in e2) {
    ao("biomass","SSB",r[2],"metric tons",ref("Table E2, p. 4"),
      "Official estimate with approximate 95% asymptotic confidence limits.",as.integer(r[1]),lo=r[3],hi=r[4])
    ao("population","depletion",r[5],"ratio",ref("Table E2, p. 4"),
      "SSB/unfished equilibrium SSB with approximate 95% asymptotic confidence limits.",as.integer(r[1]),lo=r[6],hi=r[7])
  }
  for(r in e3) ao("recruitment","recruitment",r[2],"1000 fish",ref("Table E3, p. 5"),
    "Age-0 recruitment with approximate 95% asymptotic confidence limits.",as.integer(r[1]),age=0L,lo=r[3],hi=r[4])
  arows<-list(
    c("assessment","run_identity","Oregon 2015 benchmark; Stock Synthesis 3.24u; data through 2014.","cover and summary","Latest full assessment located; later management documents carry it forward."),
    c("stock","stock_boundary","Single Oregon coastal unit; sex-disaggregated population.","assessment summary","Washington and California units are separate."),
    c("population","age_grid","Text says ages 0-12 with age 12 accumulator; printed data-file header declares 15 ages; age-composition bins are 0-12.","Section 4.1; Appendix A","Public report does not reconcile declarations; source bins retained as printed."),
    c("catch","catch_definition","Five annual fleets, metric tons; landings plus discard mortality.","Appendix A","Earlier zero rows preserved from 1900."),
    c("index","cpue","Commercial logbook, observer CPFV, ORBS.","Appendix A","All three are fishery-dependent aggregate CPUE, not independent surveys; timing 0.5."),
    c("observation","composition","100 length records, 36 negative-fleet age records and 217 conditional age-at-length records.","Appendix A","Negative-fleet rows are diagnostic; conditional Lbin codes retained without cm conversion."),
    c("biology","weight_length","Female W=6.81e-6*L^3.211 kg; male W=9.76e-6*L^3.116 kg; L is fork length cm.","Section 2.1.11","Age weights are generated through estimated growth, not supplied as fixed vector."),
    c("biology","maturity","Female fixed empirical maturity-at-length vector; L50=29.34 cm.","Section 2.1.12; Appendix B","Male maturity assumed similar, not confirmed histologically."),
    c("M","natural_mortality","Fixed age-invariant M: female 0.360 and male 0.318 per year.","Section 2.1.13; Appendix B","Not estimated in the base model."),
    c("output","uncertainty","Tables E2-E3 report approximate 95% asymptotic intervals for recent SSB, depletion and recruitment.","Tables E2-E3","No age-specific uncertainty or numeric fitted N-at-age/F-at-age surfaces found.")
  )
  for(r in arows) aa(r[1],r[2],r[3],ref(r[4]),r[5])
  inputs<-do.call(rbind,ins); outputs<-do.call(rbind,outs); assumptions<-do.call(rbind,asms)
  if(any(!is.finite(as.numeric(inputs$value)))||any(!is.finite(as.numeric(outputs$value))))stop("Non-finite source values.")
  db<-file.path(root,"database")
  stocks<-read.csv(file.path(db,"stocks.csv"),colClasses="character",check.names=FALSE)
  assess<-read.csv(file.path(db,"assessments.csv"),colClasses="character",check.names=FALSE)
  if(any(stocks$authority_stock_id=="10462",na.rm=TRUE)||stock_id%in%stocks$stock_id||id%in%assess$assessment_id)
    stop("Kelp stock or assessment identifier already exists.")
  stock<-record(names(stocks),list(stock_id=stock_id,charbonneau_id="",authority="NOAA Fisheries",
    authority_stock_id="10462",scientific_name="Hexagrammos decagrammus",common_name="Kelp greenling",
    area="Oregon coastal waters",region="Oregon",ocean="Northeast Pacific",
    notes="NOAA Stock SMART 10462; Oregon unit, distinct from Washington and California."))
  ar<-record(names(assess),list(assessment_id=id,stock_id=stock_id,assessment_year=2015,terminal_year=2014,
    estimate_terminal_year=2015,assessment_type="full_assessment",model_family="Stock Synthesis",
    model_version="3.24u",is_current=TRUE,is_applied=TRUE,assessment_url=report,data_url=report,model_url=report,
    assumptions_status="partial",inputs_status="partial",outputs_status="partial",
    notes="Latest full Oregon assessment located. Report appendices reproduce model inputs; aggregate outputs imported, while numeric fitted N-at-age, F-at-age and M-at-age are unavailable."))
  cp<-file.path(root,"discovery/candidates.csv")
  cand<-read.csv(cp,colClasses="character",check.names=FALSE)
  cr<-match(candidate_id,cand$candidate_id)
  if(is.na(cr)||cand$eligibility[cr]!="eligible"||cand$import_status[cr]!="not_started")stop("Candidate status changed.")
  ip<-file.path(root,"discovery/inventory_units.csv")
  inv<-read.csv(ip,colClasses="character",check.names=FALSE)
  ir<-which(vapply(strsplit(inv$candidate_ids," | ",fixed=TRUE),function(x)candidate_id%in%x,logical(1)))
  if(length(ir)!=1L||nzchar(inv$matched_stock_id[ir]))stop("Inventory match changed.")
  source(file.path(root,"scripts/database/candidate_register_io.R"))
  bp<-file.path(root,"discovery/selected_batch_40_2026.csv")
  batch<-read.csv(bp,colClasses="character",check.names=FALSE)
  br<-match(candidate_id,batch$candidate_id)
  if(is.na(br))stop("Kelp Greenling is not in selected batch.")
  cand$candidate_unit_id[cr]<-stock_id; cand$matched_stock_id[cr]<-stock_id
  cand$match_status[cr]<-"matched"; cand$import_status[cr]<-"partial"
  cand$catch_age_evidence[cr]<-"Imported native annual catch and length/age compositions; standard negative-fleet age compositions are diagnostic, and no catch-at-age was fabricated."
  cand$survey_age_evidence[cr]<-"Three aggregate fishery-dependent CPUE series and log SDs imported; no independent age-specific survey index."
  cand$weights_evidence[cr]<-"Sex-specific weight-length assumptions recorded; age weights are generated through estimated growth, not separately supplied."
  cand$maturity_evidence[cr]<-"Fixed female maturity-at-length vector imported; male maturity was assumed similar."
  cand$mortality_evidence[cr]<-"Fixed age-invariant M scalars imported: female 0.360 and male 0.318 per year."
  cand$timing_evidence[cr]<-"Annual model; all fleets and indices timed at 0.5."
  cand$output_evidence[cr]<-"Table 15 aggregate outputs and recent Table E2/E3 intervals imported; fitted age surfaces unavailable."
  cand$review_date[cr]<-as.character(Sys.Date()); cand$import_status[cr]<-"partial"; cand$decision_reason[cr]<-"Partial source import from the latest detailed Oregon assessment; native catches, CPUE, compositions, fixed biology and aggregate outputs recovered. Fitted age surfaces remain unavailable."; cand$notes[cr]<-"NOAA Stock SMART 10462; 2015 Oregon benchmark remains latest full fit cited by current management documents. See discovery/source_reviews/noaa_oregon_kelp_greenling_2015.md."
  inv$unit_key[ir]<-paste0("candidate:",stock_id); inv$candidate_unit_id[ir]<-stock_id
  inv$matched_stock_id[ir]<-stock_id; inv$match_status[ir]<-"matched"; inv$import_status[ir]<-"partial"
  batch$curation_status[br]<-"partial_source_import"
  candidate_inventory_row(inv,candidate_id,stock_id)
  if(write) {
    for(nm in c("stocks","assessments","assumptions","inputs","outputs"))
      write.table(get(switch(nm,stocks="stock",assessments="ar",assumptions="assumptions",inputs="inputs",outputs="outputs")),
        file.path(db,paste0(nm,".csv")),sep=",",row.names=FALSE,col.names=FALSE,append=TRUE,na="",qmethod="double",eol="\n")
    replace_candidate_register_row(cp,cr,cand[cr,,drop=FALSE],candidate_id)
    replace_csv_register_row(ip,ir,inv[ir,,drop=FALSE],"candidate_ids",inv$candidate_ids[ir])
    replace_candidate_register_row(bp,br,batch[br,,drop=FALSE],candidate_id)
  }
  list(stock=stock,assessment=ar,assumptions=assumptions,inputs=inputs,outputs=outputs)
}
if(!interactive()&&sys.nframe()==0L) {
  z<-import_noaa_oregon_kelp_greenling_2015(write="--write"%in%commandArgs(TRUE))
  cat("Kelp Greenling: ",nrow(z$inputs)," inputs, ",nrow(z$outputs)," outputs, ",
      nrow(z$assumptions)," assumptions.\n",sep="")
}







