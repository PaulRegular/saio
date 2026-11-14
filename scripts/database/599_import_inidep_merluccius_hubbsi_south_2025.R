root <- "."
cache <- file.path(root, "source_cache/inidep_merluccius_hubbsi_south_2025")
report_file <- file.path(cache, "INIDEP_Official_Technical_Report_04742_2025.pdf")
act_file <- file.path(cache, "acta_cfp_34_2025.pdf")
report_url <- paste0(
  "https://fisheryprogress.org/system/files/",
  "INIDEP%20Official%20Technical%20Report%20No%2004742%20pp%202025.pdf"
)
act_url <- "https://cfp.gob.ar/actas/ACTA%20CFP%2034-2025.pdf"
expected_hashes <- c(
  "14B409AF21DE3AF0F212B536D178C23E952F654568A034B28F0705DADBE7BC15",
  "330DA13B1BF30FD768C2F0E564443D1193D553FE87DE7ECDB37C033968D0300C"
)
files <- c(report_file, act_file)
if (!all(file.exists(files)) ||
    !identical(toupper(unname(tools::sha256sum(files))), expected_hashes)) {
  stop("The cached INIDEP report or official CFP act differs from the reviewed source.",
    call. = FALSE)
}

stock_id <- "argentina_merluccius_hubbsi_south_41s"
assessment_id <- paste0(stock_id, "_2025")
candidate_id <- "INIDEP:MERLUCCIUS_HUBBSI_SUR41"
candidate_unit_id <- stock_id
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_character_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
rows <- function(columns, values, n = 1L) {
  out <- lapply(columns, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(out) <- columns
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
append_rows <- function(path, value) {
  if (nrow(value)) utils::write.table(value, path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE,
    eol = "\n")
}
replace_csv_cell <- function(path, key_prefix, field_index, old_value, new_value) {
  lines <- readLines(path, warn = FALSE)
  row <- which(startsWith(lines, key_prefix))
  if (length(row) != 1L) stop("Expected exactly one matching status row in ", path, call. = FALSE)
  pattern <- paste0("^((?:\"(?:[^\"]|\"\")*\"|[^,]*,){",
    field_index - 1L, "})\"", old_value, "\"(,.*)$")
  parts <- regmatches(lines[row], regexec(pattern, lines[row], perl = TRUE))[[1]]
  if (length(parts) != 3L) stop("The source status row has an unexpected CSV layout in ", path, call. = FALSE)
  lines[row] <- paste0(parts[2], "\"", new_value, "\"", parts[3])

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
selected_path <- file.path(root, "discovery/selected_batch_12_2026.csv")
units_path <- file.path(root, "discovery/inventory_units.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates <- read_character_csv(candidates_path)
selected <- read_character_csv(selected_path)
units <- read_character_csv(units_path)
candidate_row <- which(candidates$candidate_id == candidate_id)
selected_row <- which(selected$candidate_id == candidate_id)
unit_row <- which(units$candidate_unit_id == candidate_unit_id)
if (length(candidate_row) != 1L || length(selected_row) != 1L ||
    length(unit_row) != 1L ||
    candidates$candidate_unit_id[candidate_row] != candidate_unit_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started" ||
    selected$curation_status[selected_row] != "selected_for_source_curation" ||
    units$import_status[unit_row] != "not_started" ||
    any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id)) {
  stop("The candidate or canonical database state differs from the reviewed selection.",
    call. = FALSE)
}

table9 <- read.table(text = "
year age1 age2 age3 age4 age5 age6 age7 total_catch_t
1986 220220 138420 116869 82350 34616 20393 14384 266038
1987 257403 163937 144880 81666 62658 31207 27753 354342
1988 330651 264060 164343 90105 42977 49635 36342 427449
1989 337566 255065 153611 96311 48370 56886 44192 451496
1990 430156 511384 357363 142161 46821 17982 12661 564771
1991 475847 563773 355988 138326 51550 20856 15528 620245
1992 333666 407823 247925 121191 42301 17382 13540 476582
1993 432837 548430 253642 124845 38950 13907 11933 564573
1994 900280 875254 298883 136859 43682 17061 16930 679381
1995 986563 840560 379560 122175 43331 14590 15964 771721
1996 1348071 863298 462179 83528 30156 8037 8948 814378
1997 1509808 815839 409358 169106 56323 13622 8493 810099
1998 523215 491635 348325 130768 53472 13995 8941 583122
1999 401165 294486 298475 131243 37805 16530 9307 444491
2000 275945 82629 142782 103450 36355 12164 9437 277319
2001 354333 235816 179318 84500 28735 9875 7291 326868
2002 555101 456126 238116 63415 24650 9435 5906 412797
2003 553133 441007 222967 55946 10352 8176 6068 396680
2004 825261 693134 303349 110461 23480 5986 6277 581004
2005 491180 664748 255079 45868 17449 3479 2629 447628
2006 497657 415369 423042 109578 27171 9596 4055 503466
2007 441065 323023 232322 132699 52333 11717 6036 430107
2008 451836 330576 126881 54023 36564 13270 6320 318413
2009 270090 429628 177706 43114 19904 13927 8069 328438
2010 235835 268098 300949 64973 15256 6857 8485 339380
2011 269819 390506 198610 109418 26496 7771 7999 359132
2012 276940 452018 188320 50643 28796 8953 4575 336829
2013 272209 523792 280261 69036 18810 9492 4547 408996
2014 270552 520715 206670 110985 31216 8694 7257 399802
2015 217463 542669 169795 86595 36256 9886 5832 381326
2016 254355 498843 265149 86820 31799 12801 5561 406147
2017 397644 457667 230545 126780 34386 11762 7003 419309
2018 261999 587107 212421 105238 48421 13993 8851 439664
2019 328944 510987 331517 150870 51205 23193 11141 523773
2020 260715 615658 220177 156053 49278 14376 10122 465431
2021 261406 605474 318862 115677 76237 19787 7631 516096
2022 383257 582232 265741 129646 36630 26983 8650 483941
2023 344604 679862 260239 107793 39783 10968 17823 508946
2024 257524 631387 345470 127462 38886 19885 10811 513858
", header = TRUE, stringsAsFactors = FALSE)

table8 <- read.table(text = "
year age1 age2 age3 age4 age5 age6 age7
1996 4121218 1710309 1038456 258351 90350 39400 27894
1998 1764414 1292761 868439 273755 103269 26537 16011
1999 476112 1409468 611153 187656 56807 29155 13875
2000 1433985 550169 569823 266734 87217 26232 22165
2001 2003612 836647 382329 250777 94504 38261 19319
2002 1185811 1307527 782075 207256 106921 46969 35481
2003 2730482 1232240 657035 156828 43247 36476 32934
2005 4064535 2544311 882255 188750 76961 28268 23407
2007 1465926 755030 662085 373612 117766 39269 32329
2011 3817673 1874933 476923 309877 86164 24338 30263
2012 4895371 4012162 800727 345072 173342 51658 22523
2013 3670744 2714312 1787860 508057 148337 117082 36748
2016 1926978 1553028 816087 286540 115652 56013 22617
2024 4183376 1738796 614600 242969 71619 31846 13223
", header = TRUE, stringsAsFactors = FALSE)

table12 <- read.table(text = "
year age1 age2 age3 age4 age5 age6 age7
1986 2527330 951608 615147 430468 183220 102812 79471
1987 1880970 1667340 593297 365999 248669 104205 102752
1988 2223960 1209800 1000990 336443 200212 133470 109853
1989 2602140 1395340 699979 541613 174501 101550 121840
1990 2552870 1622760 800088 374427 277285 87295 110220
1991 2344220 1480580 835262 373093 164050 117558 82104
1992 2335380 1301400 714092 358586 148827 62952 74951
1993 2937950 1370800 681929 340639 161210 64849 58979
1994 4303270 1671350 685612 306600 143194 65405 49213
1995 3600870 2180440 703687 247648 100536 44618 34688
1996 3805520 1820120 914725 253014 80784 31154 23863
1997 3169990 1885050 740934 316552 79029 23905 15784
1998 2106250 1494590 713015 233549 88935 20895 10140
1999 1003050 1102140 660135 273714 82060 29822 10144
2000 1590300 538690 505992 266182 101688 29197 13896
2001 2109370 949263 289408 249155 124056 46037 19202
2002 1819880 1232180 493850 136800 110859 53464 27633
2003 2576590 1001400 586504 208491 53542 41690 29832
2004 3373030 1464650 500279 263311 87498 21685 28386
2005 2145910 1725950 580596 179179 92009 30416 17385
2006 1506440 1216900 813955 254461 77143 39465 20486
2007 1556880 796302 509628 310745 94984 28659 22249
2008 2336950 808686 323765 187987 111943 34047 18228
2009 1456170 1470380 352095 130709 75530 44965 20997
2010 1784120 926625 664188 148248 54789 31652 27642
2011 2358580 1126950 408616 272072 60443 22333 24169
2012 2115090 1477090 483277 162132 107422 23858 18355
2013 1898450 1367120 702018 215647 72057 47731 18756
2014 2464750 1199560 603505 287920 88031 29407 27134
2015 2198160 1554220 526045 245652 116642 35654 22900
2016 2063810 1424340 744671 236908 110197 52313 26260
2017 3125390 1333540 676244 331891 105163 48905 34870
2018 2265680 2013750 627304 298225 145765 46177 36785
2019 2807500 1476640 983254 288674 136722 66813 38026
2020 2509820 1785520 665789 413125 120747 57174 43840
2021 2442790 1614470 835427 291823 180328 52694 44082
2022 3083680 1543320 712422 342484 119075 73561 39477
2023 2942590 1959940 694442 298638 142920 49678 47159
2024 2855330 1887510 908636 301199 128980 61712 41813
", header = TRUE, stringsAsFactors = FALSE)

table11 <- read.table(text = "
year total_biomass total_biomass_cv spawning_biomass spawning_biomass_cv recruitment recruitment_cv fishing_mortality fishing_mortality_cv
1986 1194400 0.16 922760 0.21 2527300 0.02 0.278 0.22
1987 1339600 0.13 994670 0.18 1881000 0.25 0.339 0.21
1988 1412300 0.13 1102700 0.16 2224000 0.24 0.398 0.21
1989 1437500 0.13 1095500 0.17 2602100 0.22 0.413 0.21
1990 1459000 0.13 1083100 0.17 2552900 0.23 0.587 0.20
1991 1319000 0.13 971370 0.18 2344200 0.24 0.691 0.20
1992 1141500 0.13 824560 0.19 2335400 0.24 0.558 0.20
1993 1140400 0.12 788170 0.19 2937900 0.22 0.633 0.19
1994 1194400 0.11 738960 0.19 4303300 0.17 0.910 0.17
1995 1121800 0.09 623550 0.17 3600900 0.15 0.916 0.17
1996 1094600 0.08 631150 0.13 3805500 0.12 0.965 0.16
1997 1028900 0.07 590490 0.11 3170000 0.13 1.083 0.16
1998 853440 0.06 519090 0.10 2106200 0.11 0.833 0.16
1999 753190 0.06 525630 0.08 1003000 0.13 0.771 0.16
2000 654620 0.07 487870 0.09 1590300 0.11 0.518 0.16
2001 708800 0.07 468450 0.10 2109400 0.11 0.569 0.16
2002 757340 0.07 481650 0.10 1819900 0.12 0.713 0.17
2003 766510 0.08 487040 0.11 2576600 0.12 0.635 0.17
2004 882290 0.07 504450 0.11 3373000 0.11 0.758 0.16
2005 841020 0.07 476790 0.12 2145900 0.11 0.547 0.17
2006 863210 0.07 591280 0.10 1506400 0.14 0.691 0.15
2007 731980 0.08 529520 0.10 1556900 0.12 0.727 0.15
2008 642550 0.07 411180 0.11 2336900 0.10 0.612 0.13
2009 669920 0.07 381390 0.12 1456200 0.11 0.570 0.13
2010 694200 0.07 457520 0.10 1784100 0.10 0.597 0.12
2011 724650 0.07 443330 0.11 2358600 0.09 0.630 0.12
2012 762970 0.07 439500 0.10 2115100 0.09 0.511 0.13
2013 843890 0.07 537420 0.10 1898500 0.11 0.596 0.12
2014 859180 0.07 555420 0.10 2464800 0.10 0.604 0.13
2015 877390 0.08 537440 0.11 2198200 0.11 0.502 0.13
2016 943640 0.08 620050 0.10 2063800 0.11 0.512 0.13
2017 1017500 0.07 662630 0.10 3125400 0.10 0.523 0.13
2018 1088300 0.08 675580 0.11 2265700 0.12 0.480 0.13
2019 1165500 0.08 792650 0.10 2807500 0.11 0.572 0.13
2020 1150900 0.08 758470 0.11 2509800 0.11 0.529 0.13
2021 1155400 0.08 784360 0.11 2442800 0.12 0.597 0.13
2022 1121300 0.09 736820 0.13 3083700 0.13 0.574 0.14
2023 1154800 0.11 717490 0.14 2942600 0.16 0.540 0.17
2024 1208400 0.15 777260 0.17 2855300 0.25 0.543 0.22
", header = TRUE, stringsAsFactors = FALSE)

table7 <- data.frame(
  year = 1995:2024,
  age2_index = c(2228, 1514, 814, 628, 818, 497, 1178, 1741, NA, NA,
    NA, 1548, NA, 1042, 2996, 951, NA, 3674, 3983, NA, NA, NA,
    1823, 2535, NA, NA, 2346, NA, NA, 2334),
  spawning_biomass_index = c(764, 798, 559, 776, 913, 1288, NA, NA, NA, NA,
    NA, 1604, NA, 644, 1208, 1368, NA, 1711, 2059, NA, NA, NA,
    1587, 1765, NA, NA, 1919, NA, NA, 1073)
)

table10 <- read.table(text = "
year value period
1986 3300 1986-1997
1987 3100 1986-1997
1988 2824 1986-1997
1990 2493 1986-1997
1991 3000 1986-1997
1992 2400 1986-1997
1993 2400 1986-1997
1994 2376 1986-1997
1995 2400 1986-1997
1996 2142 1986-1997
1997 1367 1986-1997
1998 1189 1998-2007
1999 1126 1998-2007
2001 1150 1998-2007
2002 1558 1998-2007
2003 1337 1998-2007
2004 1633 1998-2007
2005 1727 1998-2007
2006 1491 1998-2007
2007 1205 1998-2007
2009 2292 2009-2024
2010 1644 2009-2024
2011 1429 2009-2024
2012 1982 2009-2024
2013 2467 2009-2024
2014 1957 2009-2024
2015 2555 2009-2024
2016 2536 2009-2024
2017 3158 2009-2024
2018 3494 2009-2024
2019 3565 2009-2024
2020 3834 2009-2024
2021 3117 2009-2024
2022 3107 2009-2024
2023 3721 2009-2024
2024 3810 2009-2024
", header = TRUE, stringsAsFactors = FALSE)

if (nrow(table9) != 39L || nrow(table12) != 39L || nrow(table11) != 39L ||
    nrow(table8) != 14L || nrow(table7) != 30L || nrow(table10) != 36L ||
    !identical(table9$year, 1986:2024) ||
    !identical(table12$year, 1986:2024) ||
    !identical(table11$year, 1986:2024) ||
    any(as.matrix(table9[, 2:9]) < 0) || any(as.matrix(table12[, 2:8]) < 0)) {
  stop("One or more transcribed report tables failed their coverage or value checks.",
    call. = FALSE)
}

input_fields <- fields(inputs_path)
output_fields <- fields(outputs_path)
assumption_fields <- fields(assumptions_path)
source_report <- "INIDEP Official Technical Report 47/2025"
region <- "Southern stock south of 41°S"
input <- function(type, measure, basis, value, unit, source_reference, year = NA_integer_,
                  age = NA_integer_, fleet = "", survey = "", season = "",
                  observation_id = "", notes = "", transformation = "") {
  rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit,
    year = year, year_basis = if (is.na(year)) "" else "calendar_year",
    age = age, fleet = fleet, survey = survey, region = region, season = season,
    observation_id = observation_id, source_type = "official_table",
    source_reference = paste(source_report, source_reference, sep = ", "),
    transformation = transformation, notes = notes))
}
output <- function(type, measure, value, unit, year, source_reference,
                   age = NA_integer_, age_group = "", source_type = "official_table",
                   notes = "") {
  rows(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    age_group = age_group, source_type = source_type,
    source_reference = paste(source_report, source_reference, sep = ", "),
    notes = notes))
}
assumption <- function(component, setting, value, source_reference, notes = "") {
  rows(assumption_fields, list(assessment_id = assessment_id,
    component = component, setting = setting, value = value, region = region,
    source_reference = paste(source_report, source_reference, sep = ", "), notes = notes))
}

ages <- 1:7
age_note <- function(age) if (age == 7L) "Age 7 represents the reported 7+ group." else ""
inputs <- list()
for (i in seq_along(ages)) {
  a <- ages[i]
  inputs[[length(inputs) + 1L]] <- input("weight", "weight_at_age", "kg_per_fish",
    c(0.044, 0.160, 0.351, 0.614, 0.924, 1.270, 1.889)[i], "kg per fish",
    "Table 6, p. 10", age = a, season = "1 January", notes = age_note(a))
  inputs[[length(inputs) + 1L]] <- input("weight", "weight_at_age", "kg_per_fish",
    c(0.102, 0.264, 0.495, 0.790, 1.122, 1.480, 2.101)[i], "kg per fish",
    "Table 6, p. 10", age = a, season = "1 July", notes = age_note(a))
  inputs[[length(inputs) + 1L]] <- input("maturity", "maturity_at_age", "proportion",
    c(0.000, 0.103, 0.893, 0.997, 1, 1, 1)[i], "proportion",
    "Table 6, p. 10", age = a, notes = age_note(a))
  inputs[[length(inputs) + 1L]] <- input("M", "natural_mortality_at_age", "per_year",
    0.3, "per year", "Table 6, p. 10", age = a,
    notes = paste("Fixed natural mortality.", age_note(a)))
}

for (i in seq_len(nrow(table7))) {
  if (!is.na(table7$age2_index[i])) inputs[[length(inputs) + 1L]] <-
    input("index", "recruitment_index", "index_scale", table7$age2_index[i],
      "fish per trawl-hour", "Table 7, p. 11", year = table7$year[i], age = 2,
      survey = "Summer juvenile survey", season = "summer",
      notes = "Relative abundance index for age-2 fish; absent years and dashes are not zeros.")
  if (!is.na(table7$spawning_biomass_index[i])) inputs[[length(inputs) + 1L]] <-
    input("index", "relative_biomass_index", "index_scale",
      table7$spawning_biomass_index[i], "kg per trawl-hour", "Table 7, p. 11",
      year = table7$year[i], survey = "Summer reproductive survey", season = "summer",
      notes = "Reproductive-biomass index; absent years and dashes are not zeros.")
}

for (i in seq_len(nrow(table8))) for (j in seq_along(ages)) {
  inputs[[length(inputs) + 1L]] <- input("index", "numbers_at_age", "numbers",
    table8[i, paste0("age", ages[j])], "thousand individuals",
    "Table 8, p. 11", year = table8$year[i], age = ages[j],
    survey = "INIDEP global winter survey", season = "winter",
    notes = paste("Survey-estimated numbers at age, not a complete annual series.", age_note(ages[j])))
}

for (i in seq_len(nrow(table9))) {
  for (j in seq_along(ages)) inputs[[length(inputs) + 1L]] <-
    input("catch", "numbers_at_age", "numbers", table9[i, paste0("age", ages[j]), drop = TRUE],
      "thousand individuals", "Table 9, p. 13", year = table9$year[i], age = ages[j],
      fleet = "Total estimated catch, all sources", notes = paste(
        "Aggregate estimated catch by age includes Argentine and foreign fisheries,",
        "discard and bycatch. The report combines source catches in this table.", age_note(ages[j])),
      transformation = "Removed printed Spanish thousands separators; values remain in thousands of fish.")
  inputs[[length(inputs) + 1L]] <- input("catch", "catch_biomass", "biomass",
    table9$total_catch_t[i], "tonnes", "Table 9, p. 13", year = table9$year[i],
    fleet = "Total estimated catch, all sources",
    notes = "Reported total catch in tonnes, paired with the aggregate catch-at-age table.")
}

for (i in seq_len(nrow(table10))) inputs[[length(inputs) + 1L]] <-
  input("index", "relative_biomass_index", "index_scale", table10$value[i],
    "kg per trawl-hour", "Table 10, p. 13", year = table10$year[i],
    fleet = "Fresher trawl fleet", observation_id = paste("CPUE period", table10$period[i]),
    notes = "Independent standardized CPUE estimate for this reported time period; the three periods are separate series.")

input_rows <- do.call(rbind, inputs)

outputs <- list()
for (i in seq_len(nrow(table11))) {
  y <- table11$year[i]
  outputs[[length(outputs) + 1L]] <- output("biomass", "total_biomass",
    table11$total_biomass[i], "tonnes", y, "Table 11, p. 25")
  outputs[[length(outputs) + 1L]] <- output("biomass", "spawning_biomass",
    table11$spawning_biomass[i], "tonnes", y, "Table 11, p. 25")
  outputs[[length(outputs) + 1L]] <- output("recruitment", "recruitment",
    table11$recruitment[i], "thousand individuals", y, "Table 11, p. 25",
    notes = "Table 11 omits the unit; thousand individuals is inferred because these values match Table 12 age-1 numbers within report rounding.")
  outputs[[length(outputs) + 1L]] <- output("mortality", "fishing_mortality_scalar",
    table11$fishing_mortality[i], "per year", y, "Table 11, p. 25",
    notes = "Annual scalar f component; the report describes age-specific F as this component multiplied by age selectivity.")
  cv_columns <- c(total_biomass_cv = "total_biomass_cv",
    spawning_biomass_cv = "spawning_biomass_cv",
    recruitment_cv = "recruitment_cv",
    fishing_mortality_scalar_cv = "fishing_mortality_cv")
  for (measure in names(cv_columns)) {
    value <- table11[[cv_columns[[measure]]]][i]
    type <- if (measure %in% c("total_biomass_cv", "spawning_biomass_cv")) {
      "biomass"
    } else if (measure == "recruitment_cv") "recruitment" else "mortality"
    outputs[[length(outputs) + 1L]] <- output(type, measure, value, "ratio", y,
      "Table 11, p. 25", notes = "The source reports this value as a coefficient of variation; it is not a standard error.")
  }
}

for (i in seq_len(nrow(table12))) for (j in seq_along(ages)) {
  age_note_output <- age_note(ages[j])
  if (table12$year[i] == 2009L && ages[j] == 2L) {
    age_note_output <- paste(age_note_output,
      "The report prints this value as '147038.0'; digits were regrouped as 1,470,380 to match the table's thousands convention.")
  }
  outputs[[length(outputs) + 1L]] <- output("population", "numbers_at_age",
    table12[i, paste0("age", ages[j]), drop = TRUE], "thousand individuals",
    table12$year[i], "Table 12, p. 26", age = ages[j],
    age_group = if (ages[j] == 7L) "7+" else "", notes = age_note_output)
}

total_n <- rowSums(table12[, paste0("age", ages)])
for (i in seq_len(nrow(table12))) outputs[[length(outputs) + 1L]] <-
  output("population", "total_abundance", total_n[i], "thousand individuals",
    table12$year[i], "Derived from Table 12, p. 26", source_type = "derived_source_output",
    notes = "Sum of reported age 1-6 and 7+ model-estimated abundance; no uncertainty is available for the derived total.")
output_rows <- do.call(rbind, outputs)

assumptions <- do.call(rbind, list(
  assumption("assessment", "run_and_period", "2025 production assessment; model years 1986-2024; catch advice for 2026", "cover; pp. 1-2"),
  assumption("assessment", "method", "Annual statistical catch-at-age model (ECE) implemented in ADMB", "pp. 12-13; Appendix I"),
  assumption("assessment", "population_unit", "Southern Merluccius hubbsi effective south of 41°S; most abundant 42°S-48°S, 50-400 m depth", "p. 3"),
  assumption("age_structure", "age_groups", "Ages 1-6 and a 7+ group", "Tables 6-9 and 12", "Age 7 in the database identifies the reported plus group."),
  assumption("catch", "catch_at_age", "Estimated catch-at-age includes Argentine and foreign fisheries, discards and bycatch; landings-based estimates for 1986-2006 and observer-corrected estimates for 2007-2024", "Table 9, p. 13"),
  assumption("fishing_mortality", "age_selectivity_periods", "Age-specific selectivity patterns are fitted separately for 1986-2004, 2005-2008 and 2009-2024", "pp. 12-13"),
  assumption("fishing_mortality", "fishing_mortality_scale", "Age-specific F is the annual scalar f multiplied by age selectivity", "p. 12; Table 11, p. 25", "Table 11 reports the scalar component but not numerical F-at-age values."),
  assumption("natural_mortality", "natural_mortality_at_age", "Fixed M=0.3 per year for ages 1-6 and 7+", "Table 6, p. 10"),
  assumption("biology", "weight_and_maturity", "Population weight-at-age is reported separately for 1 January and 1 July; maturity is age-specific", "Table 6, p. 10"),
  assumption("index", "summer_indices", "Summer age-2 recruitment and reproductive-biomass indices are used; reported dashes are unavailable or unused observations", "pp. 10-11; Table 7, p. 11"),
  assumption("index", "global_survey", "Winter global survey supplies total biomass and age composition in selected years; incomplete surveys and years considered under-sampled were omitted or extrapolated", "pp. 11-12; Table 8, p. 11"),
  assumption("index", "commercial_cpue", "Three independent fresher-fleet CPUE series cover 1986-1997, 1998-2007 and 2009-2024", "Table 10, p. 13"),
  assumption("timing", "within_year_sampling_time", "Survey seasons are identified as summer and winter, but precise within-year sampling fractions are not reported", "pp. 10-11"),
  assumption("uncertainty", "reported_output_uncertainty", "Table 11 reports coefficients of variation for total biomass, spawning biomass, recruitment and scalar f", "Table 11, p. 25", "CV values are retained as separate ratio measures, not converted to standard errors."),
  assumption("reported_units", "recruitment_unit", "Table 11 does not print the recruitment unit; the thousand-individual scale is inferred from its correspondence with Table 12 age-1 abundance", "Table 11, p. 25; Table 12, p. 26")
))

stock_fields <- fields(stocks_path)
assessment_fields <- fields(assessments_path)
stock <- rows(stock_fields, list(
  stock_id = stock_id, charbonneau_id = "", authority = "INIDEP",
  authority_stock_id = "Efectivo sur de 41° S", scientific_name = "Merluccius hubbsi",
  common_name = "Southern Argentine hake",
  area = "South Atlantic south of 41°S; most abundant from 42°S to 48°S, 50-400 m depth",
  region = "Argentina", ocean = "Southwest Atlantic",
  notes = "The southern and northern effective units are assessed separately; this stock represents the southern unit south of 41°S."
))
assessment <- rows(assessment_fields, list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2024L, estimate_terminal_year = 2024L,
  assessment_type = "full_assessment", model_family = "ADMB",
  model_version = "INIDEP statistical catch-at-age model (ECE), 2025 run for 2026 catch advice",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = "", data_url = "", model_url = "",
  repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "Primary detailed report is a signed INIDEP document hosted by Fishery Progress; CFP Act 34/2025 verifies its use for 2026 advice."
))

cat("Stock:", stock_id, "\n")
cat("Source inputs:", nrow(input_rows), "rows; outputs:", nrow(output_rows),
  "rows; assumptions:", nrow(assumptions), "rows\n")
cat("2024 spawning biomass:",
  table11$spawning_biomass[table11$year == 2024L], "tonnes\n")
cat("2009 Table 12 age-2 abundance:",
  table12$age2[table12$year == 2009L], "thousand individuals\n")

if (write_mode) {
  append_rows(stocks_path, stock)
  append_rows(assessments_path, assessment)
  append_rows(assumptions_path, assumptions)
  append_rows(inputs_path, input_rows)
  append_rows(outputs_path, output_rows)

  replace_csv_cell(candidates_path, paste0("\"", candidate_id, "\","),
    15L, "not_started", "partial")
  replace_csv_cell(selected_path, paste0("\"1\",\"", candidate_id, "\","),
    13L, "selected_for_source_curation", "partial_source_import")
  replace_csv_cell(units_path, paste0("\"candidate:", candidate_unit_id, "\","),
    7L, "not_started", "partial")
  cat("Imported the source tables and marked the assessment partial.\n")
}
