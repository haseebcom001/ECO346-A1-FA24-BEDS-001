# 02_default.R  (Question 4: R's default scatterplot, nothing added)
# Run 01_prepare.R first.

library(readr)
library(ggplot2)

data <- read_csv("outputs/analysis_data.csv", show_col_types = FALSE)

p <- ggplot(data, aes(age, earn_annual)) + geom_point()

dir.create("figures", showWarnings = FALSE)
ggsave("figures/default.svg", p, width = 7, height = 5)
