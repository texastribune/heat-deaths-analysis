# This script will check the death counts aggregated from DSHS's death indexes against CDC Wonder's aggregated data.
# The data are already loaded and cleaned through scripts `load-death-indexes.R` and `load_cdc_wonder_data.R`.

# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)

# source
source("scripts/00_utils.R")

#### Death indexes ####
di <- read.csv("data/output/daily_death_by_county_2013_2022.csv") %>% 
  mutate(
    date = ymd(date_of_death),
    year = year(date),
    month = month(date),
  ) %>% 
  select(
    year, month, county = county_of_death, deaths = total
  )

di_annually <- di %>% 
  group_by(year, county) %>% 
  summarize(deaths_di = sum(deaths))

di_monthly <- di %>% 
  group_by(year, month, county) %>% 
  summarize(deaths_di = sum(deaths))

#### CDC wonder deaths ####
cdc_annually <- read.csv("data/cdc/output/annually.csv") %>% 
  select(year, county, deaths_cdc = deaths)

cdc_monthly <- read.csv("data/cdc/output/monthly.csv") %>% 
  select(year, month, county, deaths_cdc = deaths)

# Join
cq_annually <- full_join(di_annually, cdc_annually, by = c("year", "county"))
cq_monthly <- full_join(di_monthly, cdc_monthly, by = c("year", "month", "county"))


#### Check ####
cq_annually %>% 
  mutate(
    diff = deaths_di - deaths_cdc,
    diff_pct = (diff / deaths_di) * 100
  ) %>% 
  write_sheet(
    "1XDwkb3km6MtcoZigqERiXbnW9uvhVeNt4Ib4g1o304w",
    sheet = "cq_annually"
  )


%>% 
  ggplot(aes(x = as.factor(year), y = diff_pct)) +
  geom_boxplot() +
  geom_jitter(alpha = 0.2) +
  ylim(-200, 200) +
  theme_minimal()
  