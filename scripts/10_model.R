# This script will finally use all processed data and build a statistical model.

# Library
library(tidyverse)
library(mgcv)
library(googlesheets4)

# Load proecssed data
df_processed <- read.csv("data/output/final_merged_di_hi_covid_population.csv")

# Use only April to October
df_prepped <- df_processed %>% 
  filter(month >= 4 & month <= 10) %>% 
  mutate(deaths_ = deaths) %>% 
  # simply subtract covid deaths
  mutate(deaths = deaths_ - covid_deaths) %>% 
  mutate(deaths = ifelse(deaths < 0, 0, deaths))

# Get a list of all counties
counties <- unique(df_prepped$count)

daily_output <- NULL
output <- NULL

# Loop through the counties
for(c in counties) {
  print(c)
  
  # Filter data to that county
  df_county <- df_prepped %>% 
    filter(county == c)
  
  # The model
  model <- gam(
    deaths ~ 
      is_heat_event +
      as.factor(month) +
      as.factor(is_weekend) +
      offset(log(population)),
    family = nb(link = "log"),
    data = df_county
  )
  
  # create new data for daily predicted values
  new_df_county <- df_county
  
  # suppose there were no heat days
  new_df_county$is_heat_event <- F
  
  # predict daily deaths had there been no heat days
  ginv <- model$family$linkinv # inverse link function
  prs <- predict(
    model,
    newdata = new_df_county,
    type = "link",
    se.fit = T,
    interval = "predictions"
  )
  
  new_df_county$pred <- ginv(prs[[1]])
  new_df_county$lo <- ginv(prs[[1]] - 1.96 * prs[[2]])
  new_df_county$up <- ginv(prs[[1]] + 1.96 * prs[[2]])
  
  # go back to original distribution of heat days
  new_df_county$is_heat_event <- df_county$is_heat_event
  
  # subset to just heat days
  new_df_county_heat_days <- subset(
    new_df_county,
    is_heat_event == T
  )
  
  # subset of days without extreme heat
  new_df_county_non_heat_days <- subset(
    new_df_county,
    is_heat_event == F
  )
  
  # Tally up the number of observed deaths on heat event days
  deaths.heatdays <- sum(new_df_county_heat_days$deaths)
  
  # Tally up the predicted number of deaths on heat event days
  deaths.predicted <- sum(new_df_county_heat_days$pred)
  
  # Calculate relative risk
  rr <- deaths.heatdays / deaths.predicted
  # And its margin of error
  rr.lo <- exp(log(rr - 1.96 * sqrt(1 / deaths.heatdays + 1 / deaths.predicted)))
  rr.up <- exp(log(rr + 1.96 * sqrt(1 / deaths.heatdays + 1 / deaths.predicted)))
  
  # Calculate attributable fraction
  af <- (rr - 1) / rr
  
  # Excess deaths is difference between observed and expected
  excess <- sum(new_df_county_heat_days$deaths - new_df_county_heat_days$pred)
  # And its margin of error
  # note that the lower bound of predicted deaths is used to estimate
  # the upper bound of excess deaths
  excess_up <- sum(new_df_county_heat_days$deaths - new_df_county_heat_days$lo)
  excess_lo <- sum(new_df_county_heat_days$deaths - new_df_county_heat_days$up)
  
  # Get the average population of the county
  avg_population <- mean(df_county$population)
  
  # Output a dataframe with one row per day for all counties and calculated values
  daily_output <- rbind(
    daily_output,
    new_df_county
  )
  
  output <- rbind(
    output,
    data.frame(
      county = c,
      avg_population,
      deaths.heatdays,
      deaths.predicted,
      rr,
      rr.lo,
      rr.up,
      af,
      excess,
      excess_up,
      excess_lo
    )
  )
}

output[output == Inf] <- NA
output[output == -Inf] <- NA

# output %>%
#   arrange(county) %>%
#   write_sheet(
#     "15PRJfTR8asQS1IhYGmqdw0GQ44rK5OtqIK9TlxjRUAg",
#     sheet = "output_covid_subtracted"
#   )
# 
# output %>%
#   write.csv(
#     "data/output/excess_deaths_covid_subtracted.csv",
#     row.names = F
#   )
