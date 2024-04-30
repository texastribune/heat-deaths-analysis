# This script will load monthly count of deaths by county between 2013 to 2022 downloaded from CDC Wonder and cross-check the. numbers we obtained from DSHS death indexes.
# Source: https://wonder.cdc.gov/mcd.html

# Libraries
library(tidyverse)
library(lubridate)

# source
source("scripts/00_utils.R")

# operator
`%notin%` <- Negate(`%in%`)

# variables
intervals <- c("annually", "monthly")
year_ranges <- c("2013-2017", "2018-2022")

###############################################################
####################### LOAD DEATH DATA ####################### 
###############################################################

#### Monthly ####
monthly <- data.frame()

# 2013-2017
file_name <- paste0("data/cdc/raw/monthly/2013-2017.txt")
mon_2013_2017 <- read.delim(file_name, header = T) %>% 
  filter(!is.na(Year)) %>% 
  select(
    year = Year,
    month = Month.Code,
    county = County, 
    deaths = Deaths
  ) %>% 
  mutate(
    month = as.numeric(str_sub(month, start = -2)),
    county = toupper(str_remove_all(str_sub(county, end = -12), " ")),
    deaths = ifelse(deaths == "Suppressed", NA, as.numeric(deaths)),
    interval = "monthly"
  ) 

# 2018-2022
file_name <- paste0("data/cdc/raw/monthly/2018-2022.txt")
mon_2018_2022 <- read.delim(file_name, header = T) %>% 
  filter(!is.na(Year.Code)) %>% 
  select(
    year = Year,
    month = Month.Code,
    county = Occurrence.County, 
    deaths = Deaths
  ) %>% 
  mutate(
    year = ifelse(year == "2022 (provisional)", 2022, as.numeric(year)),
    month = as.numeric(str_sub(month, start = -2)),
    county = toupper(str_remove_all(str_sub(county, end = -12), " ")),
    deaths = ifelse(deaths == "Suppressed", NA, as.numeric(deaths)),
    interval = "monthly"
  ) 

# bind
monthly <- rbind(mon_2013_2017, mon_2018_2022)

# write as CSV
monthly %>% 
  write.csv(
    "data/cdc/output/monthly.csv",
    row.names = F
  )


#### Annually ####
annually <- data.frame()

# 2013-2017
file_name <- paste0("data/cdc/raw/annually/2013-2017.txt")
ann_2013_2017 <- read.delim(file_name, header = T) %>% 
  filter(!is.na(Year)) %>% 
  select(
    year = Year,
    county = County, 
    deaths = Deaths
  ) %>% 
  mutate(
    county = toupper(str_remove_all(str_sub(county, end = -12), " ")),
    deaths = ifelse(deaths == "Suppressed", NA, as.numeric(deaths)),
    interval = "annually"
  ) 

# 2018-2022
file_name <- paste0("data/cdc/raw/annually/2018-2022.txt")
ann_2018_2022 <- read.delim(file_name, header = T) %>% 
  filter(!is.na(Year.Code)) %>% 
  select(
    year = Year.Code,
    county = Occurrence.County, 
    deaths = Deaths
  ) %>% 
  mutate(
    county = toupper(str_remove_all(str_sub(county, end = -12), " ")),
    deaths = ifelse(deaths == "Suppressed", NA, as.numeric(deaths)),
    interval = "annually"
  ) 

# bind
annually <- rbind(ann_2013_2017, ann_2018_2022)

# How many NAs??
annually %>% 
  filter(is.na(deaths)) %>% 
  count() # 86

# write as CSV
annually %>% 
  write.csv(
    "data/cdc/output/annually.csv",
    row.names = F
  )
