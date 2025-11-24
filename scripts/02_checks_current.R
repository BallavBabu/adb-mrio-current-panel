# 02_checks_current.R
# Consistency checks for the current-price MRIO panel

library(Matrix)

PANEL_RDS <- "mrio_current_value_panel_2000_2024.rds"

mrio_panel <- readRDS(PANEL_RDS)

years_available <- sort(as.integer(names(mrio_panel$years)))
cat("Years in panel:", paste(years_available, collapse = ", "), "\n")

# Choose a year to test
year_test <- years_available[1]
cat("Running checks for year", year_test, "\n")

y <- mrio_panel$years[[as.character(year_test)]]

Z  <- y$core_matrices$Z
X  <- y$core_matrices$X
Y  <- y$core_matrices$Y
Y_R <- y$final_demand$Y_R

A  <- y$coefficients$A
B  <- y$multipliers$B

num_countries <- y$dimensions$num_countries
num_sectors   <- y$dimensions$num_sectors
total_sectors <- y$dimensions$total_sectors

cat("Dimensions:\n")
cat("  Z:", paste(dim(Z), collapse = " × "), "\n")
cat("  X:", length(X), "\n")
cat("  Y:", paste(dim(Y), collapse = " × "), "\n")
cat("  B:", paste(dim(B), collapse = " × "), "\n\n")

# -------------------------------------------------
# TEST 1: Leontief identity X ≈ B %*% Y_R
# -------------------------------------------------

X_hat <- as.numeric(B %*% Y_R)
diff_leontief <- X_hat - X

max_abs_diff_leontief <- max(abs(diff_leontief))
rel_diff_leontief     <- max_abs_diff_leontief / max(abs(X))

cat("TEST 1: X ≈ B %*% Y_R (global)\n")
cat("  max |X_hat - X| =", max_abs_diff_leontief, "\n")
cat("  max relative diff =", rel_diff_leontief, "\n\n")

# -------------------------------------------------
# TEST 2: Row identity X_i ≈ sum_j Z_ij + Y_R_i
# -------------------------------------------------

row_sums_Z <- rowSums(Z)
X_from_rows <- row_sums_Z + Y_R

diff_row <- X_from_rows - X
max_abs_diff_row <- max(abs(diff_row))
rel_diff_row     <- max_abs_diff_row / max(abs(X))

cat("TEST 2: X_i ≈ sum_j Z_ij + Y_R_i (row identity)\n")
cat("  max |(rowSums(Z) + Y_R) - X| =", max_abs_diff_row, "\n")
cat("  max relative diff =", rel_diff_row, "\n\n")

# -------------------------------------------------
# TEST 3: Z ≈ A %*% diag(X)
# -------------------------------------------------

X_diag <- Diagonal(x = X)
Z_hat  <- A %*% X_diag

diff_Z  <- Z_hat - Z
max_abs_diff_Z <- max(abs(diff_Z))
rel_diff_Z     <- max_abs_diff_Z / max(abs(Z))

cat("TEST 3: Z ≈ A %*% diag(X)\n")
cat("  max |Z_hat - Z| =", max_abs_diff_Z, "\n")
cat("  max relative diff =", rel_diff_Z, "\n\n")

# -------------------------------------------------
# TEST 4: Country-level examples
# -------------------------------------------------

# Choose an example country index
g <- num_countries  # last country as example
start_idx <- (g - 1L) * num_sectors + 1L
end_idx   <- g * num_sectors
idx_g     <- start_idx:end_idx

cat("Country index:", g, "block rows/cols:", start_idx, "to", end_idx, "\n\n")

X_g     <- X[idx_g]
Y_R_g   <- Y_R[idx_g]
row_Z_g <- row_sums_Z[idx_g]

# 4a. Leontief identity restricted to block g
X_hat_g <- X_hat[idx_g]
diff_g_leontief <- X_hat_g - X_g
max_abs_diff_g_leont <- max(abs(diff_g_leontief))
rel_diff_g_leont     <- max_abs_diff_g_leont / max(abs(X_g))

cat("TEST 4a: Country", g, "Leontief block X ≈ B %*% Y_R\n")
cat("  max |X_hat - X| =", max_abs_diff_g_leont, "\n")
cat("  max relative diff =", rel_diff_g_leont, "\n\n")

# 4b. Row identity restricted to block g
X_from_rows_g <- row_Z_g + Y_R_g
diff_g_row <- X_from_rows_g - X_g
max_abs_diff_g_row <- max(abs(diff_g_row))
rel_diff_g_row     <- max_abs_diff_g_row / max(abs(X_g))

cat("TEST 4b: Country", g, "row identity X_i ≈ sum_j Z_ij + Y_R_i\n")
cat("  max |(rowSums(Z_g) + Y_R_g) - X_g| =", max_abs_diff_g_row, "\n")
cat("  max relative diff =", rel_diff_g_row, "\n\n")

# -------------------------------------------------
# TEST 5: Value-added consistency
# -------------------------------------------------

VA_raw   <- y$core_matrices$VA_raw
VA_coeff <- y$coefficients$VA_coeff

VA_from_X <- as.numeric(VA_coeff %*% X)
max_abs_diff_VA <- max(abs(VA_from_X - VA_raw))
rel_diff_VA     <- max_abs_diff_VA / max(abs(VA_raw))

cat("TEST 5: VA_raw ≈ VA_coeff %*% X\n")
cat("  max |VA_from_X - VA_raw| =", max_abs_diff_VA, "\n")
cat("  max relative diff =", rel_diff_VA, "\n\n")
