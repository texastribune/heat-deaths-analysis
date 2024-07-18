# This script will compare our estimates and dshs' official counts

# Library
library(tidyverse)

# Output data
daily_output <- read.csv("data/output/daily_output.csv")
yearly_output <- read.csv("data/output/yearly_output.csv")
output <- read.csv("data/output/output.csv")

# Compare year-by-year
yearly_total <- yearly_output %>% 
  group_by(year) %>% 
  summarize(
    deaths = sum(total_deaths),
    pred = sum(total_pred),
    lo = sum(total_lo),
    up = sum(total_up),
    excess = sum(total_excess),
    excess_lo = sum(total_excess_lo),
    excess_up = sum(total_excess_up)
  )

# DSHS' official counts
yearly_dshs <- read.csv("data/dshs.csv") %>% 
  # only using 2013-2019
  filter(year >= 2013 & year <= 2019) %>% 
  # differenciate column name for merging
  rename(dshs_deaths = deaths)

# Merge
yearly_merged <- full_join(
  yearly_total, yearly_dshs,
  by = "year"
)

# Visulaize
yearly_merged %>% 
  select(year, excess, dshs_deaths) %>% 
  pivot_longer(
    cols = c(excess, dshs_deaths),
    names_to = "name",
    values_to = "deaths"
  ) %>% 
  mutate(
    deaths = round(deaths),
    name = ifelse(name == "dshs_deaths", "DSHS Count", "Our Estimate") 
  ) %>% 
  ggplot(aes(x = year, y = deaths)) +
  geom_col(aes(fill = name), position = "dodge", alpha = 0.9) +
  scale_fill_manual(values = c("lightgray", "#bf1c0e")) +
  labs(
    title = "Comparison between our estimates and DSHS count",
    subtitle = "Daily relative threshold, April - September",
    x = "Deaths", y = "", fill = ""
  ) +
  theme_minimal() +
  theme(legend.position = "top")
