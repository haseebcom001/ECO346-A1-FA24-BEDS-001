# 01_prepare.R
# Builds the variant-1 sample (Punjab urban earners aged 15-64), computes the
# Question 2 numbers and the Question 3 band table. Run from the project root
# (open ECO346-A1-FA24-BED-001.Rproj in RStudio first).

library(readr)
library(dplyr)

dir.create("outputs", showWarnings = FALSE)

# ---- 1. Read the local copies of the data --------------------------------
person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE) |>
  select(hhid, hhweight, prov_code, urban_rural)

# ---- 2. Attach weight, province and area by hhid -------------------------
joined <- left_join(person, hh, by = "hhid")
stopifnot(!any(is.na(joined$hhweight)))   # every person found a household

# ---- 3. Variant 1 = Punjab (prov_code 2), urban (urban_rural 2) -----------
earners <- joined |>
  filter(prov_code == 2, urban_rural == 2,
         age >= 15, age <= 64,
         !is.na(earn_annual), earn_annual > 0) |>
  mutate(band_start = 15 + 5 * ((age - 15) %/% 5),
         band       = paste0(band_start, "-", band_start + 4),
         midpoint   = band_start + 2)

write_csv(earners, "outputs/analysis_data.csv")

# ---- 4. Weighted quantile, exactly as defined in the brief ----------------
# sort by x, cumulative share of weight, smallest x where share >= p
wquantile <- function(x, w, p) {
  o <- order(x)
  x <- x[o]; w <- w[o]
  share <- cumsum(w) / sum(w)
  x[which(share >= p)[1]]
}

x <- earners$earn_annual
w <- earners$hhweight

p10 <- wquantile(x, w, 0.10)
p50 <- wquantile(x, w, 0.50)
p90 <- wquantile(x, w, 0.90)

q2 <- tibble(
  n_earners          = nrow(earners),
  weighted_median    = round(p50),
  unweighted_median  = round(median(x)),
  weighted_p10       = round(p10),
  weighted_p90       = round(p90),
  p90_p10_ratio      = round(p90 / p10, 2),
  excluded_below_10k = sum(x < 1e4),
  excluded_above_10m = sum(x > 1e7),
  excluded_total     = sum(x < 1e4 | x > 1e7)
)
write_csv(q2, "outputs/q2_numbers.csv")

# ---- 5. Band table for Question 3 -----------------------------------------
bands <- earners |>
  group_by(band_start, band, midpoint) |>
  summarise(n_earners     = n(),
            weighted_mean = sum(hhweight * earn_annual) / sum(hhweight),
            .groups = "drop") |>
  arrange(band_start) |>
  mutate(thin = n_earners < 30)

write_csv(bands |> mutate(weighted_mean = round(weighted_mean)),
          "outputs/q3_band_table.csv")

print(as.data.frame(q2))
print(as.data.frame(bands |> mutate(weighted_mean = round(weighted_mean))))
