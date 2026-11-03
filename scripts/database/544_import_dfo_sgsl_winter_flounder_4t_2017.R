root <- "."
db <- file.path(root, "database")
source(file.path(root, "scripts", "database", "pacific_tables.R"))

stock_id <- "dfo_sgsl_winter_flounder_4t"
full_id <- "dfo_sgsl_winter_flounder_2017"
update_id <- "dfo_sgsl_winter_flounder_2024_indicators"
report_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40804392.pdf"
update_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf"

stocks_path <- file.path(db, "stocks.csv")
assessments_path <- file.path(db, "assessments.csv")
stocks_existing <- utils::read.csv(stocks_path, stringsAsFactors = FALSE)
assessments_existing <- utils::read.csv(assessments_path, stringsAsFactors = FALSE)
if (stock_id %in% stocks_existing$stock_id) cli::cli_abort("The NAFO 4T winter flounder stock already exists.")
if (any(c(full_id, update_id) %in% assessments_existing$assessment_id)) {
  cli::cli_abort("A NAFO 4T winter flounder assessment record already exists.")
}

source_tables <- list(
  catch = read.table(text = "year 2 3 4 5 6 7 8 9 10 11 12\n1973 0 1 72 378 898 1260 1060 610 344 170 165\n1974 3 44 239 519 857 1088 771 399 220 111 111\n1975 3 60 765 988 1347 1218 800 362 157 63 47\n1976 31 323 1199 1874 1646 1399 808 357 178 90 71\n1977 11 127 430 1058 905 782 480 277 87 37 24\n1978 47 407 749 921 1397 583 352 106 98 48 26\n1979 0 0 310 1373 1725 1440 853 251 66 27 14\n1980 0 1 164 752 1818 1988 1464 226 85 46 19\n1981 0 16 228 1053 1576 1841 960 447 95 69 23\n1982 0 6 226 1397 1860 1650 1083 499 243 122 98\n1983 5 25 152 581 1291 1544 1118 576 210 76 43\n1984 0 6 50 120 155 124 73 29 9 3 2\n1985 0 4 33 143 405 627 614 385 171 68 42\n1986 1 33 264 805 1260 1245 932 474 199 81 58\n1987 1 38 393 1054 1373 1270 919 448 174 68 36\n1988 1 45 476 1220 1300 1007 612 259 94 37 20\n1989 0 7 225 952 1351 1334 929 482 212 88 58\n1990 0 1 209 1184 1624 1555 856 299 79 50 28\n1991 0 137 571 1464 2623 1921 1094 410 91 15 23\n1992 24 79 430 993 1460 1176 760 358 167 41 20\n1993 0 22 269 671 1158 965 819 437 245 43 29\n1994 5 22 199 674 1102 860 637 289 96 29 16\n1995 0 3 51 214 433 436 368 187 66 23 12\n1996 0 4 70 292 570 601 497 244 80 29 16\n1997 1 20 152 472 922 959 738 289 71 45 16\n1998 0 4 70 275 523 517 319 139 44 15 7\n1999 0 3 62 277 542 541 354 150 46 16 7\n2000 1 9 60 221 391 417 457 188 57 23 11\n2001 2 9 57 227 418 417 422 184 61 25 12\n2002 5 18 68 212 361 328 311 137 47 19 8\n2003 0 7 77 274 463 368 320 137 48 19 7\n2004 0 2 25 150 348 258 272 134 44 28 17\n2005 1 5 61 172 389 297 285 146 68 12 16\n2006 0 1 27 67 174 172 223 147 41 30 13\n2007 3 4 22 112 162 169 108 93 36 9 2\n2008 5 6 16 73 165 171 142 87 30 11 4\n2009 3 7 29 104 191 178 152 76 25 9 4\n2010 35 113 197 263 287 226 205 93 32 12 6\n2011 32 122 220 288 324 254 255 98 31 11 5\n2012 13 74 236 363 291 210 117 46 15 6 3\n2013 5 23 100 211 184 144 78 33 12 5 2\n2014 2 11 66 148 185 152 88 33 9 3 2\n2015 5 13 33 86 134 122 165 92 35 16 8\n2016 3 10 36 99 154 135 146 69 24 10 4", header = TRUE, check.names = FALSE),
  survey = read.table(text = "year 2 3 4 5 6 7 8 9 10 11 12\n1973 387 2028 5306 6371 6742 6678 4726 2322 1110 514 399\n1974 11381 11428 10564 14498 20262 26622 20330 11095 5852 2848 2240\n1975 111 1210 8089 9507 12503 11714 7950 3796 1915 797 792\n1976 1529 15401 48329 59452 46577 40860 25153 11944 6293 3258 3128\n1977 439 4051 8450 12297 6694 4223 2284 1559 371 158 99\n1978 100 2489 11841 23764 33984 13603 8256 2591 2279 1140 677\n1979 226 5086 8825 14166 13041 10986 6434 2288 1039 456 407\n1980 164 4057 14594 19283 23245 23579 17933 3117 1419 746 448\n1981 2347 7587 12994 17859 17659 19800 10742 5743 2553 1652 948\n1982 127 1247 6208 17271 15576 12106 7749 3709 1965 1022 927\n1983 808 5976 13897 21775 26244 23348 15026 7484 2779 1016 555\n1984 1203 3280 5121 5949 5486 4721 3649 2266 1092 445 308\n1985 1414 4283 6776 9398 9034 6696 4148 1813 664 255 153\n1986 1603 7385 13050 14997 12675 9501 6244 2908 1148 455 274\n1987 824 4443 8330 8486 5632 3644 2229 1009 399 159 90\n1988 694 3856 9762 12568 9515 6831 4260 1924 735 289 158\n1989 710 6289 19575 23339 13435 7699 3853 1555 612 251 166\n1990 1947 9512 28774 30570 12341 6319 2734 676 93 93 43\n1991 2644 7932 17666 15921 8824 5137 2886 926 205 24 51\n1992 2408 12818 18495 18326 13276 7465 3008 1272 454 121 57\n1993 1795 7490 10730 11331 10829 5989 4501 2409 1300 232 230\n1994 3606 5453 6433 7439 6437 3751 2460 1066 356 108 56\n1995 19438 29683 18923 12956 8562 5036 3218 1331 427 145 88\n1996 4225 10571 11028 10541 7969 5104 3246 1350 434 162 105\n1997 4785 12933 13084 11581 7669 4650 2445 847 236 137 48\n1998 2878 10094 11337 9506 6080 3390 1583 581 169 58 27\n1999 4776 13079 16666 17061 12567 7377 3606 1236 340 116 47\n2000 6845 17178 16860 17359 11828 7106 5471 1650 401 156 66\n2001 3085 9519 10835 11254 8321 5024 3730 1216 329 129 57\n2002 6667 15030 13886 13351 11319 8068 7257 3337 1291 553 279\n2003 5784 12779 11568 10118 7508 4284 3296 1363 498 208 91\n2004 3055 9041 13780 14124 11317 5455 4658 1555 563 256 137\n2005 13065 25583 16093 12158 10901 5767 3770 1575 647 105 163\n2006 1697 7288 10936 9953 7218 5022 4184 2419 692 402 199\n2007 1487 7502 8845 10463 8146 4707 2795 2401 984 393 151\n2008 2539 6475 7327 8386 6347 3595 2188 1094 358 136 62\n2009 9494 19192 14730 11779 8132 4804 3318 1456 443 160 60\n2010 3167 9080 10599 9053 5955 3354 2537 1032 340 128 60\n2011 1977 3699 4416 4062 3288 2145 1964 712 211 75 30\n2012 1129 3098 4539 3844 1831 955 441 154 48 18 8\n2013 2126 4824 6339 5432 2923 1848 879 325 101 37 15\n2014 5844 8947 8150 5354 2792 1423 634 200 51 18 12\n2015 3260 5498 4086 3472 2440 1452 1553 720 250 109 53\n2016 2794 4819 4132 3034 1605 783 636 255 81 33 14", header = TRUE, check.names = FALSE),
  maturity = read.table(text = "year 2 3 4 5 6 7 8 9 10 11 12\n1973 0.054 0.212 0.472 0.689 0.847 0.920 0.954 0.976 0.987 0.990 0.995\n1974 0.082 0.192 0.693 0.887 0.949 0.974 0.985 0.991 0.994 0.995 0.997\n1975 0.276 0.448 0.795 0.869 0.945 0.969 0.980 0.988 0.994 0.996 0.999\n1976 0.269 0.494 0.712 0.835 0.921 0.961 0.978 0.989 0.994 0.995 0.998\n1977 0.205 0.382 0.562 0.740 0.850 0.940 0.967 0.936 0.989 0.991 0.996\n1978 0.223 0.671 0.670 0.818 0.880 0.937 0.950 0.997 0.994 0.988 0.998\n1979 0.079 0.257 0.466 0.722 0.857 0.869 0.921 0.951 0.989 0.993 0.998\n1980 0.078 0.304 0.529 0.698 0.842 0.899 0.944 0.977 0.985 0.993 0.998\n1981 0.114 0.219 0.501 0.752 0.894 0.925 0.947 0.965 0.938 0.991 0.998\n1982 0.267 0.498 0.713 0.821 0.884 0.918 0.937 0.954 0.967 0.971 0.980\n1983 0.475 0.614 0.762 0.857 0.918 0.950 0.967 0.980 0.987 0.989 0.993\n1984 0.429 0.714 0.856 0.923 0.962 0.982 0.991 0.996 0.998 0.998 0.999\n1985 0.382 0.562 0.803 0.906 0.951 0.970 0.981 0.988 0.993 0.995 0.997\n1986 0.430 0.618 0.789 0.887 0.946 0.970 0.982 0.989 0.994 0.995 0.997\n1987 0.408 0.584 0.738 0.838 0.909 0.946 0.966 0.981 0.989 0.991 0.995\n1988 0.345 0.555 0.749 0.854 0.919 0.952 0.968 0.980 0.987 0.989 0.994\n1989 0.405 0.589 0.760 0.854 0.912 0.943 0.961 0.977 0.988 0.990 0.996\n1990 0.396 0.703 0.826 0.899 0.949 0.955 0.971 0.981 0.997 0.993 0.998\n1991 0.601 0.720 0.816 0.886 0.956 0.968 0.964 0.983 0.994 0.998 0.996\n1992 0.704 0.811 0.905 0.939 0.969 0.971 0.989 0.990 0.998 0.998 1.000\n1993 0.416 0.712 0.855 0.906 0.959 0.977 0.984 0.988 0.993 0.999 0.999\n1994 0.255 0.532 0.802 0.905 0.950 0.970 0.980 0.987 0.992 0.993 0.996\n1995 0.180 0.372 0.617 0.798 0.911 0.955 0.973 0.984 0.991 0.993 0.997\n1996 0.174 0.394 0.669 0.829 0.918 0.955 0.973 0.985 0.992 0.994 0.997\n1997 0.267 0.437 0.707 0.824 0.910 0.958 0.981 0.991 0.989 0.990 0.990\n1998 0.392 0.561 0.727 0.831 0.905 0.946 0.968 0.983 0.991 0.993 0.996\n1999 0.337 0.546 0.761 0.869 0.929 0.956 0.971 0.982 0.989 0.991 0.995\n2000 0.322 0.522 0.737 0.861 0.929 0.959 0.973 0.984 0.991 0.992 0.996\n2001 0.323 0.520 0.731 0.859 0.933 0.963 0.976 0.985 0.991 0.993 0.996\n2002 0.252 0.458 0.695 0.855 0.945 0.976 0.987 0.993 0.996 0.997 0.998\n2003 0.218 0.427 0.686 0.849 0.943 0.975 0.987 0.993 0.996 0.997 0.999\n2004 0.254 0.494 0.730 0.880 0.955 0.968 0.981 0.992 0.967 0.999 0.998\n2005 0.201 0.371 0.642 0.880 0.951 0.971 0.985 0.992 0.996 0.999 0.996\n2006 0.217 0.398 0.656 0.840 0.927 0.959 0.984 0.987 0.995 0.998 0.998\n2007 0.193 0.395 0.606 0.816 0.893 0.943 0.969 0.981 0.998 0.989 1.000\n2008 0.282 0.463 0.709 0.852 0.930 0.961 0.976 0.986 0.992 0.993 0.997\n2009 0.312 0.463 0.668 0.833 0.930 0.965 0.979 0.987 0.992 0.993 0.996\n2010 0.378 0.564 0.754 0.868 0.937 0.968 0.982 0.991 0.995 0.996 0.998\n2011 0.332 0.592 0.791 0.899 0.956 0.977 0.986 0.992 0.995 0.996 0.998\n2012 0.391 0.647 0.853 0.936 0.972 0.986 0.991 0.995 0.997 0.998 0.999\n2013 0.285 0.546 0.781 0.916 0.971 0.986 0.991 0.994 0.996 0.996 0.997\n2014 0.229 0.430 0.703 0.856 0.935 0.967 0.981 0.989 0.994 0.995 0.998\n2015 0.301 0.458 0.689 0.847 0.932 0.965 0.979 0.988 0.993 0.994 0.997\n2016 0.251 0.468 0.677 0.804 0.893 0.940 0.964 0.980 0.989 0.991 0.995", header = TRUE, check.names = FALSE),
  survey_weight = read.table(text = "year 2 3 4 5 6 7 8 9 10 11 12\n1973 0.046 0.094 0.152 0.215 0.291 0.360 0.422 0.499 0.584 0.616 0.741\n1974 0.036 0.060 0.187 0.278 0.365 0.443 0.503 0.566 0.624 0.644 0.708\n1975 0.067 0.097 0.181 0.230 0.316 0.404 0.467 0.570 0.717 0.806 1.041\n1976 0.078 0.118 0.169 0.223 0.299 0.369 0.426 0.493 0.577 0.619 0.853\n1977 0.064 0.093 0.129 0.179 0.240 0.316 0.382 0.357 0.548 0.585 0.706\n1978 0.062 0.162 0.142 0.193 0.234 0.338 0.398 0.599 0.563 0.550 0.712\n1979 0.042 0.077 0.114 0.182 0.250 0.276 0.340 0.446 0.582 0.625 0.777\n1980 0.051 0.097 0.141 0.184 0.258 0.310 0.354 0.470 0.547 0.591 0.767\n1981 0.053 0.079 0.138 0.210 0.295 0.336 0.379 0.432 0.542 0.576 0.760\n1982 0.066 0.114 0.176 0.225 0.272 0.313 0.350 0.398 0.458 0.484 0.574\n1983 0.052 0.076 0.118 0.165 0.225 0.286 0.341 0.408 0.473 0.495 0.559\n1984 0.037 0.076 0.121 0.169 0.242 0.334 0.418 0.502 0.570 0.592 0.664\n1985 0.046 0.074 0.139 0.196 0.254 0.310 0.365 0.442 0.535 0.573 0.721\n1986 0.052 0.083 0.132 0.191 0.266 0.334 0.396 0.479 0.572 0.607 0.729\n1987 0.048 0.076 0.115 0.161 0.222 0.288 0.352 0.433 0.512 0.539 0.619\n1988 0.048 0.082 0.133 0.184 0.247 0.308 0.361 0.424 0.491 0.518 0.614\n1989 0.059 0.091 0.138 0.181 0.231 0.283 0.341 0.435 0.550 0.592 0.718\n1990 0.037 0.090 0.132 0.180 0.241 0.277 0.315 0.384 0.717 0.564 0.887\n1991 0.052 0.081 0.113 0.151 0.240 0.298 0.310 0.408 0.508 0.688 0.558\n1992 0.081 0.101 0.148 0.182 0.235 0.266 0.366 0.409 0.546 0.563 0.778\n1993 0.043 0.090 0.146 0.188 0.256 0.322 0.384 0.442 0.514 0.705 0.774\n1994 0.030 0.067 0.132 0.186 0.242 0.293 0.340 0.401 0.465 0.488 0.557\n1995 0.029 0.055 0.099 0.158 0.233 0.295 0.347 0.417 0.509 0.550 0.720\n1996 0.031 0.061 0.111 0.163 0.222 0.279 0.335 0.415 0.513 0.551 0.678\n1997 0.035 0.055 0.104 0.143 0.198 0.261 0.318 0.416 0.438 0.400 0.418\n1998 0.048 0.072 0.108 0.146 0.200 0.262 0.322 0.398 0.477 0.507 0.610\n1999 0.040 0.068 0.115 0.160 0.210 0.258 0.303 0.365 0.434 0.460 0.547\n2000 0.034 0.057 0.097 0.140 0.189 0.234 0.276 0.334 0.405 0.433 0.530\n2001 0.038 0.061 0.100 0.146 0.199 0.242 0.278 0.329 0.402 0.436 0.575\n2002 0.033 0.056 0.096 0.151 0.223 0.286 0.336 0.396 0.459 0.482 0.558\n2003 0.032 0.053 0.090 0.138 0.200 0.252 0.294 0.345 0.403 0.426 0.504\n2004 0.032 0.057 0.090 0.137 0.194 0.227 0.254 0.317 0.317 0.404 0.396\n2005 0.022 0.037 0.075 0.129 0.179 0.214 0.259 0.295 0.336 0.437 0.374\n2006 0.025 0.043 0.078 0.118 0.170 0.207 0.256 0.302 0.374 0.394 0.458\n2007 0.029 0.046 0.074 0.125 0.158 0.235 0.270 0.331 0.430 0.429 0.578\n2008 0.031 0.049 0.087 0.128 0.175 0.216 0.254 0.305 0.366 0.391 0.483\n2009 0.033 0.048 0.080 0.127 0.184 0.230 0.267 0.310 0.351 0.365 0.407\n2010 0.039 0.058 0.089 0.124 0.170 0.217 0.262 0.322 0.387 0.410 0.478\n2011 0.035 0.060 0.095 0.134 0.179 0.216 0.248 0.288 0.330 0.346 0.394\n2012 0.035 0.063 0.108 0.152 0.201 0.245 0.285 0.339 0.403 0.428 0.507\n2013 0.030 0.059 0.108 0.176 0.241 0.283 0.313 0.346 0.380 0.394 0.439\n2014 0.031 0.053 0.097 0.144 0.199 0.250 0.295 0.353 0.426 0.460 0.591\n2015 0.040 0.058 0.098 0.148 0.205 0.255 0.296 0.347 0.406 0.430 0.519\n2016 0.035 0.060 0.094 0.129 0.176 0.226 0.272 0.325 0.376 0.394 0.446", header = TRUE, check.names = FALSE)
)

