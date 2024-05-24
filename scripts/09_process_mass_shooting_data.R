# This script loads and cleans fatalities from mass shootings

# Libraries
library(tidyverse)
library(lubridate)

# source
source("scripts/00_utils.R")

df <- read.csv("data/mass-shooting/mass_shooting_by_county.csv") %>% 
  mutate(
    date = ymd(date),
    year = year(date),
    month = month(date),
    day = day(date)
  ) %>% 
  select(
    year, month, day,
    county,
    mass_shooting_deaths = killed
  )

# Write as CSV
# df %>% 
#   write.csv("data/output/daily_mass_shootings.csv", row.names = F)
