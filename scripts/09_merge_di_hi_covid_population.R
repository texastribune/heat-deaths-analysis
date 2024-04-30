# This script will merge all data -- by loading the merged data of daily heat index and death index by county, and daily COVID deaths and annual population data.

# Library
library(tidyverse)
library(lubridate)

# source
source("scripts/00_utils.R")

# operator
`%notin%` <- Negate(`%in%`)

# Load merged data and covid data
daily_di_hi <- read.csv("data/output/merged_deaths_heat_event_2013_2022.csv")
daily_covid <- read.csv("data/output/daily_covid_deaths_by_county_2020_2022.csv") 

daily_di_hi_covid <- full_join(
  daily_di_hi, daily_covid,
  by = c("date", "year", "month", "day", "county")
) %>% 
  mutate(covid_deaths = ifelse(is.na(covid_deaths), 0, covid_deaths))

# Load population data
annually_population <- read.csv("data/output/annually_population_by_county_2013_2022.csv")

daily_di_hi_covid_population <- full_join(
  daily_di_hi_covid, annually_population,
  by = c("year", "county")
)

# Save merged data
# daily_di_hi_covid_population %>% 
#   write.csv(
#     "data/output/final_merged_di_hi_covid_population.csv",
#     row.names = F
#   )
