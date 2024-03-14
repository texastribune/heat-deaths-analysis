# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)

# source
source("scripts/utils.R")

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

# Year by year statewide
df_all_years %>% 
  group_by(year) %>% 
  summarize(total = n()) %>% 
  write_sheet(
    ss = "https://docs.google.com/spreadsheets/d/1juylzcqzxpCj4Y7IPxlixr4D2biqpJqlZtN6VWnpP5c",
    sheet = "Yearly statewide"
  )

# By date statewide
df_all_years %>% 
  group_by(date_of_death) %>% 
  summarize(total = n()) %>% 
  write_sheet(
    ss = "https://docs.google.com/spreadsheets/d/1juylzcqzxpCj4Y7IPxlixr4D2biqpJqlZtN6VWnpP5c",
    sheet = "Daily statewide"
  )
  
# Year by year by county
df_all_years %>% 
  group_by(year, county_of_death) %>% 
  summarize(total = n()) %>% 
  write_sheet(
    ss = "https://docs.google.com/spreadsheets/d/1juylzcqzxpCj4Y7IPxlixr4D2biqpJqlZtN6VWnpP5c",
    sheet = "Yearly by county"
  )

# Daily by county
df_all_years %>% 
  group_by(date_of_death, county_of_death) %>% 
  summarize(total = n()) %>% 
  write.csv("data/output/daily_death_by_county_2013_2022.csv", row.names = F)