matrix_long <- function(x) {
  years <- as.integer(x$year)
  ages <- as.integer(names(x)[-1L])
  data.frame(
    year = rep(years, times = length(ages)),
    age = rep(ages, each = length(years)),
    value = as.vector(as.matrix(x[-1L])),
    stringsAsFactors = FALSE
  )
}

input_rows <- function(assessment_id, type, measure, basis, value, unit,
                       source_reference, year = NA_integer_, age = NA_integer_,
                       fleet = "", survey = "", region = "NAFO 4T",
                       sampling_time = NA_real_, source_type = "official_table",
                       transformation = "", notes = "") {
  n <- length(value)
  year <- rep_len(year, n)
  pacific_database_row(
    "inputs", n = n,
    assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = "",
    region = rep_len(region, n), season = "",
    year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"),
    age = rep_len(age, n), value = as.numeric(value), unit = unit,
    sampling_time = rep_len(sampling_time, n),
    source_type = rep_len(source_type, n),
    source_reference = rep_len(source_reference, n),
    transformation = rep_len(transformation, n), notes = rep_len(notes, n)
  )
}

assumption_rows <- function(assessment_id, component, setting, value,
                            source_reference, notes = "", survey = "") {
  n <- length(value)
  pacific_database_row(
    "assumptions", n = n, assessment_id = assessment_id,
    component = rep_len(component, n), fleet = "",
    survey = rep_len(survey, n), sex = "", region = "NAFO 4T", season = "",
    setting = rep_len(setting, n), value = as.character(value),
    source_reference = rep_len(source_reference, n), notes = rep_len(notes, n)
  )
}

