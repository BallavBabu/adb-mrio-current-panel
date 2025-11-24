# Harmonized ADB Multi-Regional Input–Output (MRIO) Panel: Current Prices (2000–2024)
[![Release](https://img.shields.io/github/v/release/BallavBabu/adb-mrio-current-panel)](https://github.com/BallavBabu/adb-mrio-current-panel/releases)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.17694852.svg)](https://doi.org/10.5281/zenodo.17694852)

This repository provides the **R source code and documentation** for constructing and using the dataset:

> Bhusal, L. B. (2025). *Harmonized ADB Multi-Regional Input–Output (MRIO) Panel: Current Prices (2000–2024)* [Data set]. Zenodo. https://doi.org/10.5281/zenodo.17694852

The compiled panel itself is published on Zenodo as an `.rds` file. This repository focuses on:

- the **data construction scripts** used to build the panel from the original ADB MRIO Excel files,  
- **validation checks** to confirm internal consistency,  
- **documentation of the data structure** of the R object (`mrio_panel`), and  
- **example workflows** for MRIO and GVC analysis in current prices.

---

## 1. Data Sources

### 1.1 Original ADB MRIO data

The panel is derived from the official ADB MRIO database in current prices:

- ADB MRIO portal (current): <https://kidb.adb.org/globalization/current>

Users should always cite the original ADB source when using this data in research.

### 1.2 Harmonized panel (Zenodo)

The harmonized current-price panel is distributed via Zenodo:

- Bhusal, L. B. (2025). *Harmonized ADB Multi-Regional Input–Output (MRIO) Panel: Current Prices (2000–2024)* [Data set]. Zenodo. https://doi.org/10.5281/zenodo.17694852

This repository assumes that the `.rds` file from Zenodo is available locally.

---

## 2. Panel Overview

- **Years:** 2000, 2007–2024 (19 benchmark years)  
- **Economies:** 62 economies + Rest of the World (total 63)  
- **Sectors:** 35 sectors per economy (ADB MRIO classification)  
- **System size:** 2,205 sectoral units per year (63 × 35)  
- **Valuation:** Current prices (nominal USD, as reported in ADB MRIO)  
- **Format:** R serialized object (`mrio_current_value_panel_2000_2024.rds`)

Each yearly object includes:

- global intermediate use matrix (`Z`),  
- final demand matrix (`Y`),  
- gross output vector (`X`),  
- value-added vector (`VA_raw`),  
- technical coefficients (`A`, `A_D`, `A_F`),  
- Leontief inverses (`B`, `L`),  
- final demand decompositions (`Y_R`, `Y_D_R`, `Y_F_R`, `Y_country`, `Y_D`, `Y_F`),  
- gross exports by sector (`E_s`).

A detailed description of the data structure is provided in [`data-structure.md`](data-structure.md).

---

## 3. Repository Contents

- `scripts/01_build_panel_current.R`  
  Code to read ADB MRIO Excel files (63-economy configuration) and build the current-price panel object.

- `scripts/02_checks_current.R`  
  Consistency checks, including:
  - `X ≈ B %*% Y_R` (global and by country),  
  - row identity `X_i ≈ sum_j Z_ij + Y_R_i`,  
  - reconstruction check `Z ≈ A %*% X̂`.

- `scripts/03_examples_current.R`  
  Example MRIO workflows using the panel:
  - global output from final demand,  
  - value-added content of final demand using `v̂ %*% B %*% f`,  
  - country-level value-added supported by final demand.

- `data-structure.md`  
  Description of the `mrio_panel` object layout, including `metadata` and yearly components.

---

## 4. Getting Started

### 4.1 Requirements

- R (version 4.x or later recommended)  
- Packages:
  - `readxl`
  - `Matrix`
  - `dplyr` (optional, for inspection)
  - `stringr` (optional, for file handling)

Install required packages:

```r
install.packages(c("readxl", "Matrix", "dplyr", "stringr"))


### 4.2 Loading the panel (from Zenodo)

After downloading the `.rds` file from Zenodo:

```r
panel_path <- "mrio_current_value_panel_2000_2024.rds"
mrio_panel <- readRDS(panel_path)

# Example: access year 2024
y2024 <- mrio_panel$years[["2024"]]
str(y2024, max.level = 1)
```

---

## 5. Example Usage

### 5.1 Global output from total final demand

```r
y2024  <- mrio_panel$years[["2024"]]
B_2024 <- y2024$multipliers$B
f_2024 <- y2024$final_demand$Y_R

x_2024_calc <- as.numeric(B_2024 %*% f_2024)
X_2024      <- y2024$core_matrices$X

max(abs(x_2024_calc - X_2024))
```

### 5.2 Value-added content of final demand

```r
VA_coeff_2024 <- y2024$coefficients$VA_coeff
VA_diag_2024  <- y2024$coefficients$VA_diag

# Total value added embodied in global final demand
VA_global_2024 <- as.numeric(VA_coeff_2024 %*% B_2024 %*% f_2024)

# Value added by sector from gross output
VA_from_X_2024 <- as.numeric(VA_coeff_2024 %*% X_2024)
```

### 5.3 Country-level example

```r
Y_country_2024 <- y2024$final_demand$Y_country

# Choose a country index (e.g. 60)
g <- 60L
f_2024_g <- Y_country_2024[, g]

# Output and value added supported by this country's final demand
x_2024_g  <- as.numeric(B_2024 %*% f_2024_g)
VA_2024_g <- as.numeric(VA_coeff_2024 %*% B_2024 %*% f_2024_g)
```

---

## 6. Citation

If you use this panel in your work, please cite:

- **Dataset**  
  Bhusal, L. B. (2025). *Harmonized ADB Multi-Regional Input–Output (MRIO) Panel: Current Prices (2000–2024)* [Data set]. Zenodo. https://doi.org/10.5281/zenodo.17694852

- **Original data source**  
  Asian Development Bank (ADB). 
  MRIO portal: <https://kidb.adb.org/globalization/current>

## 7. Licensing

Code and documentation (this repository): MIT License (see `LICENSE`).
