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
source("scripts/00_utils.R")

# variables
years <- c(1981:2022)

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
    day = day(date),
    week = week(date)
  ) %>% 
  # Make it wide(r) on types
  pivot_wider(
    names_from = "type",
    values_from = "value"
  ) %>% 
  # Convert temperature values from K to F. Relative humidity ranges from 0-100 (%)
  mutate(
    tmmx = kelvin.to.fahrenheit(tmmx, round = 5)
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
#     "data/output/daily_tmmx_rmin_1981-2022.csv",
#     row.names = F
#   )



#######################################
########## DEFINE HEAT EVENT ##########
#######################################

df_all_ <- read.csv("data/output/daily_tmmx_rmin_1981-2022.csv")

# Get 1981-2010 daily heat index 95th percentile for each county
normals_1981_2010_pctl_95 <- get_normals(df_all_, 1981, 2010)
  
# Get 1991-2020 daily heat index 95th percentile for each county
# hi_1991_2020_pctl_95 <- get_normals(df_all_, 1991, 2020)

# Let's get the 95th percentile rolling 30-year average.
# e.g.) For 2013 analysis, we use 1983-2012 average
# hi_rolling_pctl_95 <- data.frame()
# years <- c(2013:2022)
# 
# for(year_temp in years) {
#   print(paste0("starting ", year_temp, "..."))
#   year_start <- year_temp - 30
#   year_end <- year_temp - 1
#   
#   print(year_start)
#   print(year_end)
#   
#   df_30yr <- get_rolling_avg(df_all_, year_start, year_end)
#   hi_rolling_pctl_95 <- rbind(hi_rolling_pctl_95, df_30yr)
# }

# Merge 2013-2022 data with all these data above to define heat event days
heat_event_2013_2022 <- df_all_ %>% 
  filter(year >= 2013) %>% 
  full_join(
    normals_1981_2010_pctl_95,
    by = c("county", "month", "day")
  ) %>% 
  # full_join(
  #   hi_1991_2020_pctl_95,
  #   by = c("county", "month", "day")
  # ) %>% 
  # full_join(
  #   hi_rolling_pctl_95,
  #   by = c("county", "year", "month", "day")
  # ) %>% 
  mutate(
    # is_heat_event = ifelse(tmmx >= tmmx_pctl_95_1981_2010, T, F),
    is_heat_event_tmmx_1981_2010 = ifelse(tmmx >= tmmx_pctl_95_1981_2010, T, F),
    is_heat_event_hi_1981_2010 = ifelse(hi >= hi_pctl_95_1981_2010, T, F),
    # is_heat_event_tmmx_1991_2020 = ifelse(tmmx >= tmmx_pctl_95_1991_2020, T, F),
    # is_heat_event_hi_1991_2020 = ifelse(hi >= hi_pctl_95_1991_2020, T, F),
    # is_heat_event_tmmx_rolling = ifelse(tmmx >= tmmx_pctl_95_rolling, T, F),
    # is_heat_event_hi_rolling = ifelse(hi >= hi_pctl_95_rolling, T, F),
  )

# Save as CSV
# heat_event_2013_2022 %>%
#   write.csv(
#     "data/output/daily_heat_event_2013_2022.csv",
#     row.names = F
#   )


#######################################################################
########## LET'S LOOK INTO TMMX, HI AND IS_HEAT_EVENT VALUES ##########
#######################################################################

# Just look into Bexar county as an example
elpaso <- df_all_ %>% 
  filter(county == "ElPaso")

# Distribution of normals -- 1981-2010 vs 1991-2020
elpaso %>% 
  filter(month >= 4 & month <= 10) %>%
  select(month, day, tmmx, hi) %>%
  mutate(date = ymd(paste(2013, month, day, sep = "/"))) %>% 
  mutate(
    `Max temp` = round(tmmx),
    `Heat index` = round(hi)
  ) %>% 
  select(date, `Max temp`, `Heat index`) %>% 
  pivot_longer(
    cols = c(`Max temp`, `Heat index`),
    names_to = "name",
    values_to = "value"
  ) %>% 
  ggplot(aes(x = value)) +
  geom_histogram(color = 'white', binwidth = 1, alpha = 0.9, fill = "coral") +
  facet_wrap(~name, ncol = 1) +
  labs(
    title = "Distribution of Heat index and max temperature in El Paso County",
    subtitle = "From April to October between 1981 and 2022",
    x = "", y = ""
  ) +
  theme_minimal()

# Let's look at heat event days using different variables
heat_event <- heat_event_2013_2022 %>% 
  filter(month >= 4 & month <= 10) %>% 
  group_by(year) %>% 
  summarize(
    tmmx_1981_2010 = sum(is_heat_event_tmmx_1981_2010),
    hi_1981_2010 = sum(is_heat_event_hi_1981_2010),
    tmmx_1991_2020 = sum(is_heat_event_tmmx_1991_2020),
    hi_1991_2020 = sum(is_heat_event_hi_1991_2020),
    tmmx_rolling = sum(is_heat_event_tmmx_rolling),
    hi_rolling = sum(is_heat_event_hi_rolling),
  )

heat_event %>% 
  pivot_longer(
    cols = -year,
    names_to = "name",
    values_to = "count"
  ) %>% 
  ggplot(aes(x = as.factor(year), y = name)) +
  geom_tile(aes(fill = count), color = "black") +
  scale_fill_gradient2(
    low = "lightgray",
    high = "coral"
  ) +
  theme_minimal() +
  labs(
    title = "The number of heat event days using different variables",
    x = "", y = "", fill = "Count"
  )

heat_event_2013_2022 %>% 
  filter(county == "Harris") %>% 
  filter(month >= 5 & month <= 9) %>% 
  ggplot(aes(x = date)) +
  geom_point(aes(y = tmmx, color = is_heat_event_hi_1981_2010, alpha = is_heat_event_hi_1981_2010)) +
  geom_smooth(aes(y = tmmx)) +
  facet_wrap(~year, scales = "free_x") +
  scale_color_manual(values = c("gray", "red")) +
  theme_minimal()

# heat_event %>%
#   write_sheet(
#     "1XDwkb3km6MtcoZigqERiXbnW9uvhVeNt4Ib4g1o304w",
#     sheet = "heat_event_days"
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