output_rows <- function(assessment_id, type, measure, value, unit,
                        source_reference, year = NA_integer_, age = NA_integer_,
                        survey = "", region = "NAFO 4T",
                        source_type = "official_document", notes = "") {
  n <- length(value)
  pacific_database_row(
    "outputs", n = n, assessment_id = assessment_id,
    type = type, measure = measure, fleet = "", survey = rep_len(survey, n),
    sex = "", region = rep_len(region, n), season = "",
    year = rep_len(year, n), age = rep_len(age, n), age_group = "",
    value = as.numeric(value), se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = rep_len(unit, n), source_type = rep_len(source_type, n),
    source_reference = rep_len(source_reference, n), notes = rep_len(notes, n)
  )
}

stocks <- pacific_database_row(
  "stocks", stock_id = stock_id, charbonneau_id = "", authority = "DFO",
  authority_stock_id = "NAFO Division 4T", scientific_name = "Pseudopleuronectes americanus",
  common_name = "Winter Flounder - NAFO 4T", area = "NAFO Division 4T, southern Gulf of St. Lawrence",
  region = "Gulf of St. Lawrence", ocean = "Northwest Atlantic",
  notes = "Combined-sex DFO stock modelled as one population for the 2017 statistical catch-at-age assessment."
)

assessments <- pacific_database_row(
  "assessments", assessment_id = c(full_id, update_id), stock_id = stock_id,
  assessment_year = c(2017L, 2025L), terminal_year = c(2016L, 2024L),
  estimate_terminal_year = c(2016L, 2024L),
  assessment_type = c("full_assessment", "interim_update"),
  model_family = c("Statistical catch-at-age (TMB)", "Survey indicator"),
  model_version = c(
    "Models 1-7 compared; main inference outputs are reported for Model 2",
    "DFO Science Response 2025/010; three-year survey indicator update"
  ),
  is_current = c(TRUE, FALSE), is_applied = c(TRUE, TRUE),
  framework_year = NA_integer_, assessment_url = c(report_url, update_url),
  framework_url = "", data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = c(
    paste(
      "Latest detailed full assessment located for the current NAFO 4T unit.",
      "The paper compares seven model variants; Table 11 gives Model 7 the lowest AIC, while the main inference figures and prose outputs use Model 2.",
      "Inputs and outputs are partial: the fishery weight-at-age surface is not numerically available, the survey biomass plot is digitized, and annual fitted N/F/M/SSB series are not tabulated."
    ),
    paste(
      "Interim indicator update through 2024; not a new population-model fit.",
      "The report provides the three-year mean commercial-size survey indicator and scaled reference points, but not a numerical annual index table or numeric uncertainty for the three-year mean."
    )
  )
)

