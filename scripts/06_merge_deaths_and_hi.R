# This script will merge death indexes data (through `load-death-indexes.R`) and heat index (heat event) data (through `calculate_heat_index.R`).

# Libraries 
library(tidyverse)
library(lubridate)

# Death indexes data
death_indexes <- read.csv("data/output/daily_death_by_county_2013_2022.csv") %>% 
  rename(
    date = date_of_death,
    deaths = total
  ) %>% 
  mutate(
    # In order to merge with heat event data
    county = str_remove_all(county_of_death, " ")
  ) %>% 
  select(-county_of_death) %>% 
  # Theres one column where county information is unavailable
  filter(county != "UNKNOWN")

# Heat event data
heat_event <- read.csv("data/output/daily_heat_event_2013_2022.csv") %>% 
  mutate(
    # So data can be merged
    county = toupper(county)
  )

# Heat index by CDC
heat_event_cdc <- read.csv("data/output/daily_heat_event_cdc_2013_2022.csv") 

# merge data
merged <- full_join(
  death_indexes, heat_event,
  by = c("date", "county")
) %>% 
  full_join(
    heat_event_cdc,
    by = c("date", "year", "month", "day", "county")
  ) %>% 
  mutate(
    # parse date
    date = ymd(date),
    # replace NAs with 0
    deaths = ifelse(is.na(deaths), 0, deaths),
    # determine weekend
    is_weekend = ifelse(wday(date, label = T) %in% c("Sat", "Sun"), T, F)
  ) %>% 
  select(date, year, month, day, is_weekend, county, deaths, tmmx:is_heat_event_hi_cdc_1981_2010)

# save as CSV
# merged %>%
#   write.csv(
#     "data/output/merged_deaths_heat_event_2013_2022.csv",
#     row.names = F
#   )

# save subset data in spreadsheet to show experts
# merged %>%
#   filter(county %in% c("HARRIS", "WEBB", "LIBERTY")) %>%
#   write_sheet(
#     ss = "https://docs.google.com/spreadsheets/d/1XDwkb3km6MtcoZigqERiXbnW9uvhVeNt4Ib4g1o304w"
#   )
