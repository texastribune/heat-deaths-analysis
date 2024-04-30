# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)

# source
source("scripts/00_utils.R")

# operator
`%notin%` <- Negate(`%in%`)


##################################################################
####################### LOAD DEATH INDEXES ####################### 
##################################################################

years <- c(2013:2022)
df_all_years <- data.frame()

for(year in years) {
  df <- load_death_indexes(year)
  df_all_years <- rbind(df, df_all_years)  
}

#########################################################
####################### BASIC EDA ####################### 
#########################################################

# Missing / duplicated data?
df_all_years %>% 
  group_by(name, county_of_death, date_of_death) %>% 
  summarize(total = n()) %>% 
  filter(total != 1)

# Daily by county
df_all_years %>% 
  group_by(date_of_death, county_of_death) %>% 
  summarize(total = n()) %>% 
  write.csv("data/output/daily_death_by_county_2013_2022.csv", row.names = F)
