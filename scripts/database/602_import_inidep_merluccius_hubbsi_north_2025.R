root <- "."
cache <- file.path(root, "source_cache/inidep_merluccius_hubbsi_north_2025")
files <- file.path(cache, c("report.pdf", "acta_cfp_34_2025.pdf", "resolucion_cfp_16_2025.pdf"))
expected_hashes <- c(
  "1EA0A1FFF0F7CA297692CA573DE4CC773FDCED9F657314DE8C54B7E92490E9A7",
  "330DA13B1BF30FD768C2F0E564443D1193D553FE87DE7ECDB37C033968D0300C",
  "434FBD00B5206C51EEAE05221FE36F32D04F5BC0A4D4C4F43D5CA2438F77DD36")
if (!all(file.exists(files)) ||
    !identical(toupper(unname(tools::sha256sum(files))), expected_hashes)) {
  stop("The cached INIDEP report or CFP documents differ from the reviewed sources.", call. = FALSE)
}

stock_id <- "argentina_merluccius_hubbsi_north_41s"
assessment_id <- paste0(stock_id, "_2025")
candidate_id <- "INIDEP:MERLUCCIUS_HUBBSI_NORTH41"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
read_character_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
fields <- function(path) names(utils::read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
rows <- function(columns, values) {
  n <- max(c(1L, lengths(values)))
  out <- lapply(columns, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- rep_len(as.character(value), n)
    value[is.na(value)] <- ""
    value
  })
  names(out) <- columns
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
append_rows <- function(path, value) {
  utils::write.table(value, path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "\n")
}
replace_row_text <- function(path, key_prefix, old_text, new_text) {
  lines <- readLines(path, warn = FALSE)
  row <- which(startsWith(lines, key_prefix))
  if (length(row) != 1L) stop("Expected one matching row in ", path, call. = FALSE)
  matches <- gregexpr(old_text, lines[row], fixed = TRUE)[[1]]
  if (length(matches) != 1L || matches[1] < 0L) {
    stop("Unexpected CSV row content in ", path, call. = FALSE)
  }
  lines[row] <- sub(old_text, new_text, lines[row], fixed = TRUE)
  connection <- file(path, open = "rb")
  first_bytes <- readBin(connection, what = "raw", n = 4096L)
  close(connection)
  newline <- if (any(first_bytes == as.raw(13L))) "\r\n" else "\n"
  writeLines(lines, path, sep = newline, useBytes = TRUE)
}

stocks_path <- file.path(root, "database/stocks.csv")
assessments_path <- file.path(root, "database/assessments.csv")
assumptions_path <- file.path(root, "database/assumptions.csv")
inputs_path <- file.path(root, "database/inputs.csv")
outputs_path <- file.path(root, "database/outputs.csv")
candidates_path <- file.path(root, "discovery/candidates.csv")
selected_path <- file.path(root, "discovery/selected_batch_13_2026.csv")
units_path <- file.path(root, "discovery/inventory_units.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates <- read_character_csv(candidates_path)
selected <- read_character_csv(selected_path)
units <- read_character_csv(units_path)
candidate_row <- which(!is.na(candidates$candidate_id) & candidates$candidate_id == candidate_id)
selected_row <- which(!is.na(selected$candidate_id) & selected$candidate_id == candidate_id)
unit_row <- which(!is.na(units$candidate_unit_id) & units$candidate_unit_id == stock_id)
if (length(candidate_row) != 1L || length(selected_row) != 1L || length(unit_row) != 1L ||
    candidates$candidate_unit_id[candidate_row] != stock_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started" ||
    selected$curation_status[selected_row] != "selected_for_source_curation" ||
    units$import_status[unit_row] != "not_started" ||
    any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id)) {
  stop("The candidate selection or canonical database state differs from the reviewed source screen.", call. = FALSE)
}

table1 <- utils::read.table(text = "
year arg_zcpau arg_adjacent arg_total brazil uruguay total cmp
1986 NA NA 100978 8817 86213 196008 NA
1987 NA NA 101339 9312 83693 194344 NA
1988 NA NA 49036 8138 60736 117910 NA
1989 NA NA 68766 8343 69329 146438 NA
1990 NA NA 72965 7000 55751 135716 NA
1991 NA NA 119311 6000 95890 221201 NA
1992 NA NA 123004 4500 74509 202013 NA
1993 NA NA 79162 3000 69910 152072 NA
1994 NA NA 81745 1500 56981 140226 NA
1995 NA NA 128757 2550 57874 186886 NA
1996 NA NA 112988 0 57926 170914 NA
1997 NA NA 108697 0 49649 158346 NA
1998 NA NA 71715 0 48384 120099 NA
1999 NA NA 18404 1280 32041 50573 NA
2000 2948 16839 19787 2260 27197 47210 NA
2001 22291 36295 58586 2654 27818 89058 NA
2002 25992 75997 101989 4513 32073 138575 NA
2003 9680 71890 81570 3072 35023 119665 NA
2004 8897 27592 36489 1419 39613 77521 75000
2005 24647 36732 61379 1770 41181 104330 84000
2006 14483 11742 26225 1952 28031 56208 75600
2007 4512 19062 23574 2075 25249 50898 62000
2008 23089 40054 63143 1826 28023 92991 59000
2009 14346 43249 57595 2014 26364 85973 59000
2010 5487 31063 36550 1901 33664 72115 48000
2011 3224 40237 43461 1914 35833 81208 48000
2012 721 23185 23906 2047 25501 51454 40000
2013 4015 19553 23568 1661 24314 49543 35000
2014 3193 20811 24003 2006 15956 41965 32000
2015 2220 30102 32322 1810 15666 49798 30000
2016 7997 31569 39568 1810 10502 51880 30000
2017 16634 28977 45611 1810 15560 62981 35000
2018 8638 20910 29548 1810 19741 51099 33000
2019 9373 20964 30337 1810 14563 46710 33000
2020 3829 22192 26021 1810 11321 39152 42000
2021 4339 19290 23628 1810 10441 35869 37000
2022 12956 7463 20419 1810 10342 32561 37000
2023 9123 19368 28491 1810 12015 42316 29500
2024 4619 11095 15714 1810 19672 37196 30850
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table2 <- utils::read.table(text = "
year age1 age2 age3 age4 age5 age6 age7plus
1986 3591 110669 96833 67599 28606 16124 10280
1987 3974 102897 83112 48106 43317 21562 15786
1988 21420 150115 55076 22996 8859 4016 2303
1989 12086 124107 81206 37609 13025 5280 2472
1990 17195 117282 72776 33677 10568 4953 3775
1991 12828 161873 120958 60514 22495 8197 4736
1992 5574 144935 111081 53906 15897 8881 5706
1993 3118 136884 75788 38430 8708 5923 3474
1994 8382 159236 100681 30422 4206 1606 4229
1995 8958 159162 146972 48833 6628 2788 6690
1996 13420 155270 131831 44220 5366 1898 5432
1997 11303 232336 65413 24371 5785 1895 2455
1998 9415 120135 74440 23234 5886 2249 1696
1999 1410 39684 25368 8872 3213 1717 1586
2000 1774 31638 23847 12186 3269 1822 1645
2001 10538 66278 49519 19578 5858 2714 1907
2002 13233 205528 83546 12460 3990 2313 816
2003 25651 149722 69246 22709 3768 1202 1012
2004 42852 98720 35598 7881 1717 144 332
2005 5833 167099 50224 10021 3370 868 604
2006 1043 21719 36150 16309 4441 1279 636
2007 6070 25268 27639 17519 2749 748 331
2008 17656 109155 43706 14034 6966 1241 660
2009 23105 114014 37855 9078 2841 2052 1024
2010 19244 83678 36853 10639 2169 1139 891
2011 21680 80261 59202 10929 3754 1403 1421
2012 8216 47705 30755 10605 4747 1070 714
2013 3871 63419 31750 9735 2524 780 549
2014 14677 30108 27475 12331 3530 1280 893
2015 7201 57755 28680 9957 2965 1015 427
2016 9883 41938 37737 13247 3571 1260 429
2017 14186 51720 45784 17699 5405 1661 770
2018 9750 48894 37964 12173 3965 1480 807
2019 11448 43103 34239 9108 3617 1723 980
2020 8353 35140 24673 9585 3841 931 736
2021 3825 32102 28999 7775 2555 951 405
2022 10765 39504 22681 5956 1148 511 289
2023 11781 58345 26474 7666 2386 1259 634
2024 2405 41266 25775 7422 2264 1034 429
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table3 <- utils::read.table(text = "
year age1 age2 age3 age4 age5 age6 age7plus
1986 0.235 0.369 0.54 0.683 0.842 1.081 1.399
1987 0.253 0.366 0.547 0.732 0.803 1.015 1.162
1988 0.227 0.334 0.524 0.7 0.991 1.37 1.579
1989 0.234 0.366 0.587 0.725 1.006 1.211 1.509
1990 0.207 0.345 0.579 0.719 1.011 1.494 1.908
1991 0.257 0.392 0.592 0.718 0.972 1.191 1.626
1992 0.263 0.367 0.621 0.766 0.994 1.27 1.739
1993 0.288 0.409 0.608 0.765 0.917 1.033 1.587
1994 0.238 0.353 0.513 0.672 0.886 1.343 0.949
1995 0.221 0.351 0.529 0.693 0.919 1.411 1.113
1996 0.191 0.347 0.532 0.703 0.897 1.41 1.062
1997 0.23 0.358 0.597 0.848 1.207 1.39 1.32
1998 0.164 0.337 0.577 0.906 1.232 1.581 1.939
1999 0.181 0.363 0.553 1.042 1.617 2.017 2.491
2000 0.155 0.359 0.581 0.906 1.301 1.568 2.171
2001 0.141 0.343 0.592 0.954 1.381 1.681 2.212
2002 0.188 0.346 0.529 0.86 1.066 1.692 2.321
2003 0.191 0.343 0.535 0.834 1.098 1.377 1.687
2004 0.219 0.367 0.598 0.937 1.352 1.886 2.025
2005 0.174 0.336 0.583 0.998 1.5 1.641 2.309
2006 0.163 0.384 0.628 0.947 1.43 1.682 1.668
2007 0.164 0.38 0.619 0.956 1.502 2.252 1.925
2008 0.167 0.356 0.583 0.917 1.259 2.08 2.237
2009 0.18 0.367 0.607 0.901 1.218 1.549 2.048
2010 0.179 0.365 0.58 0.9 1.389 1.92 2.231
2011 0.183 0.326 0.548 0.874 1.025 1.136 2.541
2012 0.15 0.376 0.544 0.79 1.008 1.307 1.409
2013 0.174 0.309 0.515 0.839 1.054 1.3 1.934
2014 0.166 0.322 0.51 0.768 1.03 1.197 1.318
2015 0.169 0.341 0.524 0.838 1.121 1.636 1.268
2016 0.16 0.316 0.52 0.809 1.155 1.342 2.11
2017 0.149 0.3 0.47 0.797 1.105 1.475 1.705
2018 0.165 0.301 0.459 0.763 1.146 1.398 1.795
2019 0.141 0.312 0.481 0.767 1.104 1.366 1.871
2020 0.161 0.333 0.512 0.721 1.003 1.512 1.776
2021 0.156 0.325 0.491 0.79 1.051 1.157 1.631
2022 0.139 0.313 0.511 0.807 1.181 1.149 1.25
2023 0.147 0.299 0.488 0.744 0.975 1.128 1.241
2024 0.146 0.324 0.51 0.783 1.108 1.291 1.56
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table4 <- utils::read.table(text = "
year value period
1986 1460 1986-2016
1987 2375 1986-2016
1988 1059 1986-2016
1989 1525 1986-2016
1990 1382 1986-2016
1991 2192 1986-2016
1992 1639 1986-2016
1993 1151 1986-2016
1994 817 1986-2016
1995 1026 1986-2016
1996 900 1986-2016
1997 670 1986-2016
1998 508 1986-2016
1999 179 1986-2016
2000 259 1986-2016
2001 494 1986-2016
2002 719 1986-2016
2003 610 1986-2016
2004 534 1986-2016
2005 517 1986-2016
2006 313 1986-2016
2007 258 1986-2016
2008 317 1986-2016
2009 357 1986-2016
2010 319 1986-2016
2011 536 1986-2016
2012 396 1986-2016
2013 444 1986-2016
2014 339 1986-2016
2015 468 1986-2016
2016 581 1986-2016
2017 1666 2017-2024
2018 1523 2017-2024
2019 1745 2017-2024
2020 1379 2017-2024
2021 1463 2017-2024
2022 1219 2017-2024
2023 1615 2017-2024
2024 1456 2017-2024
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table5 <- utils::read.table(text = "
year age1 age2 age3 age4 age5 age6 age7plus
1996 444832 216981 106258 47096 17632 7589 8660
1997 213845 163359 71361 27851 11925 6998 6374
1998 96543 132764 68138 34383 6995 4681 3653
1999 120069 62083 57859 23197 6126 3131 2768
2000 391031 87449 39225 18498 8945 3101 2536
2001 464002 75888 22667 9303 7058 3197 2554
2003 287942 89301 39679 21590 6911 3300 4169
2005 141257 134113 39161 13647 4639 1784 972
2006 128271 68319 37384 23441 7620 3860 1834
2008 66354 62536 19649 8465 7838 1703 481
2011 322951 130266 31426 10435 4660 2007 2300
2012 290595 116753 19098 8440 4452 2634 1936
2016 357593 137218 52630 19322 7302 3118 2020
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table6 <- utils::read.table(text = "
age value
1 0.045
2 0.177
3 0.394
4 0.692
5 1.067
6 1.515
7 2.034
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table7 <- utils::read.table(text = "
age natural_mortality maturity
1 0.3 0.005
2 0.3 0.142
3 0.3 0.838
4 0.3 0.994
5 0.3 1
6 0.3 1
7 0.3 1
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table8 <- utils::read.table(text = "
year value
1995 4532
1996 2798
1998 1076
1999 467
2000 371
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table9 <- utils::read.table(text = "
year season value
1991 spring 65.68
1992 spring 45.34
1993 spring 24.43
1993 autumn 59.91
1994 spring 34.34
1994 autumn 16.99
1995 spring 19.13
1995 autumn 14.03
1996 spring 29.52
1996 autumn 17.39
1997 spring 16.1
1997 autumn 53.74
1998 autumn 23.35
1999 autumn 27.45
2000 spring 14.13
2000 autumn 22.82
2001 autumn 49.47
2006 autumn 13.88
2007 spring 19.34
2007 autumn 101.45
2008 spring 14.02
2008 autumn 57.74
2009 spring 18.24
2010 spring 35.71
2010 autumn 36.63
2011 autumn 103.91
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table11 <- utils::read.table(text = "
year total_biomass_e1 spawning_biomass_e1 recruitment_e1 total_biomass_e2 spawning_biomass_e2 recruitment_e2 total_biomass_e3 spawning_biomass_e3 recruitment_e3
1986 702500 573550 564390 705430 576170 565350 737170 609030 577240
1987 644190 535160 624280 647550 538280 625590 670860 561360 609090
1988 565110 452500 691940 568740 455880 693470 584180 473150 689160
1989 574070 447510 750010 577870 451030 751170 586390 460370 755630
1990 574140 439920 751710 577930 443460 752830 581930 447150 755870
1991 589540 461120 560300 593270 464640 561090 593910 465700 545390
1992 510240 406380 541520 513850 409830 542160 510750 408960 528450
1993 440190 339130 632780 443590 342430 632960 437350 337970 634140
1994 424180 309390 706640 427300 312460 706550 419640 304570 717500
1995 407830 291870 513980 410570 294600 514240 402960 286440 500570
1996 340290 246950 504750 342650 249260 504960 334960 243380 493780
1997 265830 186260 328100 267840 188220 328220 258590 180990 317320
1998 200810 150750 166290 202610 152500 166530 190380 142410 151060
1999 138650 107330 210830 140270 108890 211190 125980 97137 196930
2000 143220 96990 447780 144710 98388 448680 129660 85096 453400
2001 183670 99189 702280 185090 100460 702860 170520 85813 706610
2002 212910 113000 375380 214280 114260 375500 201170 101030 376470
2003 187730 121920 339330 189050 123170 339580 177450 112020 330970
2004 156610 98192 377730 157870 99388 377850 147170 89767 376210
2005 159540 105200 154080 160750 106370 154350 150160 96824 140760
2006 121490 91755 166270 122680 92894 166480 111150 83726 148780
2007 122530 84214 383430 123700 85334 383780 110910 74540 390050
2008 140440 81556 314570 141570 82617 314880 128610 69648 314120
2009 130210 75287 371210 131300 76295 371540 119250 64688 370840
2010 129120 68961 370800 130180 69927 371550 119330 59262 376770
2011 139510 80853 275730 140620 81807 276890 131220 72210 274670
2012 130150 83503 242070 131430 84555 243450 123310 76684 244310
2013 140150 99516 177590 141690 100790 179100 134100 93677 168530
2014 146420 107950 301000 148420 109540 305340 141750 103220 323010
2015 161860 113690 256110 164710 115770 262000 159770 109290 260550
2016 174790 128340 265660 178820 131310 272820 176180 128050 280270
2017 181220 135940 239650 186560 140090 245200 185980 138510 248070
2018 167190 126710 217040 173740 132280 220730 174820 132950 216080
2019 158170 121510 190040 165650 128200 193730 167440 130440 189520
2020 149860 117160 172580 158100 124650 176440 159770 127080 168940
2021 145430 114370 183040 154210 122390 186720 154700 124070 179020
2022 147470 112630 247510 156580 121050 249920 156030 121020 260920
2023 157900 116820 219720 167340 125480 227220 165730 123570 212810
2024 159220 119360 240710 169350 128040 251560 163800 126500 191530
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)

table12 <- utils::read.table(text = "
year term target_biomass f_scalar cba
2026 short 150000 0.412 40507
2026 short 230000 0.126 13593
2026 medium 150000 0.508 48461
2026 medium 230000 0.31 31570
", header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)


if (nrow(table1) != 39L || !identical(table1$year, 1986:2024) ||
    nrow(table2) != 39L || nrow(table3) != 39L || nrow(table4) != 39L ||
    nrow(table5) != 13L || nrow(table6) != 7L || nrow(table7) != 7L ||
    nrow(table8) != 5L || nrow(table9) != 26L || nrow(table11) != 39L ||
    nrow(table12) != 4L) {
  stop("One or more transcribed report tables failed their coverage checks.", call. = FALSE)
}
if (table1$total[table1$year == 2000L] != 47210 ||
    table1$arg_total[table1$year == 2000L] != 19787 ||
    table2$age1[table2$year == 1986L] != 3591 ||
    table3$age7plus[table3$year == 2024L] != 1.560 ||
    table11$spawning_biomass_e2[table11$year == 2024L] != 128040 ||
    table12$cba[table12$term == "short" & table12$target_biomass == 150000] != 40507) {
  stop("Key transcribed values do not match the reviewed PDF tables.", call. = FALSE)
}

ages <- 1:7
age_columns <- paste0("age", c(1:6, "7plus"))
reported_total_t <- table1$total
implied_catch_t <- rowSums(table2[, age_columns] * table3[, age_columns])
if (any(abs(implied_catch_t / reported_total_t - 1) > 0.002)) {
  stop("Catch-at-age and commercial weights do not reproduce the Table 1 total catch within rounding.", call. = FALSE)
}

input_fields <- fields(inputs_path)
output_fields <- fields(outputs_path)
assumption_fields <- fields(assumptions_path)
region <- "North of 41°S; ZCPAU and adjacent Argentine waters"
source_report <- "INIDEP Official Technical Report 43/2025"
input <- function(type, measure, basis, value, unit, source_reference,
                  year = NA_integer_, year_basis = NULL, age = NA_integer_,
                  fleet = "", survey = "", season = "",
                  region = "North of 41°S; ZCPAU and adjacent Argentine waters",
                  observation_id = "", sampling_time = NA_real_,
                  transformation = "", notes = "") {
  if (is.null(year_basis)) year_basis <- ifelse(is.na(year), "", "calendar_year")
  rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = year_basis, age = age, fleet = fleet, survey = survey,
    region = region, season = season, observation_id = observation_id,
    sampling_time = sampling_time, source_type = "official_table",
    source_reference = paste(source_report, source_reference, sep = ", "),
    transformation = transformation, notes = notes))
}
output <- function(type, measure, value, unit, year, source_reference,
                   source_type = "official_table", scenario = "", notes = "") {
  rows(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year,
    source_type = source_type, source_reference = source_reference,
    scenario = scenario, notes = notes))
}
assumption <- function(component, setting, value, source_reference, notes = "") {
  rows(assumption_fields, list(assessment_id = assessment_id,
    component = component, region = region, setting = setting, value = value,
    source_reference = paste(source_report, source_reference, sep = ", "), notes = notes))
}

inputs <- list()
catch_series <- list(
  arg_total = list(region = "Argentina; total north of 41°S", note = "Total Argentine catch for the northern unit."),
  brazil = list(region = "Brazil; northern-unit catch contribution", note = "Brazilian catch contribution to the northern effective."),
  uruguay = list(region = "Uruguay; northern-unit catch contribution", note = "Uruguayan catch contribution to the northern effective."),
  total = list(region = "All countries; total north of 41°S", note = "Published total catch across countries; country rows are not additional independent observations."),
  arg_zcpau = list(region = "Argentina; ZCPAU", note = "Published Argentine catch component in the ZCPAU; available from 2000."),
  arg_adjacent = list(region = "Argentina; between ZCPAU and 41°S", note = "Published Argentine catch component south of the ZCPAU to 41°S; available from 2000.")
)
for (column in names(catch_series)) {
  values <- table1[[column]]
  keep <- !is.na(values)
  if (any(keep)) inputs[[length(inputs) + 1L]] <- input(
    "catch", "catch_biomass", "biomass", values[keep], "tonnes",
    "Table 1, printed p. 3", year = table1$year[keep],
    region = catch_series[[column]]$region,
    notes = paste(catch_series[[column]]$note,
      "The table reports the 1986-1999 Argentine total without the later subarea split.",
      "The 2000 country-component sum differs from the published all-country total; original values are retained."))
}

for (j in seq_along(ages)) {
  a <- ages[j]
  inputs[[length(inputs) + 1L]] <- input("catch", "numbers_at_age", "numbers",
    table2[[age_columns[j]]], "thousand individuals", "Table 2, printed p. 4",
    year = table2$year, age = a, fleet = "Argentine trawl fleet",
    notes = paste("Estimated catch numbers-at-age are reported; the fitted catch composition likelihood uses proportions.",
      "The report does not publish annual effective sample sizes or a fleet-by-age breakdown.",
      if (a == 7L) "Age 7 represents the reported 7+ group." else ""),
    transformation = "Removed printed Spanish thousands separators; values remain in thousands of fish.")
  inputs[[length(inputs) + 1L]] <- input("catch_weight", "catch_weight_at_age", "kg_per_fish",
    table3[[age_columns[j]]], "kg per fish", "Table 3, printed p. 5",
    year = table3$year, age = a, fleet = "Commercial fishing",
    notes = paste("Commercial catch weight-at-age; distinct from the single population weight vector in Table 6.",
      if (a == 7L) "Age 7 represents the reported 7+ group." else ""),
    transformation = "Converted decimal comma to decimal point; values remain kg per fish.")
}

cpue_note <- paste("Standardized Argentine fresh-trawl CPUE. The source treats 1986-2016 and 2017-2024 as separate series.",
  "The report does not state a within-year sampling date for CPUE.")
inputs[[length(inputs) + 1L]] <- input("index", "relative_biomass_index", "index_scale",
  table4$value, "kg per trawl-hour", "Table 4, printed p. 6",
  year = table4$year, fleet = "Argentine fresh-trawl fleet",
  observation_id = paste("CPUE", table4$period), notes = cpue_note,
  transformation = "Removed printed dot thousands separators from CPUE values.")

for (j in seq_along(ages)) inputs[[length(inputs) + 1L]] <- input(
  "index", "numbers_at_age", "numbers", table5[[age_columns[j]]],
  "thousand individuals", "Table 5, printed p. 7", year = table5$year,
  age = ages[j], survey = "Joint global survey (BIP Holmberg / Oca Balda)",
  season = "September", sampling_time = 0.75,
  notes = paste("Survey-estimated numbers-at-age for selected years only.",
    "The 2021-2022 age compositions were not used because they were not representative of the full effective.",
    if (ages[j] == 7L) "Age 7 represents the reported 7+ group." else ""),
  transformation = "Removed printed Spanish thousands separators; values remain in thousands of fish.")
for (j in seq_along(ages)) inputs[[length(inputs) + 1L]] <- input(
  "weight", "weight_at_age", "kg_per_fish", table6$value[j], "kg per fish",
  "Table 6, printed p. 7", age = ages[j], season = "1 January",
  notes = paste("Single population weight-at-age vector from the 1997 global survey, recalculated to 1 January and applied throughout the model period.",
    if (ages[j] == 7L) "Age 7 represents the reported 7+ group." else ""),
  transformation = "Converted decimal comma to decimal point; values remain kg per fish.")
for (j in seq_along(ages)) {
  inputs[[length(inputs) + 1L]] <- input("M", "natural_mortality_at_age", "per_year",
    table7$natural_mortality[j], "per year", "Table 7, printed p. 7", age = ages[j],
    notes = paste("Fixed natural mortality, constant across ages and years.",
      if (ages[j] == 7L) "Age 7 represents the reported 7+ group." else ""))
  inputs[[length(inputs) + 1L]] <- input("maturity", "maturity_at_age", "proportion",
    table7$maturity[j], "proportion", "Table 7, printed p. 7", age = ages[j],
    notes = paste("Mature proportion, constant across the assessment period.",
      if (ages[j] == 7L) "Age 7 represents the reported 7+ group." else ""),
    transformation = "Converted decimal comma to decimal point; values remain proportions.")
}
for (i in seq_len(nrow(table8))) inputs[[length(inputs) + 1L]] <- input(
  "index", "recruitment_index", "index_scale", table8$value[i],
  "thousand individuals per trawl-hour", "Table 8, printed p. 8",
  year = table8$year[i], year_basis = "model_year", age = 2L,
  survey = "INIDEP juvenile survey", season = "December in previous year",
  sampling_time = 0, notes = "Age-1 fish sampled in December are assigned to age 2 at the beginning of the following calendar year.",
  transformation = "Preserved the assessment's assignment to the following model year; no abundance scaling was applied.")
for (i in seq_len(nrow(table9))) inputs[[length(inputs) + 1L]] <- input(
  "index", "recruitment_index", "index_scale", table9$value[i],
  "thousand individuals per square nautical mile", "Table 9, printed p. 8",
  year = table9$year[i], age = 1L, survey = "BIP Aldebarán juvenile survey",
  season = table9$season[i], sampling_time = if (table9$season[i] == "spring") 0.75 else 0.417,
  notes = "Age-1 juvenile density index recalculated using the same strata across years; timing corresponds to the reported September spring and May autumn surveys.",
  transformation = "Converted decimal comma to decimal point; values remain in thousands of fish per square nautical mile.")
input_rows <- do.call(rbind, inputs)

outputs <- list()
for (i in seq_len(nrow(table11))) {
  y <- table11$year[i]
  for (s in c("e1", "e2", "e3")) {
    scenario <- toupper(s)
    outputs[[length(outputs) + 1L]] <- output("biomass", "total_biomass",
      table11[[paste0("total_biomass_", s)]][i], "tonnes", y,
      paste(source_report, "Table 11, printed p. 29"), scenario = scenario)
    outputs[[length(outputs) + 1L]] <- output("biomass", "spawning_biomass",
      table11[[paste0("spawning_biomass_", s)]][i], "tonnes", y,
      paste(source_report, "Table 11, printed p. 29"), scenario = scenario)
    outputs[[length(outputs) + 1L]] <- output("recruitment", "recruitment",
      table11[[paste0("recruitment_", s)]][i], "thousand individuals", y,
      paste(source_report, "Table 11, printed p. 29"), scenario = scenario,
      notes = "The report explicitly gives recruitment in thousands of fish; the table reports no uncertainty measures.")
  }
}
for (i in seq_len(nrow(table12))) {
  target <- format(table12$target_biomass[i], big.mark = ",", scientific = FALSE)
  scenario <- paste("E2", table12$term[i], "term; BR >", target, "t")
  outputs[[length(outputs) + 1L]] <- output("management", "recommended_biological_catch",
    table12$cba[i], "tonnes", 2026L, paste(source_report, "Table 12, printed p. 32"),
    scenario = scenario, notes = "Biologically acceptable catch at no more than 10% risk of missing the spawning-biomass recovery target.")
  outputs[[length(outputs) + 1L]] <- output("mortality", "fishing_mortality_scalar",
    table12$f_scalar[i], "per year", 2026L, paste(source_report, "Table 12, printed p. 32"),
    scenario = scenario, notes = "Projected scalar fishing mortality associated with the reported catch advice.")
}
for (i in which(!is.na(table1$cmp))) {
  scope <- if (table1$year[i] >= 2014L) {
    "Argentine sector south of ZCPAU to 41°S; ZCPAU limit is separate"
  } else "Entire northern effective"
  outputs[[length(outputs) + 1L]] <- output("management", "maximum_permissible_catch",
    table1$cmp[i], "tonnes", table1$year[i], paste(source_report, "Table 1, printed p. 3"),
    scenario = scope, notes = "Historical CFP maximum catch shown for context; not a fitted model output.")
}
outputs[[length(outputs) + 1L]] <- output("management", "maximum_permissible_catch",
  28700, "tonnes", 2026L,
  "Consejo Federal Pesquero Resolution 16/2025, 11 December 2025",
  scenario = "2026 management limit for the northern effective",
  notes = "Management limit set by CFP; this is distinct from the conditional E2 biologically acceptable catches in Table 12.")
output_rows <- do.call(rbind, outputs)

assumptions <- do.call(rbind, list(
  assumption("assessment", "run_and_period", "2025 production assessment; model period 1986-2024; catch advice for 2026", "cover; pp. 1-2"),
  assumption("assessment", "method", "Annual statistical catch-at-age model implemented in AD Model Builder", "pp. 2-3; 9-16"),
  assumption("assessment", "population_unit", "Northern Merluccius hubbsi effective north of 41°S; managed by CTMFM in the ZCPAU and by Argentina south of that zone", "pp. 2-3"),
  assumption("age_structure", "age_groups", "Ages 1-6 and a 7+ group", "Tables 2, 3, 5-9; pp. 4-8", "Age 7 in the database identifies the reported plus group."),
  assumption("catch", "annual_catch", "Annual all-country catches in Table 1; Argentina, Brazil, and Uruguay components are also reported", "Table 1, printed p. 3", "The 1986-1999 Argentine subarea split is unavailable. In 2000 the published country-component sum differs from the published total by 2,034 t; original values are preserved."),
  assumption("catch", "catch_at_age", "Estimated catch numbers-at-age; model uses age proportions in a multinomial likelihood", "Table 2, printed p. 4; pp. 13-14", "The source does not publish the fitted annual effective sample sizes or a fleet-by-age table."),
  assumption("catch", "catch_observation_error", "Annual catch totals treated as near-exact with log-scale CV 0.001", "pp. 13-14"),
  assumption("catch_weight", "commercial_weight_at_age", "Commercial catch weights-at-age vary annually and differ from the single population weight vector", "Table 3, printed p. 5; Table 6, printed p. 7"),
  assumption("fishing_mortality", "fishing_mortality_structure", "Annual scalar fishing mortality multiplied by an age-specific double-normal selectivity pattern", "pp. 9-12"),
  assumption("fishing_mortality", "selectivity_blocks", "Four selectivity blocks: 1986-1990, 1991-1996, 1997-2013, and 2014-2024", "p. 10"),
  assumption("catchability", "q_estimation", "Catchability coefficients are calculated analytically for each index; separate q values are used for CPUE periods 1986-2016 and 2017-2024", "pp. 11-12; 15-16"),
  assumption("index", "index_error", "Log-index standard deviations: 0.1 global survey, 0.3 age-2 juvenile index, 0.4 age-1 autumn, 0.4 age-1 spring, and 0.1 for each of two CPUE periods", "p. 15"),
  assumption("index", "global_survey", "Global survey numbers-at-age are reported for selected years 1996-2016; the 2021-2022 age compositions were excluded", "Table 5, printed p. 7; pp. 7, 11-12", "The assessment also uses a global-survey biomass index, but the numerical observed biomass series is not tabulated in the report and was not reconstructed here."),
  assumption("index", "juvenile_indices", "Age-2 index is assigned to the next January; age-1 indices come from Aldebarán spring and autumn surveys", "Tables 8-9, printed pp. 8-9; p. 11"),
  assumption("timing", "survey_timing", "Global survey September (0.75); age-2 index assigned to 1 January (0); Aldebarán autumn May (0.417) and spring September (0.75)", "pp. 8, 11"),
  assumption("timing", "cpue_timing", "Within-year timing for annual CPUE is not reported", "Table 4, printed p. 6; pp. 6-7"),
  assumption("natural_mortality", "natural_mortality_at_age", "Fixed M=0.3 per year for ages 1-6 and 7+", "Table 7, printed p. 7"),
  assumption("biology", "weight_and_maturity", "Population weights are from the 1997 global survey and recalculated to 1 January; maturity proportions are fixed by age", "Tables 6-7, printed p. 7"),
  assumption("recruitment", "recruitment_model", "Beverton-Holt stock-recruitment relationship with annual lognormal recruitment deviations; base CV 0.3", "pp. 9, 15-16"),
  assumption("initial_abundance", "initial_state", "Initial abundance at the start of 1986 is derived from virgin abundance, fishing mortality, natural mortality, and estimated age-specific initial residuals constrained to sum to zero", "pp. 9-10"),
  assumption("scenarios", "scenario_definitions", "E1 uses 0.1 CV for 2021-2022 survey biomass; E2 uses 0.3; E3 uses E2 and recruitment CV 0.6", "pp. 15-16"),
  assumption("uncertainty", "reported_output_uncertainty", "Table 11 reports point estimates for total biomass, spawning biomass and recruitment under E1-E3, without uncertainty measures", "Table 11, printed p. 29"),
  assumption("model_output", "age_specific_states", "Annual numerical N-at-age and F-at-age outputs are not tabulated", "Tables 11-12"),
  assumption("reported_units", "recruitment_unit", "Recruitment in Table 11 is reported in thousands of fish", "Table 11, printed p. 29")
))

stock_fields <- fields(stocks_path)
assessment_fields <- fields(assessments_path)
stock <- rows(stock_fields, list(
  stock_id = stock_id, charbonneau_id = "", authority = "INIDEP",
  authority_stock_id = "Efectivo norte de 41° S", scientific_name = "Merluccius hubbsi",
  common_name = "Northern Argentine hake",
  area = "North of 41°S; ZCPAU and adjacent Argentine waters",
  region = "Argentina and Argentina-Uruguay Common Fishing Zone",
  ocean = "Southwest Atlantic",
  notes = "Distinct from the southern effective south of 41°S. The northern biological unit spans the ZCPAU and adjacent Argentine waters; Table 1 includes Argentina, Uruguay, and Brazil catch records."
))
assessment <- rows(assessment_fields, list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2024L, estimate_terminal_year = 2024L,
  assessment_type = "full_assessment", model_family = "ADMB",
  model_version = "INIDEP statistical catch-at-age model, 2025 run for 2026 advice",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://marabierto.inidep.edu.ar/handle/inidep/5103",
  framework_url = "", data_url = "", model_url = "",
  repository_url = "https://marabierto.inidep.edu.ar/handle/inidep/5103",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "The detailed report provides annual catch-at-age, catch weights, CPUE, survey age data, biology and aggregate E1-E3 outputs. Aggregate global-survey biomass observations and raw fitted age-composition sample sizes are not tabulated; annual N-at-age, F-at-age and state uncertainty are unavailable. CFP records confirm the 2026 advice cycle."
))

cat("Stock:", stock_id, "\n")
cat("Imported source inputs:", nrow(input_rows), "; outputs:", nrow(output_rows),
  "; assumptions:", nrow(assumptions), "\n")
cat("Catch-age times commercial-weight check: maximum absolute relative difference =",
  max(abs(implied_catch_t / reported_total_t - 1)), "\n")
if (write_mode) {
  append_rows(stocks_path, stock)
  append_rows(assessments_path, assessment)
  append_rows(assumptions_path, assumptions)
  append_rows(inputs_path, input_rows)
  append_rows(outputs_path, output_rows)
  replace_row_text(candidates_path, paste0("\"", candidate_id, "\","),
    paste0("\"2026-11-07\",\"\",\"new\",\"screened\",\"eligible\",\"not_started\","),
    paste0("\"2026-11-07\",\"", stock_id, "\",\"matched\",\"screened\",\"eligible\",\"partial\","))
  replace_row_text(selected_path, paste0("\"1\",\"", candidate_id, "\","),
    "\"selected_for_source_curation\"", "\"partial_source_import\"")
  replace_row_text(units_path, paste0("\"candidate:", stock_id, "\","),
    paste0("\"candidate:", stock_id, "\",\"\",\"", stock_id,
      "\",\"new\",\"eligible\",\"screened\",\"not_started\",\"INIDEP\""),
    paste0("\"candidate:", stock_id, "\",\"", stock_id, "\",\"", stock_id,
      "\",\"matched\",\"eligible\",\"screened\",\"partial\",\"INIDEP\""))
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  cat("Imported the reviewed source tables and marked the record partial.\n")
}