catch_long <- matrix_long(source_tables$catch)
survey_long <- matrix_long(source_tables$survey)
maturity_long <- matrix_long(source_tables$maturity)
weight_long <- matrix_long(source_tables$survey_weight)
catch_long$proportion <- catch_long$value / ave(catch_long$value, catch_long$year, FUN = sum)
survey_long$proportion <- survey_long$value / ave(survey_long$value, survey_long$year, FUN = sum)
years <- 1973:2016
landings_tonnes <- c(
  2300, 1920, 2010, 2407, 1235, 1121, 1585, 1976, 1941, 2305, 1799,
  149, 1180, 2044, 1811, 1414, 2089, 2077, 2536.2, 1892.7, 1664.8,
  1237.1, 668.0, 836.1, 1128.9, 620.7, 647.5, 576.7, 573.3, 440.3,
  468.3, 381.4, 383.3, 246.7, 192.8, 197.3, 209.7, 301.3, 317.8,
  305.9, 211.1, 191.9, 215.9, 191.9
)
stopifnot(length(landings_tonnes) == length(years))

rv_biomass_kg_per_tow <- c(6.7, 29.1, 12.5, 44.9, 5.1, 15.6, 8.7, 16.7, 16.2, 11.3, 16.7, 5.1, 5.9, 9.5, 4.1, 7.0, 9.1, 9.5, 6.5, 8.4, 6.3, 4.1, 6.6, 5.4, 4.7, 3.7, 6.6, 6.5, 5.0, 7.6, 4.5, 4.8, 5.0, 4.0, 4.0, 3.0, 4.4, 3.2, 1.7, 1.4, 2.2, 2.1, 1.8, 1.1)
stopifnot(length(rv_biomass_kg_per_tow) == length(years))

