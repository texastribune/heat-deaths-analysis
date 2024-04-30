# This script will load COVID fatality data released by DSHS and calculate daily deaths by county between March 2020 and December 2022.
# Source; https://www.dshs.texas.gov/covid-19-coronavirus-disease-2019/texas-covid-19-data
# Note: 2023 daily fatality data by county is only available through May 6, 2023.
# If we are going to include 2023 into the analysis, we would have to consider how to handle COVID deaths. One good news is, CDC has updated its weekly, statewide COVID deaths data. https://data.cdc.gov/NCHS/Provisional-COVID-19-death-counts-rates-and-percen/mpx5-t7tu/about_data

# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)
library(zoo)

# source
source("scripts/00_utils.R")

# operator
`%notin%` <- Negate(`%in%`)

# variables
years <- c(2020:2022)
url <- "https://docs.google.com/spreadsheets/d/1OKwrIVWd6BDweGwZdcRKyAQaueyv7bhVpQjvoDwlh3o/"

#####################################################################
####################### LOAD COVID FATALITIES ####################### 
#####################################################################

# load
df_combined <- data.frame()

for(year in years) {
  sheet_name <- paste0("Fatalities by County ", as.character(year))
  
  df <- read_sheet(
    ss = url,
    sheet = sheet_name
  )
  
  df_long <- df %>% 
    pivot_longer(
      cols = -County,
      names_to = "date",
      values_to = "cum_deaths"
    )
  
  df_combined <- rbind(df_combined, df_long)
}

# clean
df_clean <- df_combined %>% 
  mutate(
    # In order to merge with other data
    county = toupper(str_remove_all(County, " ")),
    date = mdy(date),
    year = year(date),
    month = month(date),
    day = day(date)
  ) %>% 
  arrange(date) %>% 
  arrange(county) %>% 
  group_by(county) %>% 
  mutate(
    lag = ifelse(is.na(lag(cum_deaths)), 0, lag(cum_deaths)),
    deaths = cum_deaths - lag
  ) %>% 
  select(date, year, month, day, county, deaths) %>% 
  rename(covid_deaths = deaths) %>% 
  filter(county %notin% c("TOTAL", "INCOMPLETEADDRESS"))

# save as a CSV file
# df_clean %>%
#   write.csv(
#     'data/output/daily_covid_deaths_by_county_2020_2022.csv',
#     row.names = F
#   )
