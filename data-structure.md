# Data Structure: MRIO Current-Price Panel (2000–2024)

This document describes the structure of the R object
`mrio_panel` used in the Zenodo dataset:

> Bhusal, L. B. (2025). *Harmonized ADB Multi-Regional Input–Output (MRIO) Panel: Current Prices (2000–2024)* [Data set]. Zenodo. https://doi.org/10.5281/zenodo.17694852

---

## 1. Top-level object

The `.rds` file contains a single list:

- `mrio_panel$metadata`
- `mrio_panel$years`

### 1.1 `metadata`

Typical fields:

- `creation_date`  
- `data_source`  
- `currency`  
- `price_type`  
- `total_years`  
- `successful_years` (vector of years, e.g. 2000, 2007–2024)  
- `num_countries` = 63  
- `num_sectors` = 35  
- `total_sectors` = 2205  
- `country_codes`, `country_names`, `country_numbers`  
- `sector_names`

---

## 2. Yearly objects

Each element of `mrio_panel$years` is named by year, e.g.:

```r
y <- mrio_panel$years[["2024"]]
```

The structure is:

- `dimensions`
- `core_matrices`
- `coefficients`
- `multipliers`
- `final_demand`
- `trade`

### 2.1 `dimensions`

- `num_countries` = 63  
- `num_sectors`   = 35  
- `total_sectors` = 2205  

### 2.2 `core_matrices`

- `Z` . Intermediate use matrix (2205 × 2205)  
- `X` . Gross output vector (2205 × 1)  
- `Y` . Final demand matrix (2205 × 315, 5 ADB final demand categories × 63 economies)  
- `VA_raw` . Value added vector (2205 × 1)  

### 2.3 `coefficients`

- `A` . Total technical coefficient matrix (2205 × 2205)  
- `A_D` . Domestic technical coefficient matrix (block-diagonal, by country)  
- `A_F` . Foreign technical coefficient matrix (`A - A_D`)  
- `VA_coeff` . Value-added coefficients (1 × 2205)  
- `VA_diag` . Diagonal matrix of value-added coefficients (2205 × 2205)  

### 2.4 `multipliers`

- `B` . Global Leontief inverse, `(I - A)^(-1)`  
- `L` . Domestic Leontief inverse, `(I - A_D)^(-1)`  

### 2.5 `final_demand`

- `Y_R` . Total final demand by sector (2205 × 1)  
- `Y_D_R` . Domestic final demand by sector (2205 × 1)  
- `Y_F_R` . Export final demand by sector (2205 × 1)  
- `Y_country` . Final demand by absorbing economy (2205 × 63)  
- `Y_D` . Domestic final demand matrix (block-diagonal, 2205 × 2205)  
- `Y_F` . Foreign final demand matrix (2205 × 2205)  

### 2.6 `trade`

- `E_s` . Gross exports by sector (2205 × 1)

This layout is stable across all years in the panel.