catch_ref <- paste0(report_url, "; Table 9, PDF p. 46 (report p. 36)")
survey_age_ref <- paste0(report_url, "; Table 10, PDF p. 47 (report p. 37)")
maturity_ref <- paste0(report_url, "; Table 12, PDF p. 49 (report p. 39)")
weight_ref <- paste0(report_url, "; Table 13, PDF p. 50 (report p. 40)")
catch_total_ref <- paste0(report_url, "; Table 1, PDF p. 36 (report p. 26)")
survey_biomass_ref <- paste0(report_url, "; Figure 18, PDF p. 68 (report p. 58)")

inputs <- do.call(rbind, list(
  input_rows(full_id, "catch", "landings_biomass", "biomass", landings_tonnes,
    "tonnes", catch_total_ref, year = years, fleet = "Commercial landings",
    notes = paste(
      "Annual total landings used in the assessment.",
      "The parenthetical Magdalen Islands bait-fishery values in Table 1 are components of these totals and are not added again."
    )),
  input_rows(full_id, "catch", "numbers_at_age", "numbers", catch_long$value,
    "thousand fish", catch_ref, year = catch_long$year, age = catch_long$age,
    fleet = "Commercial fishery", source_type = "official_table",
    notes = paste(
      "Reported catch-at-age numbers; age 12 is the 12+ group.",
      "The model uses annual catch proportions in numbers, derived from this table, alongside total landings; these rows are retained as the underlying reported age table, not as an additional age-specific catch likelihood."
    )),
  input_rows(full_id, "catch", "proportion_at_age", "proportion_numbers", catch_long$proportion,
    "proportion", catch_ref, year = catch_long$year, age = catch_long$age,
    fleet = "Commercial fishery", source_type = "reconstructed_source_input",
    transformation = paste(
      "For each year, divide each displayed Table 9 number-at-age value by the sum across ages 2-12.",
      "The source table is rounded to thousands of fish; zero cells are retained as zero and the report does not specify how zero cells were treated in the model's log-scale composition residuals."
    ),
    notes = "Reconstructed annual composition used by the SCA composition likelihood; age 12 represents 12+."),
  input_rows(full_id, "index", "numbers_at_age", "numbers", survey_long$value,
    "thousand fish", survey_age_ref, year = survey_long$year, age = survey_long$age,
    survey = "September RV survey, offshore strata 415-439", sampling_time = 0.71,
    source_type = "official_table",
    notes = paste(
      "Reported trawlable abundance-at-age; age 12 is the 12+ group.",
      "The model uses the aggregate survey index and age proportions; these abundance rows are retained as source data and are not a separate age-specific likelihood."
    )),
  input_rows(full_id, "index", "proportion_at_age", "proportion_numbers", survey_long$proportion,
    "proportion", survey_age_ref, year = survey_long$year, age = survey_long$age,
    survey = "September RV survey, offshore strata 415-439", sampling_time = 0.71,
    source_type = "reconstructed_source_input",
    transformation = "For each year, divide each displayed Table 10 trawlable abundance-at-age value by the sum across ages 2-12.",
    notes = "Reconstructed annual survey composition used by the SCA composition likelihood; age 12 represents 12+."),
  input_rows(full_id, "index", "total_biomass", "biomass", rv_biomass_kg_per_tow,
    "kg/tow", survey_biomass_ref, year = years,
    survey = "September RV survey, offshore strata 415-439", sampling_time = 0.71,
    source_type = "digitized",
    transformation = paste(
      "Digitized the black solid offshore series in the lower panel from the figure image.",
      "Calibrated the vertical axis from 0 to 80 kg/tow and rounded to 0.1 kg/tow; confidence intervals were not digitized."
    ),
    notes = paste(
      "Digitized survey biomass index in the units printed on Figure 18 (kg/tow).",
      "The methods list the model input as tonnes while the figure axis and caption report kg/tow; the native model scale is unresolved without its input files."
    )),
  input_rows(full_id, "weight", "weight_at_age", "kg_per_fish", weight_long$value,
    "kg/fish", weight_ref, year = weight_long$year, age = weight_long$age,
    survey = "September RV survey", sampling_time = 0.71,
    notes = "Table 13 numerically reports the RV-survey weight-at-age surface; age 12 represents 12+. The fishery weight-at-age surface mentioned in the methods was not found in a numerical table or machine-readable file."),
  input_rows(full_id, "maturity", "maturity_at_age", "proportion", maturity_long$value,
    "proportion", maturity_ref, year = maturity_long$year, age = maturity_long$age,
    survey = "September RV survey",
    notes = "Reported annual mature proportion-at-age used in calculating SSB; age 12 represents 12+.")
))

