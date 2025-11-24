# 03_examples_current.R
# Example MRIO and GVC analysis workflows using the current-price panel

library(Matrix)

PANEL_RDS <- "mrio_current_value_panel_2000_2024.rds"

mrio_panel <- readRDS(PANEL_RDS)

# Choose a reference year
year_ref <- 2024
y <- mrio_panel$years[[as.character(year_ref)]]

B        <- y$multipliers$B
L        <- y$multipliers$L
Y_R      <- y$final_demand$Y_R
Y_country <- y$final_demand$Y_country
X        <- y$core_matrices$X
VA_raw   <- y$core_matrices$VA_raw
VA_coeff <- y$coefficients$VA_coeff
VA_diag  <- y$coefficients$VA_diag

num_countries <- y$dimensions$num_countries
num_sectors   <- y$dimensions$num_sectors

cat("Year:", year_ref, "\n")
cat("num_countries:", num_countries, "\n")
cat("num_sectors:  ", num_sectors, "\n")
cat("dim(B):", paste(dim(B), collapse = " × "), "\n")
cat("dim(L):", paste(dim(L), collapse = " × "), "\n\n")

# -------------------------------------------------
# Example 1: Global output from total final demand
# -------------------------------------------------

X_hat_global <- as.numeric(B %*% Y_R)
cat("Example 1: Global output from total final demand\n")
cat("  max |B %*% Y_R - X| =", max(abs(X_hat_global - X)), "\n\n")

# -------------------------------------------------
# Example 2: Total value added from global final demand
# -------------------------------------------------

VA_from_final_global <- as.numeric(VA_coeff %*% B %*% Y_R)
VA_total_reported    <- sum(VA_raw)

cat("Example 2: Total value added from global final demand\n")
cat("  VA_from_final_global:", VA_from_final_global, "\n")
cat("  sum(VA_raw):         ", VA_total_reported, "\n\n")

# -------------------------------------------------
# Example 3: Country-level value added supported by final demand
# -------------------------------------------------

# Choose a country index (e.g. 60)
g <- 60L

f_g <- Y_country[, g]

x_g  <- as.numeric(B %*% f_g)
VA_g <- as.numeric(VA_coeff %*% B %*% f_g)

VA_g_sector  <- as.numeric(VA_diag %*% x_g)
VA_g_total   <- sum(VA_g_sector)

cat("Example 3: Country", g, "value added supported by its final demand\n")
cat("  total VA (via v %*% B %*% f_g):", VA_g, "\n")
cat("  total VA (via v_diag %*% x_g):", VA_g_total, "\n\n")

# -------------------------------------------------
# Example 4: Simple sector aggregates by country
# -------------------------------------------------

# Aggregate gross output by country
X_country_sum <- sapply(seq_len(num_countries), function(g) {
  start_idx <- (g - 1L) * num_sectors + 1L
  end_idx   <- g * num_sectors
  sum(X[start_idx:end_idx])
})

cat("Example 4: First 10 country-level gross output sums:\n")
print(round(X_country_sum[1:10], 2))
