# Excess heat deaths analysis
This repository includes data and code used for a statistical analysis which aims to estimate the number of people who died of heat between 2018 and 2022, using death indexes data and heat index data.

The analysis is inspired by and mostly follows [an analysis conducted by the Los Angeles Times](https://github.com/datadesk/extreme-heat-excess-deaths-analysis) in 2021 for [this story](https://www.latimes.com/projects/california-extreme-heat-deaths-show-climate-change-risks/).

This analysis was conducted with guidance from [Ariel Karlinsky](https://akarlinsky.github.io/), an economist and statistician at Hebrew University, [Ebrahim Eslami](https://harcresearch.org/people/ebrahim-eslami-phd/), a research scientist at HARC, and Texas State Climatologist [John Nielsen-Gammon](https://atmo.tamu.edu/people/profiles/faculty/nielsen-gammonjohn.html).

Since this analysis involves building a statistical model, most of it was conducted using a computational language `R`.

## Data sources:
- **Death indexes**:
  - [Texas Department of State Health Services Vital Statistics](https://www.dshs.texas.gov/vital-statistics/death-records/birth-death-indexes)
- **Heat indexes**: 
  - Daily maximum heat indexes were calculated by using daily maximum temperature and daily minimum relative humidity, obtained from [gridMET](https://www.climatologylab.org/gridmet.html), a gridded surface meteorological dataset, using an R package [climateR](https://github.com/mikejohnson51/climateR).
  - Data provided by [gridMET](https://www.climatologylab.org/gridmet.html) is gridded for ~4km resolution. To obtain data representative for each county, the grids were centered the [2020 Centers of Population](https://www.census.gov/geographies/reference-files/time-series/geo/centers-population.html) by the U.S. Census.