assumption_ref <- paste0(report_url, "; Methods and Results, PDF pp. 24-29 (report pp. 14-19)")
assumptions <- do.call(rbind, list(
  assumption_rows(full_id, "population", "model_years", "1973-2016",
    assumption_ref, "44 annual years; one combined-sex population; ages 2-12+, with age 12 as the plus group."),
  assumption_rows(full_id, "population", "sex_structure", "combined sex",
    assumption_ref),
  assumption_rows(full_id, "catch", "catch_likelihood", "annual total landings plus number proportions-at-age",
    assumption_ref, "The report describes log-scale catch uncertainty with SD 0.1 except 1984, which uses SD 2."),
  assumption_rows(full_id, "index", "survey_likelihood", "aggregate RV biomass index plus number proportions-at-age",
    assumption_ref, "The aggregate index scale is unresolved: the methods call it tonnes, while Figure 18 reports kg/tow."),
  assumption_rows(full_id, "index", "survey_timing", "0.71",
    assumption_ref, "September RV survey fraction of the annual time step.", survey = "September RV survey, offshore strata 415-439"),
  assumption_rows(full_id, "M", "process", "estimated in five-year blocks from 1973; final block is 2013-2016",
    assumption_ref, "Two age blocks (2-4, 5+) or three age blocks (2-4, 5-7, 8+) were compared; M is not fixed."),
  assumption_rows(full_id, "F", "selectivity", "logistic age selectivity; time blocks varied among model variants",
    assumption_ref, "Fishery blocks may be 1973-1985, 1986-2005, and 2006-2016; RV blocks may be 1973-1984 and 1985-2016."),
  assumption_rows(full_id, "recruitment", "age_2_process", "AR(1) with fixed logit(phi) = -4",
    assumption_ref, "The report describes this as approximately a random walk."),
  assumption_rows(full_id, "index", "catchability_prior", "log(q_RV) ~ Normal(-1.7, 0.7)",
    assumption_ref, "The reported Model 2 estimate is 0.232; the report states q is weakly inferred from the data.", survey = "September RV survey, offshore strata 415-439"),
  assumption_rows(full_id, "biology", "fishery_weight_at_age", "unresolved",
    weight_ref, "The methods say annual survey and fishery weights-at-age were inputs, but the numeric Table 13 is explicitly titled and presented as RV-survey weights. No fishery weights were recovered."),
  assumption_rows(full_id, "model", "variant_interpretation", "Models 1-7 compared; main inference figures use Model 2",
    paste0(report_url, "; Table 11, PDF p. 48 and Results, PDF pp. 27-29"),
    "Table 11 reports the lowest AIC for Model 7, while the main population, mortality, and recruitment results are presented for Model 2. Stored outputs are explicitly labelled Model 2; the report does not make this distinction a single selected-model record."),
  assumption_rows(update_id, "index", "indicator_definition", "Three-year mean of September RV survey biomass for fish >=25 cm, assigned to 2024",
    paste0(update_url, "; Table 1 and p. 5"),
    "This is a commercial-size survey indicator, not SSB or an output of a new population-model fit.", survey = "Southern Gulf September RV survey")
))

