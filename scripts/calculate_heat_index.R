# This script will calculate maximum daily heat index for each county in Texas
# from 1991 to 2022. It will then define "heat event" day from 2013 to 2022
# where daily heat index is higher than the 95th percentile of 1991-2020 heat
# index distribution.

# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)
library(weathermetrics)

# Source
source("scripts/utils.R")

# variables
years <- c(1991:2022)

##############################################################
########## LOAD, BIND DATA AND CALCULATE HEAT INDEX ##########
##############################################################

# Load and bind all data from gridMET 
# -- downloaded through `scripts/get_gridmet_data.R`
# Empty data frame for binded data
df_all <- data.frame()

# Loop through years
for (year in years) {
  print(paste0("Starting ", year, "..."))
  df <- read.csv(paste0("data/gridmet/", year, ".csv")) 
  df_all <- rbind(df_all, df)
}

# Clean data and convert/calculate values
df_all_ <- df_all %>% 
  mutate(
    # Parse date and extract year, month and day
    date = ymd(date),
    year = year(date),
    month = month(date),
    day = day(date)
  ) %>% 
  # Make it wide(r) on types
  pivot_wider(
    names_from = "type",
    values_from = "value"
  ) %>% 
  # Convert temperature values from K to F. Relative humidity ranges from 0-100 (%)
  mutate(
    tmmx = kelvin.to.fahrenheit(tmmx)
  ) %>% 
  # Calculate heat index with max air temperature and minimum relative humidity
  mutate(
    hi = heat.index(
      t = tmmx,
      rh = rmin
    )
  )

# Save as a CSV file
# df_all_ %>% 
#   write.csv(
#     "data/output/daily_tmmx_rmin_1991-2022.csv",
#     row.names = F
#   )

#######################################
########## DEFINE HEAT EVENT ##########
#######################################

# Get 1991-2020 daily heat index 95th percentile for each county
hi_1991_2020_pctl_95 <- df_all_ %>% 
  filter(year <= 2020) %>% 
  select(county, date, year, month, day, hi) %>% 
  group_by(county, month, day) %>% 
  mutate(hi_pctl_95 = quantile(hi, probs = 0.95, na.rm = T)) %>% 
  select(county, month, day, hi_pctl_95) %>% 
  distinct()

# Merge 2013-2022 heat index data with 1991-2020 95th percentile and define heat event days
heat_event_2013_2022 <- df_all_ %>% 
  filter(year >= 2013) %>% 
  full_join(
    hi_1991_2020_pctl_95,
    by = c("county", "month", "day")
  ) %>% 
  mutate(
    is_heat_event = ifelse(hi > hi_pctl_95, T, F)
  )

# Save as CSV
# heat_event_2013_2022 %>% 
#   write.csv(
#     "data/output/daily_heat_event_2013_2022.csv",
#     row.names = F
#   )

# Write in a google spreadsheet
# heat_event_2013_2022 %>% 
#   write_sheet(
#     ss = "https://docs.google.com/spreadsheets/d/1c47n_L88je7YTu4CDB8m6KorjvS8HvS7cUZkKEm6dCI",
#     sheet = "2013-2022"
#   )













#############################################################
########## ANYTHING FROM HERE IS OLD (USING PRISM) ##########
#############################################################

# Load and bind all data
temp <- data.frame()

for(year in years) {
  print(paste0("Starting ", year, "..."))
  
  filename <- paste0(
    "data/prism/PRISM_tmin_tmean_tmax_tdmean_stable_4km_",
    year, "0101_", year, "1231.csv"
  )
  raw <- read_csv(
    filename,
    skip = 10,
    show_col_types = F
  ) 
  df <- raw %>% 
    select(
      county = Name,
      date = Date,
      tmin = `tmin (degrees F)`,
      tmean = `tmean (degrees F)`,
      tmax = `tmax (degrees F)`,
      tdmean = `tdmean (degrees F)`
    )
  
  temp <- rbind(df, temp)
  
  print(paste0(year, " done!"))
}

# Parse date and calculate heat index
# Heat index is a good indicator of how hot people felt, and is closely related to heat deaths (https://www.weather.gov/arx/heatindex_climatology)
# To calculate heat index, I'm using a package `weathermetrics` (https://github.com/geanders/weathermetrics)
temp_ <- temp %>% 
  mutate(
    date = ymd(date),
    year = year(date),
    month = month(date),
    day = day(date)
  ) %>% 
  mutate(
    hi = heat.index(
      t = tmax,
      dp = tdmean,
      temperature.metric = "fahrenheit",
      output.metric = "fahrenheit"
    )
  )

# Get 1991-2020 daily heat index 95th percentile for each county
hi_1991_2020_pctl_95 <- temp_ %>% 
  filter(year <= 2020) %>% 
  select(county, date, year, month, day, hi) %>% 
  group_by(county, month, day) %>% 
  mutate(hi_pctl_95 = quantile(hi, probs = 0.95, na.rm = T)) %>% 
  select(county, month, day, hi_pctl_95) %>% 
  distinct()

# Merge 2013-2022 heat index data with 1991-2020 95th percentile and define heat event days
heat_event_2013_2022 <- temp_ %>% 
  filter(year >= 2013) %>% 
  select(county, date, year, month, day, hi) %>% 
  full_join(
    hi_1991_2020_pctl_95,
    by = c("county", "month", "day")
  ) %>% 
  mutate(
    is_heat_event = ifelse(hi > hi_pctl_95, T, F)
  )
