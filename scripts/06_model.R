# Now finally run the model

# Library
library(tidyverse)
library(mgcv)
library(googlesheets4)

# Load data
df_processed <- read.csv("data/output/processed.csv") %>% 
  # only using april to september in this setting
  filter(month >= 4 & month <= 9) %>% 
  mutate(is_heat_event = is_heat_event_summer)

# County name
counties <- df_processed$county %>% 
  unique()

# Model
daily_output <- NULL
yearly_output <- NULL
output <- NULL

for(i in 1:length(counties)) {
  c <- counties[i]
  
  print(paste0(i, " ", c, "..."))
  
  # filter data to that county
  df_county <- df_processed %>% 
    filter(county == c)
  
  # the model
  model <- gam(
    deaths ~ 
      is_heat_event +
      year + # controlling by year
      as.factor(month) +
      as.factor(is_weekend) +
      offset(log(population)),
    family = nb(link = "log"),
    data = df_county
  )
  
  summary(model)
  
  # extract p-value to check the statistical significance
  p_value <- summary.gam(model)$p.pv[2]
  
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
  
  # subset to just heat days# subset to julag_heat_dayst heat days
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
  
  # # Calculate relative risk
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
  county_daily_output <- new_df_county %>% 
    mutate(
      excess = deaths - pred,
      excess_up = deaths - lo,
      excess_lo = deaths - up
    )
  
  daily_output <- rbind(daily_output, county_daily_output)
  
  # Year-by-year total of excess deaths on heat event days
  county_yearly_summary_output <- county_daily_output %>% 
    filter(is_heat_event) %>% 
    group_by(year) %>% 
    summarize(
      total_deaths = sum(deaths),
      total_pred = sum(pred),
      total_lo = sum(lo),
      total_up = sum(up),
      total_excess = sum(excess),
      total_excess_lo = sum(excess_lo),
      total_excess_up = sum(excess_up)
    ) %>% 
    mutate(
      county = c
    )
  
  yearly_output <- rbind(yearly_output, county_yearly_summary_output)
  
  # Output row
  county_output <- data.frame(
    county = c,
    avg_population,
    deaths.heatdays,
    deaths.predicted,
    p_value,
    rr,
    rr.lo,
    rr.up,
    af,
    excess,
    excess_up,
    excess_lo
  )
  
  output <- rbind(output, county_output)
  
  # Clear the environment
  rm(
    c, df_county, model, prs, new_df_county, new_df_county_heat_days,
    new_df_county_non_heat_days, county_daily_output,
    county_yearly_summary_output, county_output
  )
}

# Write output as CSV
daily_output %>% 
  write.csv("data/output/daily_output.csv", row.names = F)
yearly_output %>% 
  write.csv("data/output/yearly_output.csv", row.names = F)
output %>% 
  write.csv("data/output/output.csv", row.names = F)
