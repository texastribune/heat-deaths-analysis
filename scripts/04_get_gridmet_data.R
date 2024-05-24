# This script will get data from gridMET (https://www.climatologylab.org/gridmet.html) and clean data.

# Libraries
library(tidyverse)
library(lubridate)
# package to download gridMET data
# documentation: https://mikejohnson51.github.io/climateR/index.html
# remotes::install_github("mikejohnson51/AOI")
# remotes::install_github("mikejohnson51/climateR")
library(AOI)
library(climateR)
library(sf)

# source
source("scripts/00_utils.R")

# Using CRS NAD 83
crs <- 4269

##################################################
########## Prepare county location data ##########
##################################################

# Centers of population data
# Following the methodology by the LA Times, using the location for centers of population by US Census (https://www.census.gov/geographies/reference-files/time-series/geo/centers-population.html)
cenpop <- read.table("data/mapdata/cenpop2020.txt", header = T, sep = ",") %>% 
  select(
    lat = LATITUDE,
    lon = LONGITUDE,
    county = COUNAME,
    fips = COUNTYFP
  ) 

# Get simple feature collection that will be used as an AOI (area of interest) to get gridMET data
points <- st_as_sf(
  cenpop,
  coords = c("lon", "lat"),
  crs = crs
)

##################################################
############ Get data for each county ############
##################################################

# Going to get daily data between these years
years <- c(1981:2022)

# Data variable abbreviations, used for direct download (https://www.northwestknowledge.net/metdata/data/)
  # Here is the list of variable abbreviations:
  # sph: (Near-Surface Specific Humidity)
  # vpd: (Mean Vapor Pressure Deficit)
  # pr: (Precipitation)
  # rmin: (Minimum Near-Surface Relative Humidity)
  # rmax: (Maximum Near-Surface Relative Humidity)
  # srad: (Surface Downwelling Solar Radiation)
  # tmmn: (Minimum Near-Surface Air Temperature)
  # tmmx: (Maximum Near-Surface Air Temperature)
  # vs: (Wind speed at 10 m)
  # th: (Wind direction at 10 m)
  # pdsi: (Palmer Drought Severity Index)
  # pet: (Reference grass evaportranspiration)
  # etr: (Reference alfalfa evaportranspiration)
  # erc: (model-G)
  # bi: (model-G)
  # fm100: (100-hour dead fuel moisture)
  # fm1000: (1000-hour dead fuel moisture)
types <- c(
  "tmmx", # Maximum Near-Surface Air Temperature
  "rmin" # Minimum Near-Surface Relative Humidity)
)

# LOOP STARTS HERE
for(year in years) {
  print(paste0("Starting ", year, "..."))
  
  # Empty data frame to add data to
  output_df <- data.frame()
  
  for(type in types) {
    
    # Get data
    data <- getGridMET(
      AOI = points,
      varname = type,
      startDate = paste0(year, "-01-01"),
      endDate = paste0(year, "-12-31"),
    )
    
    # Default extract function spits out data in a wide format
    wide <- extract_sites(
      r = data,
      pts = points,
      ID = "county"
    ) 
    
    # Make it long and add value type as a column
    long <- wide %>% 
      pivot_longer(
        cols = -date,
        names_to = "county",
        values_to = "value"
      ) %>% 
      mutate(
        type = type
      )
    
    # Push and store data in the empty data frame
    output_df <- rbind(output_df, long)
    
  }
  
  # Save as CSV
  output_df %>% write.csv(
    paste0("data/gridmet/", year, ".csv"),
    row.names = F
  )
  
  print(paste0(year, " done!"))
}
