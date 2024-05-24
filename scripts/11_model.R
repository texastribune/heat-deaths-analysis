# This script will finally use all processed data and build a statistical model.

# Library
library(tidyverse)
library(mgcv)
library(googlesheets4)

# Source
source("scripts/00_utils.R")

# Load proecssed data
df_processed <- read.csv("data/output/final_merged_di_hi_covid_population_mass_shooting.csv")

# Counties to use -- ones with 25K or larger population in 2020. This gives us 99 larger counties.
larger_counties <- df_processed %>% 
  filter(year == 2020 & population > 25000) %>% 
  select(year, county) %>% 
  distinct() %>% 
  pull(county) # 99 counties

# Use only May through September
df_prepped <- df_processed %>% 
  filter(county %in% larger_counties) %>% 
  filter(month >= 5 & month <= 9) %>%
  mutate(
    deaths = deaths_minus_mass_shooting,
    # To subtract by-residence COVID deaths for reference
    # deaths = deaths_minus_mass_shooting - covid_deaths,
    is_heat_event = is_heat_event_hi_cdc_1981_2010
  ) %>%
  select(
    -c(deaths_minus_covid, deaths_minus_mass_shooting)
  ) 
  # To subtract by-residence COVID deaths for reference
  # mutate(
  #   deaths = ifelse(deaths < 0, 0, deaths)
  # )

daily_output <- NULL
output <- NULL

# Loop through the counties
for(c in larger_counties) {
  print(c)
  
  county_output <- calculate_excess_deaths(c, df_prepped)
  output <- rbind(output, county_output)
}

output[output == Inf] <- NA
output[output == -Inf] <- NA

# Count statistically significant models
output %>% 
  filter(p_value < 0.05) %>% 
  count()

# Total number of excess deaths in 99 counties
output %>% 
  summarize(total_excess = sum(excess))

# Visualize excess deaths and margins of error for each county
output %>% 
  arrange(excess) %>% 
  mutate(row = -row_number()) %>% 
  ggplot(aes(x = row)) +
  geom_hline(yintercept = 0, color = "#444444", size = 0.5) +
  geom_segment(aes(x = row, y = excess_lo, xend = row, yend = excess_up), alpha = 0.1, size = 1.5) +
  geom_point(aes(y = excess_lo), color = "steelblue", size = 0.8) +
  geom_point(aes(y = excess_up), color = "salmon", size = 0.8) +
  geom_point(aes(y = excess), color = "#444444", size = 0.8) +
  labs(
    title = "Excess deaths and margin of error by county, with by-residence COVID subtraction",
    subtitle = "Sum of 2020-2022 excess deaths, using CDC's max heat index data",
    x = "", y = "Excess"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_blank()
  )