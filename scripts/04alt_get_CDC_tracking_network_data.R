# This script will gather county data from CDC National Environmental Public Health Tracking Network (Tracking Network) via a connection with the Tracking Network Data API.

# devtools::install_github("CDCgov/EPHTrackR", dependencies = TRUE)
library(EPHTrackR)

# tracking_api_token(
#   "",
#   install = T
# )

measures_inventory <- list_measures()

View(measures_inventory)

list_indicators(content_area = "Heat & Heat-related Illness (HRI)")
list_measures(content_area = 35)
list_GeographicItems(
  measure = "Historical Mean Daily Max. Heat Index by day of year for Summer Months (May-September)",
  geo_type = "County"
)

get_data(
  measure = 913,
  strat_level = "State x County",
  temporalItems = c(2022),
  geoItems = "Harris, TX"
)

###################################################################
####################### LOAD MAX HEAT INDEX ####################### 
###################################################################

# While requesting API token, I manually downloaded historical max heat index for 99 largest counties
# https://ephtracking.cdc.gov/DataExplorer/?c=35&i=173&m=-1

root_path <- "data/heat-index/"

files <- list.files(path = root_path)

df_all <- data.frame()

for (file in files) {
  county <- str_remove(file, ".zip")
  print(county)
  
  unzip(
    zipfile = paste0(root_path, file),
    exdir = paste0(root_path, county)
  )
  
  csv_file <- list.files(
    path = paste0(root_path, county),
    pattern = "\\.csv"
  )
  
  csv_file_name <- paste0(root_path, county, "/", csv_file)
  
  df <- read.csv(csv_file_name, fileEncoding="latin1") %>% 
    select(
      county = County,
      date = Report.Date,
      hi = Value
    ) 
  
  county_check <- df$county %>% 
    unique() %>% 
    str_remove(" ") %>% 
    tolower()
  
  if (county != county_check) {
    "ERROR!"
  }
  
  df_all <- rbind(df_all, df)
}


df_all_ <- df_all %>% 
  mutate(
    county = str_remove_all(toupper(county), " "),
    date = ymd(date),
    hi = as.numeric(str_remove(value, "°F"))
  ) %>% 
  mutate(
    year = year(date),
    month = month(date),
    day = day(date)
  ) %>% 
  filter(year >= 1981 & year <= 2022) 

# Get 1981-2010 daily heat index 95th percentile for each county
normals_1981_2010_pctl_95 <- df_all_ %>% 
  filter(year >= 1981 & year <= 2010) %>% 
  group_by(county, month, day) %>% 
  mutate(
    hi_cdc_pctl_95 = quantile(hi, probs = 0.95, na.rm = T)
  ) %>% 
  select(county, month, day, hi_cdc_pctl_95) %>%
  distinct() 

# Merge 2013-2022 data with all these data above to define heat event days
heat_event_2013_2022 <- df_all_ %>% 
  filter(year >= 2013) %>% 
  full_join(
    normals_1981_2010_pctl_95,
    by = c("county", "month", "day")
  ) %>% 
  mutate(
    is_heat_event_hi_cdc_1981_2010 = ifelse(hi >= hi_cdc_pctl_95, T, F),
  ) %>% 
  rename(
    hi_cdc = hi
  )

# write as CSV
# heat_event_2013_2022 %>%
#   write.csv(
#     "data/output/daily_heat_event_cdc_2013_2022.csv",
#     row.names = F
#   )