main_outputs <- output_rows(
  full_id, "biomass", "SSB", 76270, "tonnes",
  paste0(report_url, "; Results, PDF p. 29 (report p. 19)"), year = 2016,
  source_type = "official_document",
  notes = "Model 2 inference output stated in prose; rounded to the reported 10 tonnes. No numeric uncertainty was provided in the text."
)
main_outputs <- rbind(main_outputs, output_rows(
  full_id, "population", "total_abundance", 3.05, "billion fish",
  paste0(report_url, "; Results, PDF p. 28 (report p. 18)"), year = 2016,
  source_type = "official_document",
  notes = "Model 2 estimate for ages 2-12+; reported as 3.05 billion fish. No numeric uncertainty was provided in the text."
), output_rows(
  full_id, "recruitment", "recruitment", c(1.8, 0.7), "billion fish",
  paste0(report_url, "; Results, PDF p. 29 (report p. 19)"), year = 2016, age = c(2L, 3L),
  source_type = "official_document",
  notes = c(
    "Model 2 age-2 recruitment estimate; report prose rounds to 1.8 billion fish.",
    "Model 2 age-3 recruitment estimate; report prose rounds to 0.7 billion fish."
  )
), output_rows(
  full_id, "catchability", "q", 0.232, "ratio",
  paste0(report_url, "; Results, PDF p. 27 (report p. 17)"), year = NA_integer_,
  survey = "September RV survey, offshore strata 415-439", source_type = "official_document",
  notes = "Model 2 estimate; the report describes q as weakly inferred."
))

update_outputs <- output_rows(
  update_id, "index", "relative_biomass_index", 1.38, "kg/tow",
  paste0(update_url, "; Results, PDF p. 5"), year = 2024,
  survey = "Southern Gulf September RV survey", source_type = "official_document",
  notes = "Reported three-year moving average of the survey biomass indicator for commercial-size fish (>=25 cm), assigned to 2024; no numeric uncertainty for this mean was reported."
)
update_outputs <- rbind(update_outputs, output_rows(
  update_id, "index", "LRP", 3.82, "kg/tow",
  paste0(update_url, "; Table 1, PDF p. 3"), year = NA_integer_,
  survey = "Southern Gulf September RV survey", source_type = "official_table",
  notes = "Scaled LRP for the >=25 cm survey biomass indicator; not a population-scale SSB reference point."
), output_rows(
  update_id, "index", "USR", 7.64, "kg/tow",
  paste0(update_url, "; Table 1, PDF p. 3"), year = NA_integer_,
  survey = "Southern Gulf September RV survey", source_type = "official_table",
  notes = "Scaled USR for the >=25 cm survey biomass indicator; not a population-scale SSB reference point."
))
outputs <- rbind(main_outputs, update_outputs)

