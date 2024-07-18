# This script will load raw death indexes and aggregate them by county.

# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)

# operator
`%notin%` <- Negate(`%in%`)


##################################################################
####################### LOAD DEATH INDEXES ####################### 
##################################################################

years <- c(2013:2022)
df_all_years <- data.frame()

for(year in years) {
  print(year)
  filename <- paste0("data/raw/death-indexes/", year, ".csv")
  raw <- read.csv(filename, fileEncoding="latin1")
  
  df <- raw %>% 
    tail(-13)
  colnames(df) <- c("last_name", "first_name", "middle_name", "date", "county", "sex")
  
  df <- df %>% 
    mutate(
      first_name = ifelse(first_name != "", trimws(first_name), ""),
      middle_name = ifelse(middle_name != "", trimws(middle_name), ""),
      last_name = ifelse(last_name != "", trimws(last_name), "")
    ) %>% 
    mutate(
      name = paste(first_name, middle_name, last_name),
      date = mdy(date),
      year = year(date),
      county = str_remove_all(county, " "),
    ) %>% 
    select(name, sex, date, county, year) %>% 
    arrange(county) %>% 
    arrange(date) 
  
  df_all_years <- rbind(df, df_all_years)  
  
  rm(year, filename, raw, df)
}

#########################################################
####################### BASIC EDA ####################### 
#########################################################

# Missing / duplicated data?
df_all_years %>% 
  group_by(name, county, date) %>% 
  summarize(total = n()) %>% 
  filter(total != 1)
# "BABY DIOP" in Dallas on July 27, 2013 and "GUADALUPE GONZALES" in Cameron on May 13, 2014, have same first, middle, last names and date of death, county of death. But they are associated with different sex. Should we treat them as duplicates?

# Daily by county
death_indexes <- df_all_years %>% 
  group_by(date, county) %>% 
  summarize(total_deaths = n()) 

death_indexes %>% 
  filter(county != "UNKNOWN") %>% 
  write.csv("data/output/death_indexes.csv", row.names = F)

# Clean environment
rm(df_all_years, death_indexes)
