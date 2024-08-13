# Excess heat deaths analysis

By [Yuriko Schumacher](https://www.texastribune.org/about/staff/yuriko-schumacher/) and [Angela Voit](https://www.texastribune.org/about/staff/angela-voit/)

This document explains our statistical analysis that aims to estimate the excess number of people who died in Texas on the days that were significantly hotter than normal. The analysis examined data between 2013 and 2019 and uses death indexes and heat index data.

The Texas Tribune reported on the official heat-related death tolls from the state's health department (DSHS) in [2022](https://www.texastribune.org/2023/01/26/texas-heat-deaths-migrants-climate-change/) and [2023](https://www.texastribune.org/2024/01/12/texas-heat-deaths-2023-record-climate-change/) although we've repeatedly reported their numbers are "likely a dramatic undercount".

In short, this analysis aims to estimate excess deaths on what we define as “heat-event” days in the state’s 41 largest counties between April and September in the years we examined. This allows us to compare our estimates with DSHS' official tally and show undercounts. Those counties cover about 85% of the state’s population.

The analysis is inspired by and mostly follows [an analysis conducted by the Los Angeles Times](https://github.com/datadesk/extreme-heat-excess-deaths-analysis) in 2021 for [this story](https://www.latimes.com/projects/california-extreme-heat-deaths-show-climate-change-risks/). 

Excess deaths are calculated as actual deaths minus predicted deaths. We defined days as “heat-event” days if the maximum heat index was in the top 10% of the heat indexes recorded on that day at that location during 1980-2010. Based on this, we built a model predicting death counts if the day had not been a heat-event day and compared those to actual deaths reported by the state. We then calculated the difference between predicted and actual deaths. We limited this analysis to April through September.

This analysis involved building a statistical model and controls for:
1. years, because death rates naturally increase as the population ages
2. months
3. weekends, when fewer death certificates may be submitted
4. population increases over time.

## What we did differently from the LA Times
### Meteorological data
We are using daily maximum heat indexes for this analysis instead of daily maximum air temperatures. We decided to use heat indexes after hearing from multiple experts that higher humidity increases the risk of health problems. [Other similar studies](https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2792389) have used heat indexes too.
### Heat-event days
We defined a heat event day using the 90th percentile threshold (top 10%), instead of the 95th percentile (top 5%) used by the LA Times. To find the most appropriate percentile cutline, we conducted an exploratory data analysis looking into mortality trends and maximum heat index distribution.This found mortality generally increases as maximum heat index rises, but it went down on the hottest days in some counties. We believe this is because on the hottest days, there may be more people staying inside and avoiding activities outside that are sources of risk. We suspect many of the excess deaths occur on days that are a little cooler but still dangerously hot. Andrew Dessler, professor of atmospheric sciences at Texas A&M University, reviewed our analysis and noted that “most deaths are occurring on days that are not the *hottest*, but still very hot.” He said this could represent “behavioral changes, not that hot temperatures are not dangerous.”
### Study months
The months used in the study are chosen partly based on CDC's  definition of [summer months](https://ephtracking.cdc.gov/Applications/heatTracker/): May through September. We then added April to our study months to cover half of the year (the same length as the LA Times). We added April instead of October because [many studies](https://journals.ametsoc.org/configurable/content/journals$002fwcas$002f13$002f1$002fwcas-d-20-0083.1.xml?t:ac=journals%24002fwcas%24002f13%24002f1%24002fwcas-d-20-0083.1.xml) have shown that heat earlier in the summer has larger negative health impacts than later in the summer.
### Counties
We are including the 41 counties in Texas where the population exceeded 100,000 in the 2020 Census. We needed to exclude smaller counties from this analysis because there was not enough data to build a robust model and make estimates. We set the threshold to 100,000 people because it’s a round number that covers about 85% of the state's population. Because this is such a high percentage, we feel we can compare this data with the  statewide death numbers provided by DSHS.
### Mass shooting deaths
After conducting an initial analysis, we noticed an unusual spike in the number of excess deaths in some counties on some days. We then found that these deaths happened on days and in places where mass shootings happened. To account for this, we subtracted the number of people who died from mass shootings from the total number of deaths in those counties.

## Results
In these 41 counties, we estimate **998** excess deaths on “heat-event” days during summer months between 2013 and 2019. That’s **221** more than the official number of deaths recorded where heat was the direct or contributing cause of death. 

- Total deaths with heat as a direct or contributing cause: **777**
- Total excess heat deaths, according to our analysis: **998**

The results come with wide margins of error and have a lot of uncertainty. Total estimated excess deaths could range from -3,797 to 5,521. [Ariel Karlinsky](https://akarlinsky.github.io/), an economist and statistician at Hebrew University, thinks this is because of the relatively small number of excess deaths compared to all deaths.

## Challenges
This analysis helped us calculate the number of deaths attributable to heat, but also has its limitations. First, the mortality data we used includes deaths by any cause, except [mass shooting deaths](https://apps.texastribune.org/features/2019/texas-10-years-of-mass-shootings-timeline/). We subtracted those after seeing unusual spikes in deaths in counties on days when a mass shooting happened. But it is difficult to control for every factor, which could result in overcounts in our estimates.

For a similar reason, we excluded 2020, 2021 and 2022 from this analysis because of a high number of excess deaths caused by the COVID-19 pandemic. (The 2023 mortality data was not yet available at the time of this analysis.)

Additionally, the model only accounts for deaths on the days where the heat index was abnormally high — even though in some cases heat victims die days or weeks after heat exposure. This would contribute to undercounts in our estimates. 

The findings are consistent with other parts of our reporting and previous research suggesting excess deaths increase as heat rises.

## Data sources
### Heat-related deaths count
Data was requested from the Texas Department of State Health Services. According to DSHS, the heat-related death counts include records with ICD-10 codes X30 (hyperthermia), T67 (effects of heat and light) and P81.0 (hyperthermia for newborn babies). They exclude any deaths where W92 (exposure to man-made heat) is listed anywhere in the death certificate.

### Death indexes
Data is from the [Texas Department of State Health Services Vital Statistics](https://www.dshs.texas.gov/vital-statistics/death-records/birth-death-indexes). Data includes descendant's 1) name, 2) date of death, 3) county of death by occurrence, and 4) sex. At the time of this analysis, the data were only available up to 2022. According to the state, the 2023 data will not be available until early 2025 because "records can still be filed."

### Population data
We offset the model by annual population estimates. Data was from the U.S. Census, [2013-2019](https://www.census.gov/data/datasets/time-series/demo/popest/2010s-counties-total.html), [2020-2022](https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-total.html).

### Heat indexes
Daily estimates of maximum heat indexes were provided by [CDC's Heat & Health Tracker](https://ephtracking.cdc.gov/Applications/heatTracker/). The data is calculated using air temperature and humidity. It was collected at the gridded level and summarized to the county level. More information about the data is [here](https://ephtracking.cdc.gov/indicatorPages?selectedContentAreaAbbreviation=35&selectedIndicatorId=97). More about heat indexes is [here](https://www.weather.gov/ama/heatindex).

### Mass shooting deaths
Data was compiled by the [Tribune](https://apps.texastribune.org/features/2019/texas-10-years-of-mass-shootings-timeline/).

This analysis was conducted with guidance from Karlinsky and was reviewed by Dessler.

This project was originally pitched by former Tribune climate reporter [Erin Douglas](https://www.bostonglobe.com/about/staff-list/staff/erin-douglas/), who is now a climate reporter for The Boston Globe.