append_pacific_case(stocks, assessments, assumptions, inputs, outputs)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_id <- "DFO:Gulf:Winter Flounder - NAFO 4T"
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || sum(candidates$candidate_id == candidate_id) != 1L) {
  cli::cli_abort("The DFO NAFO 4T winter flounder candidate row is missing or duplicated.")
}
candidates$import_status[i] <- "partial"
candidates$catch_age_evidence[i] <- paste(
  "Table 9 reports commercial catch numbers-at-age (thousands of fish) for ages 2-12+, 1973-2016.",
  "The 2016 estimates are preliminary; the assessment likelihood uses annual number proportions derived from these counts plus total landings."
)
candidates$survey_age_evidence[i] <- paste(
  "Table 10 reports trawlable survey abundance-at-age for ages 2-12+, 1973-2016.",
  "Figure 18 also provides a digitized aggregate weight-per-tow index; the model-native scale is unresolved."
)
candidates$weights_evidence[i] <- paste(
  "Table 13 provides the RV survey weights-at-age in kg/fish for 1973-2016.",
  "The numeric fishery weights-at-age mentioned in the methods were not found."
)
candidates$maturity_evidence[i] <- "Table 12 reports annual mature proportions-at-age for ages 2-12+, 1973-2016."
candidates$mortality_evidence[i] <- "The SCA estimates M in five-year blocks; two- and three-age-block variants were compared."
candidates$timing_evidence[i] <- "September RV survey timing is 0.71 of the annual step."
candidates$output_evidence[i] <- paste(
  "The report gives 2016 Model 2 SSB, total abundance, and age-2/age-3 recruitment in prose.",
  "Annual N/F/M and SSB series are plotted but not tabulated; the 2025 update reports a separate 2024 survey indicator."
)
candidates$review_date[i] <- "2026-11-03"
candidates$decision_reason[i] <- paste(
  "Partial import completed from the latest detailed full assessment located (2017 SCA, data through 2016) and the 2025 interim indicator update.",
  "Inputs remain partial because fishery weights-at-age and the model-native RV index scale are unresolved; outputs lack numerical annual state surfaces and uncertainty."
)
candidates$notes[i] <- paste(
  "One combined-sex DFO population for NAFO Division 4T.",
  "The 2025/010 report states that a full assessment was planned for 2026, but no later full assessment was located as of 2026-11-03."
)
source(file.path(root, "scripts", "database", "candidate_register_io.R"))
replace_candidate_register_row(candidate_path, i, candidates[i, , drop = FALSE], candidate_id)

unit_path <- file.path(root, "discovery", "inventory_units.csv")
units <- utils::read.csv(unit_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
u <- match("candidate:dfo_sgsl_winter_flounder_4t", units$unit_key)
if (is.na(u)) cli::cli_abort("The DFO winter flounder inventory unit is missing.")
units$import_status[u] <- "partial"
replace_inventory_unit_row <- function(path, row_index, row, unit_key) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  if (length(record_index) != 1L || is.na(record_index) ||
      record_index < 2L || record_index > length(bounds$start)) {
    cli::cli_abort("The winter flounder inventory row is out of range.")
  }
  old_record <- rawToChar(bytes[bounds$start[record_index]:bounds$end[record_index]])
  if (!startsWith(old_record, paste0('"', unit_key, '"'))) {
    cli::cli_abort("The winter flounder inventory row identity changed.")
  }

  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L))
    replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L))
    replacement <- replacement[-length(replacement)]

  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  has_carriage_return <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_carriage_return <- TRUE
    next_byte <- next_byte + 1L
  }
  line_ending <- raw(0L)
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    line_ending <- c(if (has_carriage_return) as.raw(13L) else raw(0L), as.raw(10L))
    last <- next_byte
    replacement <- c(replacement, line_ending)
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)

  updated <- tryCatch(read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE), error = function(e) NULL)
  valid <- !is.null(updated) && nrow(updated) == length(bounds$start) - 1L &&
    identical(as.character(updated$unit_key[as.integer(row_index)]), unit_key) &&
    identical(as.character(updated$import_status[as.integer(row_index)]), "partial")
  if (!valid) {
    writeBin(original, path)
    cli::cli_abort("Updated winter flounder inventory unit failed validation.")
  }
}
replace_inventory_unit_row(unit_path, u, units[u, , drop = FALSE],
  "candidate:dfo_sgsl_winter_flounder_4t")

cat("Imported partial DFO NAFO 4T winter flounder source records.\n")
