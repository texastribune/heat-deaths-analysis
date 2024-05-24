load_death_indexes <- function(year) {
  filename <- paste0("data/raw/death-indexes/", year, ".csv")
  raw <- read.csv(filename)
  
  df <- raw %>% 
    tail(-13)
  colnames(df) <- c("last_name", "first_name", "middle_name", "date_of_death", "county_of_death", "sex")
  df <- df %>% 
    mutate(
      name = paste(first_name, middle_name, last_name),
      date_of_death = mdy(date_of_death),
      year = year(date_of_death),
      county_of_death = str_remove_all(county_of_death, " "),
    ) %>% 
    select(name, sex, date_of_death, county_of_death, year) %>% 
    arrange(county_of_death) %>% 
    arrange(date_of_death) 

  return (df)
}

get_normals <- function(df_all_, year_start, year_end) {
  pctl_95 <- df_all_ %>% 
    filter(year >= year_start & year <= year_end) %>% 
    select(county, date, year, month, day, tmmx, hi)  %>% 
    group_by(county, month, day) %>% 
    mutate(
      tmmx_pctl_95 = quantile(tmmx, probs = 0.95, na.rm = T),
      hi_pctl_95 = quantile(hi, probs = 0.95, na.rm = T)
    ) %>% 
    # select(county, week, tmmx_pctl_95, hi_pctl_95) %>%
    select(county, month, day, tmmx_pctl_95, hi_pctl_95) %>%
    distinct() 
  
  colnames(pctl_95) <- c(
    "county", "month", "day",
    paste("tmmx_pctl_95", year_start, year_end, sep = "_"),
    paste("hi_pctl_95", year_start, year_end, sep = "_")
  )
  
  return (pctl_95)
}

get_rolling_avg <- function(df_all_, year_start, year_end) {
  pctl_95 <- df_all_ %>% 
    filter(year >= year_start & year <= year_end) %>% 
    select(county, date, month, day, tmmx, hi) %>% 
    group_by(county, month, day) %>% 
    mutate(
      tmmx_pctl_95 = quantile(tmmx, probs = 0.95, na.rm = T),
      hi_pctl_95 = quantile(hi, probs = 0.95, na.rm = T)
    ) %>% 
    select(county, month, day, tmmx_pctl_95, hi_pctl_95) %>% 
    distinct() %>% 
    mutate(year = year_end + 1) %>% 
    select(county, year, month, day, tmmx_pctl_95, hi_pctl_95)
  
  colnames(pctl_95) <- c("county", "year", "month", "day", "tmmx_pctl_95_rolling", "hi_pctl_95_rolling")
  
  return (pctl_95)
}

calculate_excess_deaths <- function(c, df_prepped) {
  c <- "HARRIS"
  
  # Filter data to that county
  df_county <- df_prepped %>% 
    filter(county == c)
  
  # Filter data before COVID for modeling
  df_county_pre_covid <- df_county %>% 
    filter(year <= 2019)
  
  # Filter data after COVID for estimates
  df_county_post_covid <- df_county %>% 
    filter(year >= 2020)
  
  # The model
  model <- gam(
    deaths ~ 
      is_heat_event +
      as.factor(month) +
      as.factor(is_weekend) +
      offset(log(population)),
    family = nb(link = "log"),
    data = df_county_pre_covid # using pre COVID data for modeling
  )
  
  summary(model)
  
  # extract p-value to check the statistical significance
  p_value <- summary.gam(model)$p.pv[2]
  
  # create new data for daily predicted values. Using post COVID data for estimates
  new_df_county_post_covid <- df_county_post_covid
  
  # suppose there were no heat days
  new_df_county_post_covid$is_heat_event <- F
  
  # predict daily deaths had there been no heat days
  ginv <- model$family$linkinv # inverse link function
  prs <- predict(
    model,
    newdata = new_df_county_post_covid,
    type = "link",
    se.fit = T,
    interval = "predictions"
  )
  
  new_df_county_post_covid$pred <- ginv(prs[[1]])
  new_df_county_post_covid$lo <- ginv(prs[[1]] - 1.96 * prs[[2]])
  new_df_county_post_covid$up <- ginv(prs[[1]] + 1.96 * prs[[2]])
  
  # go back to original distribution of heat days
  new_df_county_post_covid$is_heat_event <- df_county_post_covid$is_heat_event
  
  # subset to just heat days
  new_df_county_post_covid_heat_days <- subset(
    new_df_county_post_covid,
    is_heat_event == T
  )
  
  # subset of days without extreme heat
  new_df_county_post_covid_non_heat_days <- subset(
    new_df_county_post_covid,
    is_heat_event == F
  )
  
  # Tally up the number of observed deaths on heat event days
  deaths.heatdays <- sum(new_df_county_post_covid_heat_days$deaths)
  
  # Tally up the predicted number of deaths on heat event days
  deaths.predicted <- sum(new_df_county_post_covid_heat_days$pred)
  
  # Calculate relative risk
  rr <- deaths.heatdays / deaths.predicted
  # And its margin of error
  rr.lo <- exp(log(rr - 1.96 * sqrt(1 / deaths.heatdays + 1 / deaths.predicted)))
  rr.up <- exp(log(rr + 1.96 * sqrt(1 / deaths.heatdays + 1 / deaths.predicted)))
  
  # Calculate attributable fraction
  af <- (rr - 1) / rr
  
  # Excess deaths is difference between observed and expected
  excess <- sum(new_df_county_post_covid_heat_days$deaths - new_df_county_post_covid_heat_days$pred)
  # And its margin of error
  # note that the lower bound of predicted deaths is used to estimate
  # the upper bound of excess deaths
  excess_up <- sum(new_df_county_post_covid_heat_days$deaths - new_df_county_post_covid_heat_days$lo)
  excess_lo <- sum(new_df_county_post_covid_heat_days$deaths - new_df_county_post_covid_heat_days$up)
  
  # Get the average population of the county
  avg_population <- mean(df_county$population)
  
  # Output a dataframe with one row per day for all counties and calculated values
  county_daily_output <- new_df_county_post_covid %>% 
    mutate(
      excess = deaths - pred,
      excess_up = deaths - lo,
      excess_lo = deaths - up
    )
  
  # Year-by-year total of excess deaths on heat event days
  county_yearly_summary_output <- county_daily_output %>% 
    filter(is_heat_event) %>% 
    group_by(year) %>% 
    summarize(
      total_excess = sum(excess),
      total_excess_lo = sum(excess_lo),
      total_excess_up = sum(excess_up)
    )
  
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
  
  return (county_output)
}
