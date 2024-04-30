# This script will calculate annual population by county from 2013 to 2022.
# Source: US Census 2020-2023 https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-total.html
# 2013-2019: https://www.census.gov/data/datasets/time-series/demo/popest/2010s-counties-total.html

# Libraries
library(tidyverse)
library(readxl)
library(lubridate)

# source
source("scripts/00_utils.R")

# operator
`%notin%` <- Negate(`%in%`)

# Load data
# 2010-2019
raw_2010_2019 <- read_excel(
  "data/population/co-est2019.xlsx"
)
df_2010_2019 <- raw_2010_2019 %>% 
  head(258) %>% 
  tail(-4) 

colnames(df_2010_2019) <- c("county", "census_2010", "base_2010", "est_2010", "est_2011", "est_2012", "est_2013",
                            "est_2014", "est_2015", "est_2016", "est_2017", "est_2018", "est_2019")

df_2010_2019 <- df_2010_2019 %>% 
  select(-c(census_2010, base_2010))%>% 
  mutate(county = format_county_census(county)) %>% 
  mutate_at(c("est_2010", "est_2011", "est_2012", "est_2013","est_2014",
              "est_2015", "est_2016", "est_2017","est_2018", "est_2019"), as.numeric) %>% 
  pivot_longer(
    cols = -county,
    names_to = "year",
    values_to = "population"
  ) %>% 
  mutate(
    year = str_remove(year, "est_")
  )

# 2020-2023
raw_2020_2023 <- read_excel(
  "data/population/co-est2023.xlsx"
)

df_2020_2023 <- raw_2020_2023 %>% 
  head(258) %>% 
  tail(-4) 

colnames(df_2020_2023) <- c("county", "base_2020", "est_2020", "est_2021", "est_2022", "est_2023")

df_2020_2023 <- df_2020_2023 %>% 
  select(-base_2020) %>% 
  mutate(county = format_county_census(county)) %>% 
  mutate_at(c( "est_2020", "est_2021", "est_2022", "est_2023"), as.numeric) %>% 
  pivot_longer(
    cols = -county,
    names_to = "year",
    values_to = "population"
  ) %>% 
  mutate(
    year = str_remove(year, "est_")
  )

# Merge
df <- rbind(df_2010_2019, df_2020_2023) %>% 
  arrange(county)

# Filter
df <- df %>% 
  filter(year %in% c(2013:2022)) %>% 
  mutate(year = as.numeric(year))

# Save as CSV
# df %>% 
#   write.csv(
#     "data/output/annually_population_by_county_2013_2022.csv",
#     row.names = F
#   )
