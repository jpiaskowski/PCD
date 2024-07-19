
### Load libra5ries
  
# standard libraries
library(dplyr); library(tidyr); library(readr); library(ggplot2)

# date & time / time series libraries
library(lubridate)
library(imputeTS)


### Import data set and create some helper variables:  

streams <- read_csv(here::here("data/Alpowa_Deadman_Flow_Temp_2022.csv"), 
                    show_col_types = FALSE) |> 
  janitor::clean_names() |> 
  rename(date_ = "date") |> # rename header to 'date_' since 'date()' is a function
  mutate(missing = case_when(     # create new variable to indicate extent of missingness
    is.na(water_temp_c) ~ "missing",
    .default = NA_character_
  )) |> 
  mutate(year = year(date_), julian = as.numeric(format(date_, "%j"))) |> # new variables: Year, Julian days
  mutate(Year = as.character(year)) |> 
  mutate(improvement = case_when(    # add new variable for magic cut-off
    date_ < "2011-07-01" ~ "before", 
    date_ >= "2011-07-01" ~ "after"
  )) |> 
  dplyr::mutate(improvement = factor(improvement, levels = c("before", "after"))) |> 
  filter(date_ > "2003-06-30" & date_ < "2022-07-01") |> # filter to interval of interest
  slice(-(grep("02-29$", date_))) 


### Filter to individual streams:

deadman <- filter(streams, site == "Deadman Creek") |> 
  dplyr::arrange(date_) |> 
  mutate(index = 1:n())

alpowa <- filter(streams, site == "Alpowa Creek") |> 
  dplyr::arrange(date_) |> 
  mutate(index = 1:n())

### Make time series objects

# code  assumes data aree sorted by date
# 'start' is the first observation in the time series (position 1/row 1)
# 'frequency' is the length of time period (365 days)

alpowa_ts_temp <- ts(alpowa$water_temp_c, start = 1, frequency = 365) 
alpowa_ts_flow <- ts(alpowa$flow_cfs, start = 1, frequency = 365) 

deadman_ts_temp <- ts(deadman$water_temp_c, start = 1, frequency = 365) 
deadman_ts_flow <- ts(deadman$flow_cfs, start = 1, frequency = 365) 

# impute missing data

# We cannot have missing data in a time series object
# Check out functions from the package **ImputeTS** for options on imputatatio 
# note: do not try `algorithm = 'kalman'` unless you don't mind waiting awhile!

alpowa_ts_temp_imp <- na_seadec(alpowa_ts_temp, algorithm = "interpolation")
alpowa_ts_flow_imp <- na_seadec(alpowa_ts_flow, algorithm = "interpolation")

deadman_ts_temp_imp <- na_seadec(deadman_ts_temp, algorithm = "interpolation")
deadman_ts_flow_imp <- na_seadec(deadman_ts_flow, algorithm = "interpolation")

## Save all objects

save(alpowa, deadman, file = "outputs/prepped_stream_data.RData")

save(alpowa_ts_flow, alpowa_ts_temp, deadman_ts_flow, deadman_ts_temp,
     file = "outputs/time_series_obs.RData")

save(list = ls(pattern = "imp"), 
     file = "outputs/time_series_imputed_obs.RData")

