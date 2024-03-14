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
      year = year(date_of_death)
    ) %>% 
    select(name, sex, date_of_death, county_of_death, year) %>% 
    arrange(county_of_death) %>% 
    arrange(date_of_death) 

  return (df)
}

