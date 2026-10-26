# 04_age_redesign.R  (Question 3: earnings against age; also the Q4 redesign)
# Run 01_prepare.R first.

library(readr)
library(dplyr)
library(ggplot2)

earners <- read_csv("outputs/analysis_data.csv", show_col_types = FALSE)
q2      <- read_csv("outputs/q2_numbers.csv", show_col_types = FALSE)
bands   <- read_csv("outputs/q3_band_table.csv", show_col_types = FALSE)

rupees <- function(v) paste0("Rs ", format(v, big.mark = ",", scientific = FALSE, trim = TRUE))

# Points: jitter age by at most 0.4 years; seed fixed so the figure is reproducible
set.seed(346)
points <- earners |>
  filter(earn_annual >= 1e4, earn_annual <= 1e7) |>
  mutate(age_jit = age + runif(n(), -0.4, 0.4))

top <- bands |> slice_max(weighted_mean, n = 1)

p <- ggplot() +
  geom_point(data = points, aes(age_jit, earn_annual),
             alpha = 0.2, size = 1.1, colour = "grey30", stroke = 0) +
  geom_line(data = bands, aes(midpoint, weighted_mean),
            colour = "#C0392B", linewidth = 1) +
  # filled markers = 30+ earners; hollow (white fill) = thin band (< 30)
  geom_point(data = bands, aes(midpoint, weighted_mean, fill = thin),
             shape = 21, size = 3.2, colour = "#C0392B", stroke = 1.2,
             show.legend = FALSE) +
  scale_fill_manual(values = c(`FALSE` = "#C0392B", `TRUE` = "white")) +
  annotate("text", x = top$midpoint, y = top$weighted_mean * 1.9,
           label = paste0("Highest mean: ages ", top$band, "\n",
                          rupees(top$weighted_mean)),
           size = 3.6, colour = "#C0392B", fontface = "bold") +
  annotate("segment", x = top$midpoint, xend = top$midpoint,
           y = top$weighted_mean * 1.55, yend = top$weighted_mean * 1.12,
           colour = "#C0392B") +
  scale_y_log10(limits = c(1e4, 1e7), breaks = 10^(4:7), labels = rupees(10^(4:7))) +
  scale_x_continuous(limits = c(14.5, 64.5), breaks = seq(15, 65, 5)) +
  labs(
    title = "Average earnings more than triple between the late teens and the late fifties",
    subtitle = "Weighted mean annual earnings by five-year age band (red), over every individual earner (grey)",
    x = "Age (years)",
    y = "Annual earnings (log scale)",
    caption = paste0(
      "Source: PSLM 2019-20 person file. Sample: ", format(q2$n_earners, big.mark = ","),
      " earners (ages 15-64, annual earnings > 0) in urban Punjab. Means weighted by hhweight.\n",
      "Grey points jittered by up to 0.4 years. Filled markers: bands with 30+ earners; hollow markers would mark thin bands (< 30). ",
      "\n", q2$excluded_total, " earners outside the axis range are not drawn but are included in the means.")
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey35"),
        plot.title.position = "plot",
        plot.caption.position = "plot")

ggsave("figures/q3_earnings_by_age.svg", p, width = 9, height = 6)
