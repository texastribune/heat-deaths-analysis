# This script will merge all data -- by loading the merged data of daily heat index and death index by county and annual population data. And then organize the data so it can be used to build a model

# Library
library(tidyverse)
library(lubridate)

# source
source("scripts/00_utils.R")

# operator
`%notin%` <- Negate(`%in%`)

# Load data
death_indexes <- read.csv("data/output/death_indexes.csv") %>% 
  mutate(
    date = ymd(date),
    year = year(date)
  ) 

heat_event <- read.csv("data/output/heat_event.csv") %>% 
  mutate(
    date = ymd(date)
  )

population <- read.csv("data/output/population.csv") 
mass_shooting <- read.csv("data/output/mass_shootings.csv") 

# Merge data
df_merged <- full_join(
    death_indexes, heat_event,
    by = c("date", "year", "county")
  ) %>% 
  full_join(
    population,
    by = c("county", "year")
  ) %>% 
  full_join(
    mass_shooting,
    by = c("year", "month", "day", "county")
  ) %>% 
  mutate(
    total_deaths = replace_na(total_deaths, 0),
    mass_shooting_deaths = replace_na(mass_shooting_deaths, 0)
  ) 

# Organize the data for the model
df_processed <- df_merged %>% 
  # only using 2013-2019 data
  filter(year >= 2013 & year <= 2019) %>% 
  # only using 41 most populous counties
  filter(is_larger_county == T) %>% 
  # adding a variable about weekend
  mutate(is_weekend = ifelse(wday(date, label = T) %in% c("Sat", "Sun"), T, F)) %>% 
  group_by(date, county) %>% 
  mutate(deaths = max(c(0, total_deaths - mass_shooting_deaths))) %>% 
  ungroup() %>%
  select(date, county, year, month, day, is_weekend, deaths, population, hi, is_heat_event_daily, is_heat_event_summer)

# Write as CSV
df_processed %>% 
  write.csv("data/output/processed.csv", row.names = F)

# Clean the environment
rm(death_indexes, heat_event, population, mass_shooting, df_merged, df_processed)

