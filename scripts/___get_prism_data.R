# This script gets data from the Oregon State PRISM project (https://prism.nacse.org/). Trying to get daily, by county temperature / dew point data between 2013-2022.

# Libraries
library(tidyverse)
library(lubridate)
library(googlesheets4)
library(prism)
# https://github.com/ropensci/prism

# source
source("scripts/00_utils.R")

# Set the download directory
prism_set_dl_dir("data/prism")

get_prism_normals("tmean", "4km", annual = TRUE, keepZip = FALSE)
pd_to_file("PRISM_tmean_30yr_normal_4kmM5_annual_bil")

# Clean average grid point for each county
# Using QGIS, I joined prism 4k polygon mesh (https://prism.oregonstate.edu/downloads/) and Texas county boundaries (https://gis-txdot.opendata.arcgis.com/datasets/TXDOT::texas-county-boundaries-detailed/explore?location=30.834886%2C-100.077018%2C6.28), and calculated average latitude and longitude of all grid points within the county perimeters.
grid_raw <- read.csv("data/mapdata/avg_grid_point.csv")
grid <- grid_raw %>%
  distinct()
prism_location <- grid %>% 
  select(lat = avg_lat, lon = avg_lon, county = CNTY_NM)
prism_location %>% 
  write.table("data/prism_location.csv", sep = ",", row.names = F, col.names = F)

# Centers of population data
# Following the methodology by the LA Times, using the location for centers of population by US Census (https://www.census.gov/geographies/reference-files/time-series/geo/centers-population.html)
cenpop <- read.table("data/mapdata/cenpop2020.txt", header = T, sep = ",")
cenpop %>% 
  select(
    lat = LATITUDE,
    lon = LONGITUDE,
    county = COUNAME
  ) %>% 
  write.table("data/prism_location.csv", sep = ",", row.names = F, col.names = F)

# Downloaded tmax, tmin, tmean, tdmean data and 30-year daily normals (1991-2020) using PRISM data download system (https://prism.oregonstate.edu/explorer/bulk.php)