format_county_census <- function(county_raw) {
  county <- str_remove(county_raw, " County, Texas") %>% 
    str_remove_all("\\.") %>% 
    toupper()
  
  return(county)
}
