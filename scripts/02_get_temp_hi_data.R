# This script will gather county data from CDC National Environmental Public Health Tracking Network (Tracking Network) via a connection with the Tracking Network Data API.

library(tidyverse)
library(lubridate)
# devtools::install_github("CDCgov/EPHTrackR", dependencies = TRUE)
library(EPHTrackR)
# Documentation: https://github.com/CDCgov/EPHTrackR?tab=readme-ov-file

# Set API Token
tracking_api_token(
  "2f2ff073-9ce8-40ea-9011-05c425addbd8",
  install = T
)
readRenviron("~/.Renviron")

# List measure items to identify content area first
measures_inventory <- list_measures()
View(measures_inventory)
list_indicators(content_area = "Heat & Heat-related Illness (HRI)")

# Check geographic items
list_measures(content_area = 35) 
geo_items <- list_GeographicItems(
  measure = "Daily Maximum Temperature from May to September",
  # measure = "Daily Maximum Heat Index from May to September",
  geo_type = "County"
) %>% 
  as.data.frame()
texas_geo_items <- geo_items %>% 
  filter(parentName == "Texas")

# Check temproal items
temp_items <- list_TemporalItems(
  measure = "Daily Maximum Temperature from May to September",
  # measure = "Daily Maximum Heat Index from May to September"
) %>% 
  as.data.frame()

# Loop to retrieve data
for(i in 1:254) {
  # Wait for 20 seconds interval after five counties because
  # we would get an  error saying too many API calls for the time frame
  if (i %% 5 == 0) {
    print("***Pausing for 20 seconds***")
    Sys.sleep(20)
  }
  
  # County name and ID
  county_name <- texas_geo_items$childName[i]
  county_slug <- str_remove_all(toupper(county_name), " ")
  county_id <- texas_geo_items$childGeographicId[i]
  
  print(paste0("Starting ", county_name, " ..."))
  
  # Get Data
  df <- get_data(
    # measure = "Daily Maximum Temperature from May to September",
    measure = "Daily Maximum Heat Index from May to September",
    strat_level = "State x County",
    temporalItems = c(1981:2022),
    geoItems = county_id
  ) %>% 
    as.data.frame() 
  
  # Save raw data as CSV
  df %>% 
    write.csv(
      paste0("data/neph_tmmx/", county_slug, ".csv"),
      # paste0("data/neph_heat-index/", county_slug, ".csv"),
      row.names = F
    )
  
  rm(county_name, county_slug, county_id, df)
}

# Loop to read and clean data
df_all <- data.frame()

for (i in 1:254) {
  # County name
  county_name <- texas_geo_items$childName[i]
  county_slug <- str_remove_all(toupper(county_name), " ")
  
  print(paste0("Starting ", county_name, " ..."))
  
  # Load and clean data
  df <- read.csv(paste0("data/neph_heat-index/", county_slug, ".csv")) %>%
    # df <- read.csv(paste0("data/neph_tmmx/", county_slug, ".csv")) %>%    
    select(
      county = geo,
      county_fips = geoId,
      date,
      value = dataValue,
      yearly_max = yearlyMax
    )
  
  # Bind data
  df_all <- rbind(df_all, df) 
  
  rm(county_name, county_slug, df)
}

# Mutate some columns
df_all_ <- df_all %>% 
  mutate(
    county = str_remove_all(toupper(county), " "),
    date = ymd_hms(date),
  ) %>% 
  mutate(
    year = year(date),
    month = month(date),
    day = day(date)
  ) %>% 
  rename(
    hi = value
  ) %>% 
  select(-c(county_fips, yearly_max))

# Look into 2013-2019 daily max heat index distribution
df_all_ %>% 
  filter(year >= 2013 & year <= 2019) %>% 
  mutate(tempdate = ymd(paste("2016", month, day))) %>% 
  ggplot(aes(x = tempdate, y = hi)) +
  geom_point(size = 0.1, alpha = 0.025) +
  geom_hline(yintercept = 90, color = "orange") +
  geom_hline(yintercept = 103, color = "red") +
  labs(title = "Daily max heat index between 2013 and 2019 (all counties)",
       x = "Date", y = "Max Heat Index (F)") +
  scale_x_date(date_labels = "%b") +
  annotate("text", x = ymd("2016-01-01"), y = 93, label = "90F", color = "orange") +
  annotate("text", x = ymd("2016-01-01"), y = 106, label = "103F", color = "red") +
  theme_minimal()

# Get 1981-2010 daily heat index 95th percentile for each county
daily_threshold <- df_all_ %>% 
  filter(year >= 1981 & year <= 2010) %>%
  group_by(county, month, day) %>%
  mutate(
    daily_threshold = quantile(hi, probs = 0.95, na.rm = T),
  ) %>% 
  select(county, month, day, daily_threshold) %>% 
  distinct() 

# Merge 2013-2019 data with all these data above to define heat event days
heat_event <- df_all_ %>% 
  filter(year >= 2013 & year <= 2019) %>% 
  full_join(
    daily_threshold,
    by = c("county", "month", "day")
  ) %>% 
  mutate(
    # Define heat event days as the max heat index is above the 95th percentile of base years
    is_heat_event = ifelse(hi > daily_threshold, T, F)
  )

# write as CSV
heat_event %>%
  write.csv(
    "data/output/heat_event.csv",
    row.names = F
  )

# Clean the environment
rm(
  measures_inventory, geo_items, texas_geo_items, temp_items,
  df_all, df_all_, daily_threshold, heat_event
)
