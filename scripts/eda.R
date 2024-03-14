library(tidyverse)
library(readxl)
library(lubridate)

el_paso <- read_excel("data/raw/el-paso.xlsx", na = "N/A") %>% 
  filter(!is.na(`Name:`))



el_paso <- el_paso %>% 
  mutate(date = ymd(date)) %>% 
  mutate(
    race = NA,
    gender = NA,
    county = "El Paso"
  )

harris <- read.csv("data/raw/harris.csv") %>% 
  select(
    name = Name,
    age = Age,
    race = Race,
    gender = Gender,
    date = DOD
  ) %>% 
  mutate(
    date = mdy(date),
    county = "Harris"
  )

dallas <- read_excel("data/raw/dallas.xlsx") %>% 
  select(2, 3, 5, 6, 7) 
colnames(dallas) <- c("name", "age", "gender", "race", "date")
dallas <- dallas %>% 
  filter(!is.na(name)) %>% 
  tail(-1) %>% 
  mutate(
    age = ifelse(str_detect(age, "years"), as.numeric(str_remove(age, " years")), 0),
    gender = str_sub(gender, end = 1),
    date = mdy(date),
    county = "Dallas"
  ) 

tarrant <- read_excel("data/raw/tarrant.xlsx") %>% 
  mutate(
    name = paste(FirstName, LastName),
    date = ymd(str_sub(DateOfDeath, end = 10)),
    age = as.numeric(AgeAtDeath),
    race = Race,
    gender = Sex,
    county = "Tarrant"
  ) %>% 
  select(name:county)

df <- rbind(el_paso, harris) %>% 
  rbind(dallas) %>% 
  rbind(tarrant)

df %>% 
  ggplot(aes(x = age)) +
  geom_histogram(color = "white", binwidth = 3) + 
  facet_wrap(~county, ncol = 1) +
  labs(
    title = "Age distribution of people who died of heat in Dallas, El Paso, Harris and Tarrant counties",
    x = "Age", y = ""
  ) +
  theme_minimal()

df %>% 
  ggplot(aes(x = date)) +
  geom_histogram(color = "white") + 
  facet_wrap(~county, ncol = 1) +
  labs(
    title = "DOD distribution of people who died of heat in Dallas, El Paso, Harris and Tarrant counties",
    x = "Date", y = ""
  ) +
  theme_minimal()

df %>% 
  filter(!is.na(race)) %>% 
  ggplot(aes(x = race)) +
  geom_histogram(stat = "count") +
  facet_wrap(~county, ncol = 1) +
  labs(
    title = "Racial breakdown of heat deaths in Dallas, Harris and Tarrant counties",
    x = "", y = ""
  ) +
  theme_minimal()

df %>% 
  filter(!is.na(gender)) %>% 
  ggplot(aes(x = gender)) +
  geom_histogram(stat = "count", binwidth = 5) +
  facet_wrap(~county, ncol = 1) +
  labs(
    title = "Gender breakdown of heat deaths in Dallas, Harris and Tarrant counties",
    x = "", y = ""
  ) +
  theme_minimal()

df %>% 
  group_by(county) %>% 
  summarize(total = n())

dshs <- read.csv("data/dshs.csv") %>% 
  filter(!is.na(year)) %>% 
  select(year, deaths, summer_temp) %>% 
  mutate(
    century_avg = 81.3,
    diff = summer_temp - century_avg
  ) 

dshs %>% 
  ggplot(aes(x = year, y = summer_temp)) +
  geom_line(color = "lightgray") +
  geom_point(aes(color = summer_temp), size = 3) +
  scale_color_gradientn(
    limits = c(78, 87),
    colors = c("white", "#C74900")
  ) +
  theme_minimal() +
  labs(x = "", y = "") +
  theme(legend.position = "none")

ggsave("mockup/statewide-temp.svg")

dshs %>% 
  ggplot(aes(x = year, y = deaths)) +
  geom_bar(stat = "identity", aes(fill = diff)) +
  scale_fill_gradientn(
    limits = c(-5.5, 5.5),
    colors = c("blue", "white", "red")
  ) +
  labs(x = "", y = "") +
  theme_minimal()

dshs %>% 
  ggplot(aes(x = year, y = deaths)) +
  geom_bar(stat = "identity", fill = "lightgray") +
  labs(x = "", y = "") +
  theme_minimal()

ggsave("mockup/statewide-deaths.svg")
