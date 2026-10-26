# 03_distribution.R  (Question 2: weighted histogram of annual earnings)
# Run 01_prepare.R first.

library(readr)
library(dplyr)
library(ggplot2)

earners <- read_csv("outputs/analysis_data.csv", show_col_types = FALSE)
q2      <- read_csv("outputs/q2_numbers.csv", show_col_types = FALSE)

# Keep Rs 10,000 to Rs 10,000,000 (log10 4 to 7); the rest are counted in the caption
in_range <- earners |>
  filter(earn_annual >= 1e4, earn_annual <= 1e7) |>
  mutate(log_earn = log10(earn_annual))

rupees <- function(v) paste0("Rs ", format(v, big.mark = ",", scientific = FALSE, trim = TRUE))

med <- log10(q2$weighted_median)
p90 <- log10(q2$weighted_p90)

p <- ggplot(in_range, aes(x = log_earn, weight = hhweight)) +
  # density = weighted share in the bin / bin width (0.1), i.e. per log10 unit
  geom_histogram(aes(y = after_stat(density)),
                 breaks = seq(4, 7, by = 0.1), closed = "left",
                 fill = "#4C78A8", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = c(med, p90), linetype = "dashed", linewidth = 0.6) +
  annotate("text", x = med, y = Inf, vjust = 1.5, hjust = 1.05, size = 3.6,
           label = paste0("Median\n", rupees(q2$weighted_median))) +
  annotate("text", x = p90, y = Inf, vjust = 1.5, hjust = -0.05, size = 3.6,
           label = paste0("90th percentile\n", rupees(q2$weighted_p90))) +
  scale_x_continuous(limits = c(4, 7), breaks = 4:7,
                     labels = rupees(10^(4:7)),
                     expand = expansion(mult = 0.01)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(
    title = paste0("Half of urban Punjab's earners make less than ",
                   rupees(q2$weighted_median), " a year"),
    subtitle = paste0("The 90th percentile (", rupees(q2$weighted_p90), ") is ",
                      format(q2$p90_p10_ratio, nsmall = 2), " times the 10th percentile (",
                      rupees(q2$weighted_p10), ")"),
    x = "Annual earnings (log scale)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019-20 person file. Sample: ", format(q2$n_earners, big.mark = ","),
      " earners (ages 15-64, annual earnings > 0) in urban Punjab.\n",
      "All statistics weighted by hhweight. ", q2$excluded_total,
      " earners outside Rs 10,000 to Rs 10,000,000 are excluded from the histogram (",
      q2$excluded_below_10k, " below, ", q2$excluded_above_10m, " above).")
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey35"),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.margin = margin(10, 30, 10, 10))

ggsave("figures/q2_distribution.svg", p, width = 9, height = 5.5)
