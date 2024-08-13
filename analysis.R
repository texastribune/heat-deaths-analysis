# This script will load the processed data and run the model

# Library
library(tidyverse)
library(mgcv)

# Load data
df_processed <- read.csv("data/processed.csv") %>% 
  # only using april to september in this setting
  filter(month >= 4 & month <= 9) 

# County name
counties <- df_processed$county %>% 
  unique()

# Prepare variables to store output data
output <- NULL

# Loop through the counties
for(i in 1:length(counties)) {
  c <- counties[i]
  
  print(paste0(i, " ", c, "..."))
  
  # filter data to that county
  df_county <- df_processed %>% 
    filter(county == c)
  
  # model
  model <- gam(
    deaths ~ 
      is_heat_event +
      year +
      as.factor(month) +
      as.factor(is_weekend) +
      offset(log(population)),
    family = nb(link = "log"),
    data = df_county
  )
  
  # create new data for daily predicted values
  new_df_county <- df_county %>% 
    # suppose there were no heat days
    mutate(is_heat_event = F)
  
  # predict daily deaths had there been no heat-event days
  ginv <- model$family$linkinv
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
  
  # go back to original distribution of heat-event days
  new_df_county$is_heat_event <- df_county$is_heat_event
  
  # subset of heat-event days
  new_df_county_heat_days <- subset(
    new_df_county,
    is_heat_event == T
  )
  
  # subset of non-heat-event days
  new_df_county_non_heat_days <- subset(
    new_df_county,
    is_heat_event == F
  )
  
  # Tally up the number of actual deaths on heat-event event days
  deaths.heatdays <- sum(new_df_county_heat_days$deaths)
  
  # Tally up the predicted number of deaths on heat-event event days
  deaths.predicted <- sum(new_df_county_heat_days$pred)
  
  # # Calculate relative risk
  rr <- deaths.heatdays / deaths.predicted
  # And its margin of error
  rr.lo <- exp(log(rr - 1.96 * sqrt(1 / deaths.heatdays + 1 / deaths.predicted)))
  rr.up <- exp(log(rr + 1.96 * sqrt(1 / deaths.heatdays + 1 / deaths.predicted)))
  
  # Excess deaths is difference between observed and expected
  excess <- sum(new_df_county_heat_days$deaths - new_df_county_heat_days$pred)
  # And its margin of error
  excess_up <- sum(new_df_county_heat_days$deaths - new_df_county_heat_days$lo)
  excess_lo <- sum(new_df_county_heat_days$deaths - new_df_county_heat_days$up)
  
  # Get the average population of the county
  avg_population <- mean(df_county$population)
  
  # Output row
  county_output <- data.frame(
    county = c,
    avg_population,
    deaths.heatdays,
    deaths.predicted,
    rr,
    rr.lo,
    rr.up,
    excess,
    excess_up,
    excess_lo
  )
  
  output <- rbind(output, county_output)
}

# Write output as CSV
output %>% 
  write.csv("data/output.csv", row.names = F)
