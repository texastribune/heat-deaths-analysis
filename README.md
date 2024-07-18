# Excess heat deaths analysis
This repository includes data and code used for a statistical analysis which aims to estimate the number of people who died of heat between 2013 and 2019, using death indexes data and heat index data.

Texas Tribune has reported official heat-related deaths tolls counted by the state's health department (DSHS) in [2022](https://www.texastribune.org/2023/01/26/texas-heat-deaths-migrants-climate-change/) and [2023](https://www.texastribune.org/2024/01/12/texas-heat-deaths-2023-record-climate-change/) although we've repeatedly reported data is "likely a dramatic undercount".

In short, this analysis aims to estimate the excess deaths on extreme heat days in 41 largest counties in Texas between April and September from 2013 and 2019, so that we can compare our estimates with DSHS' official tally, showing undercounts, and hopefully holding officials accountable.

The analysis is hugely inspired by and mostly follows [an analysis conducted by the Los Angeles Times](https://github.com/datadesk/extreme-heat-excess-deaths-analysis) in 2021 for [this story](https://www.latimes.com/projects/california-extreme-heat-deaths-show-climate-change-risks/). 

We predict a 'normal' daily death count on a day in a county between 2013 and 2019, had it not been an extreme heat day. To build a model, we used daily death tolls and maximum heat index for each county.

The 41 counties included in this analysis had more than 100,000 people in the 2020 Census. We needed to exclude smaller counties from this analysis because there was simply not enough data to build a robust model and make an estimate. We set this 100,000 threshold because it would cover about 85% of the state's population.

Daily excess deaths are calculated as actual deaths minus estimated deaths. For each 2013-2019 daily maximum heat index estimate, we defined whether the day was an extreme heat day -- above the county's 95th percentile value of 1981-2010 maximum heat index distribution. And the model explains, for each county, actual deaths as a function of whether it was an extreme heat day, while also controlling for 1) a year (to account for deaths or even crude death rates to naturally increasing due to population aging), 2) a month and 3) whether it was in the weekend (since there may be fewer death certificate submissions), as well as accounting for 4) a population increase.

Although our results have margins of errors, by looking at the average of lower and upper end of the estimates, our estimates show more excess deaths on extreme heat days in five of the seven years of study. Our estimates in 2018 (93) is slightly lower than the official count (99), and there are 45 negative excess deaths in 2014 in our estimates.

## Presets:
- **Study months**: This analysis estimates the number of people who died of heat between April and September. These months are chosen because CDC's [Heat & Health Tracker](https://ephtracking.cdc.gov/Applications/heatTracker/) defines summer months as May to September; As an indicator about people's health status with respect to environmental factors, CDC has a [data category](https://ephtracking.cdc.gov/indicatorPages?selectedContentAreaAbbreviation=35&selectedIndicatorId=97) about *"Daily Estimates of Maximum Heat Index for Summer Months (May–September)"*. Based on this, we added April to our study months to make the study months as half a year (same as the LA Times). We added April instead of October because many studies have shown that heat in the earlier summer has a bigger health impact than later ([Sheridan et al. 2018](https://journals.ametsoc.org/configurable/content/journals$002fwcas$002f13$002f1$002fwcas-d-20-0083.1.xml?t:ac=journals%24002fwcas%24002f13%24002f1%24002fwcas-d-20-0083.1.xml)).
- **Extreme heat days**: Extreme heat days are defined by the county’s 95th percentile value of historical (1981–2010) maximum heat index distribution. This is following LAT's methodology and CDC's Heat & Health Tracker, as well as other similar studies.

## Data sources:
- **Heat-related deaths count**:
  - Via data request from Texas Department of State Health Services. DSHS only counts deaths with Underlying Cause-of-Death ICD-10 code X30 (hyperthermia) as an official tally of “heat-related deaths”. According to CDC (via Emily’s interview), in order to better count the heat-related deaths, the count should include records with X30 (hyperthermia), T67 (effects of heat and light) and P81.0  (hyperthermia for newborn babies), excluding W92 (exposure to manmade heat).

- **Death indexes**:
  - [Texas Department of State Health Services Vital Statistics](https://www.dshs.texas.gov/vital-statistics/death-records/birth-death-indexes). Data includes descendant's 1) name, 2) date of death, 3) county of death by occurrence, and 4) sex. At the time of this analysis, the data were only avaiable up to 2022. According to DSHS' vital statistics section, the 2023 data is not available until early 2025 because "records can still be filed".

- **Population data**:
  - We offset the model by annual population estimates. Data by U.S. Census, [2020-2022](https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-total.html).

- **Heat indexes**: 
  - Daily estimates of maximum heat indexes were also provided by [CDC's Heat & Health Tracker](https://ephtracking.cdc.gov/Applications/heatTracker/). The data is caluculated using air temperature and humidity at a gridded level and summarized to the county level. More about data [here](https://ephtracking.cdc.gov/indicatorPages?selectedContentAreaAbbreviation=35&selectedIndicatorId=97).

- **Mass shooting deaths**: 
  - After conducting an initial analysis, we found an abnormal number of excess deaths in some counties. We then identified these deaths happened on a day in a county where a mass shooting happened. In this analysis, we simply subtract the number of people who died from mass shootings. Data are compiled through [Tribune's analysis](https://apps.texastribune.org/features/2019/texas-10-years-of-mass-shootings-timeline/).

All data are uploaded [here](https://drive.google.com/drive/u/0/folders/1vCKHO1FFF2gddAbXLA9r1lOrOscSAWrN).

This analysis was conducted with guidance from [Ariel Karlinsky](https://akarlinsky.github.io/), an economist and statistician at Hebrew University, [Ebrahim Eslami](https://harcresearch.org/people/ebrahim-eslami-phd/), a research scientist at HARC, and Texas State Climatologist [John Nielsen-Gammon](https://atmo.tamu.edu/people/profiles/faculty/nielsen-gammonjohn.html).

This project was originally pitched by Tribune's former climate reporter [Erin Douglas](https://www.bostonglobe.com/about/staff-list/staff/erin-douglas/), who is now a climate reporte for The Boston Globe.

Since this analysis involves building a statistical model, most of it was conducted using a computational language `R`.