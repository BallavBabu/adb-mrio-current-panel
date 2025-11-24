# 01_build_panel_current.R
# Construct harmonized current-price ADB MRIO panel (2000–2024, 63 economies × 35 sectors)
# Panel output: mrio_current_value_panel_2000_2024.rds

library(readxl)
library(Matrix)
library(stringr)

# -------------------------------------------------------------------
# 1. User paths (edit as needed)
# -------------------------------------------------------------------

DATA_DIR   <- "~/Downloads"  # directory containing ADB MRIO Excel files
OUTPUT_RDS <- "mrio_current_value_panel_2000_2024.rds"

# -------------------------------------------------------------------
# 2. Helper: list Excel files in DATA_DIR
# -------------------------------------------------------------------

excel_files <- list.files(
  DATA_DIR,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

cat("Detected Excel files:\n")
print(basename(excel_files))

# -------------------------------------------------------------------
# 3. Detect ADB MRIO sheets and year mapping
# -------------------------------------------------------------------

sheet_map <- do.call(
  rbind,
  lapply(excel_files, function(fp) {
    ss <- tryCatch(
      excel_sheets(fp),
      error = function(e) character(0)
    )
    if (length(ss) == 0L) return(NULL)
    mrio_sheets <- grep("^ADB MRIO [0-9]{4}$", ss, value = TRUE)
    if (length(mrio_sheets) == 0L) return(NULL)

    data.frame(
      file  = fp,
      sheet = mrio_sheets,
      year  = as.integer(sub("ADB MRIO ", "", mrio_sheets)),
      stringsAsFactors = FALSE
    )
  })
)

sheet_map <- sheet_map[order(sheet_map$year), ]
cat("\nDetected year–sheet mapping:\n")
print(sheet_map)

years_available <- sort(unique(sheet_map$year))
cat("\nYears available:", paste(years_available, collapse = ", "), "\n")

# -------------------------------------------------------------------
# 4. Read legend (country and sector information) from 2000 file
# -------------------------------------------------------------------

legend_row <- sheet_map[sheet_map$year == 2000, ][1, ]
legend_file  <- legend_row$file
legend_sheet <- "Legend"

cat("\nReading legend from:\n  file  =", basename(legend_file),
    "\n  sheet =", legend_sheet, "\n")

country_data <- read_excel(
  path      = legend_file,
  sheet     = legend_sheet,
  range     = "A2:C64",
  col_names = c("Country_Code", "Country_Name", "Country_Number")
)

country_codes   <- country_data$Country_Code
country_names   <- country_data$Country_Name
country_numbers <- country_data$Country_Number

num_countries <- length(country_names)  # should be 63
num_sectors   <- 35L
total_sectors <- num_countries * num_sectors

cat("\nLegend summary:\n")
cat("  num_countries:", num_countries, "\n")
cat("  num_sectors:  ", num_sectors, "\n")
cat("  total_sectors:", total_sectors, "\n")

sector_names <- read_excel(
  path      = legend_file,
  sheet     = legend_row$sheet,
  range     = "B8:B42",
  col_names = FALSE
)[[1]]

# -------------------------------------------------------------------
# 5. Function to build a single-year MRIO object (63 × 35, current prices)
# -------------------------------------------------------------------

build_mrio_year_63_current <- function(file_path, sheet_name,
                                       num_countries, num_sectors) {

  total_sectors <- num_countries * num_sectors

  # 5.1 Intermediate use matrix Z and gross output X
  Z <- as.matrix(read_excel(
    path      = file_path,
    sheet     = sheet_name,
    range     = "E8:CFY2212",
    col_names = FALSE
  ))

  if (!all(dim(Z) == c(total_sectors, total_sectors))) {
    stop("Z has unexpected dimensions for file: ", basename(file_path))
  }

  X_raw <- read_excel(
    path      = file_path,
    sheet     = sheet_name,
    range     = "CSC8:CSC2212",
    col_names = FALSE
  )

  X <- as.numeric(unlist(X_raw))
  if (length(X) != total_sectors) {
    stop("X has unexpected length for file: ", basename(file_path))
  }

  X[X == 0] <- 1e-10
  X_diag    <- Diagonal(x = X)

  # 5.2 Technical coefficient matrix A
  A <- Z %*% solve(X_diag)

  # 5.3 Final demand matrix Y (5 categories × 63 economies = 315 columns)
  Y <- as.matrix(read_excel(
    path      = file_path,
    sheet     = sheet_name,
    range     = "CFZ8:DJG2212",
    col_names = FALSE
  ))

  if (!all(dim(Y) == c(total_sectors, num_countries * 5L))) {
    stop("Y has unexpected dimensions for file: ", basename(file_path))
  }

  Y_R <- rowSums(Y)

  # Split into domestic (Y_D) and foreign (Y_F)
  Y_D_blocks <- lapply(seq_len(num_countries), function(g) {
    start_row <- (g - 1L) * num_sectors + 1L
    end_row   <- g * num_sectors
    start_col <- (g - 1L) * 5L + 1L
    end_col   <- g * 5L
    Y[start_row:end_row, start_col:end_col]
  })

  Y_D <- bdiag(Y_D_blocks)
  Y_D_R <- Matrix::rowSums(Y_D)

  Y_F   <- Y - as.matrix(Y_D)
  Y_F_R <- rowSums(Y_F)

  # Final demand by absorbing economy
  Y_country <- matrix(0, nrow = total_sectors, ncol = num_countries)
  for (g in seq_len(num_countries)) {
    cols <- ((g - 1L) * 5L + 1L):(g * 5L)
    Y_country[, g] <- rowSums(Y[, cols])
  }

  # 5.4 Domestic and foreign technical coefficients
  A_D_blocks <- lapply(seq_len(num_countries), function(g) {
    start_idx <- (g - 1L) * num_sectors + 1L
    end_idx   <- g * num_sectors
    A[start_idx:end_idx, start_idx:end_idx]
  })
  A_D <- bdiag(A_D_blocks)
  A_F <- A - A_D

  # 5.5 Identity matrix and Leontief inverses
  I_mat <- Diagonal(n = nrow(A))
  B     <- solve(I_mat - A)
  L     <- solve(I_mat - A_D)

  # 5.6 Value-added (VA) block: directly below Z
  VA_matrix <- read_excel(
    path      = file_path,
    sheet     = sheet_name,
    range     = "E2214:CFY2219",
    col_names = FALSE
  )

  VA_raw <- colSums(as.matrix(VA_matrix))
  VA_coeff <- VA_raw %*% solve(X_diag)
  VA_diag  <- Diagonal(x = as.numeric(VA_coeff))

  # 5.7 Gross exports by sector
  E_s <- as.matrix(A_F %*% X) + rowSums(Y_F)

  list(
    dimensions = list(
      num_countries = num_countries,
      num_sectors   = num_sectors,
      total_sectors = total_sectors
    ),
    core_matrices = list(
      Z      = Z,
      X      = X,
      Y      = Y,
      VA_raw = VA_raw
    ),
    coefficients = list(
      A        = A,
      A_D      = A_D,
      A_F      = A_F,
      VA_coeff = VA_coeff,
      VA_diag  = VA_diag
    ),
    multipliers = list(
      B = B,
      L = L
    ),
    final_demand = list(
      Y_R       = Y_R,
      Y_D_R     = Y_D_R,
      Y_F_R     = Y_F_R,
      Y_country = Y_country,
      Y_D       = Y_D,
      Y_F       = Y_F
    ),
    trade = list(
      E_s = E_s
    )
  )
}

# -------------------------------------------------------------------
# 6. Build panel across all years
# -------------------------------------------------------------------

years_list <- list()

for (yr in years_available) {
  row <- sheet_map[sheet_map$year == yr, ][1, ]
  file_path  <- row$file
  sheet_name <- row$sheet

  cat("\nBuilding MRIO object for year", yr, "from:\n")
  cat("  file  =", basename(file_path), "\n")
  cat("  sheet =", sheet_name, "\n")

  years_list[[as.character(yr)]] <- build_mrio_year_63_current(
    file_path     = file_path,
    sheet_name    = sheet_name,
    num_countries = num_countries,
    num_sectors   = num_sectors
  )
}

# -------------------------------------------------------------------
# 7. Assemble mrio_panel object and save
# -------------------------------------------------------------------

metadata <- list(
  creation_date   = Sys.Date(),
  data_source     = "ADB MRIO database (current prices)",
  currency        = "USD",
  price_type      = "current",
  total_years     = length(years_available),
  successful_years = years_available,
  num_countries   = num_countries,
  num_sectors     = num_sectors,
  total_sectors   = total_sectors,
  country_codes   = country_codes,
  country_names   = country_names,
  country_numbers = country_numbers,
  sector_names    = sector_names
)

mrio_panel <- list(
  metadata = metadata,
  years    = years_list
)

saveRDS(mrio_panel, file = OUTPUT_RDS)
cat("\nSaved current-price MRIO panel to:\n", OUTPUT_RDS, "\n")
