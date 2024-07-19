
# read in libraries and data
# standard libraries
library(dplyr); library(tidyr); library(readr); library(ggplot2); 
# time series libraries
library(lubridate)
library(forecast)
library(imputeTS)
library(fable)

# import full data set
streams <- read_csv("data/Alpowa_Deadman_Flow_Temp_2022.csv", show_col_types = FALSE) %>% 
  janitor::clean_names() %>% 
  rename(date_ = "date") %>% 
  mutate(missing = case_when(     # create new variable for downstream plotting
    is.na(water_temp_c) ~ "missing",
    .default = NA_character_
  )) %>% 
  mutate(year = year(date_), julian = as.numeric(format(date_, "%j"))) %>% 
  mutate(Year = as.character(year)) %>% 
  mutate(improvement = case_when(
    date_ < "2011-07-01" ~ "before", 
    date_ >= "2011-07-01" ~ "after"
  ))

### Alpowa Example

# filter to a single stream: 
alpowa <- filter(streams, site == "Alpowa Creek") %>% 
  filter(date_ > "2003-06-30" & date_ < "2022-07-01") %>% # filter to interval of interest
  slice(-(grep("02-29$", date_))) %>% # prep work for time series
  dplyr::arrange(date_)

# exploratory plots
# full time series
ggplot(alpowa, aes(x = date_, y = water_temp_c)) +
  geom_line(color = "turquoise3") +
  ylab("Water Temperature (°C)") +
  theme_minimal(base_size = 12) +
  ggtitle("Alpowa Creek") + 
  theme(axis.title.x = element_blank())

ggsave("outputs/Alpowa_temp.png", height = 975, width = 2625, units = "px")

# faceted by year
ggplot(alpowa, aes(x = julian, y = water_temp_c)) +
  geom_line(aes(color = improvement), linewidth = 0.75) +
  facet_grid(rows = vars(Year)) + 
  guides(color = "none") + 
  ylab("Water Temperature (°C)") +
  xlab("Julian Calendar Days") + 
  ggtitle("Alpowa Creek") + 
  scale_y_continuous(breaks=c(0, 10, 20)) +
  theme_gray(base_size = 11) 

ggsave("outputs/Alpowa_temp_stacked.png", height = 2850, width = 2025, units = "px")

# big chunk of missing data in 2016: May 23 - July 7

# visualize missing data:

ggplot_na_distribution(alpowa$water_temp_c)
ggplot_na_distribution2(alpowa$water_temp_c)
ggplot_na_gapsize(alpowa$water_temp_c)

# look at lagged interactions
# ACF
ggAcf(alpowa$water_temp_c) 
# PACF
ggPacf(alpowa$water_temp_c) 
# unclear what those dotted blue lines are confidence intervals
# and `calc.ci = FALSE` gives an error

# impute missing data (not sure this is an appropriate choice for this data set)

alpowa$water_temp_complete <- na_ma(alpowa$water_temp_c, k = 5, weighting = "exponential")
#better methods (e.g. na_seadec)
# check results
ggplot_na_distribution(alpowa$water_temp_complete)

ggplot(alpowa, aes(x = julian, y = water_temp_complete)) +
  geom_line(aes(color = improvement), linewidth = 0.75) +
  facet_grid(rows = vars(Year)) + 
  guides(color = "none") + 
  theme_classic()

# my own custom missing data plot
# alpowa %>% filter(date_ > "2011-06-30") %>% drop_na(missing) %>%
#   ggplot(., aes(x = date_, y = missing)) +
#     geom_segment(aes(xend = date_), yend = 0, color = "black", alpha = 0.5) +
#     geom_point(fill = "violetred", color = "black", size = 5, alpha = 0.3, shape = 21) +
#     theme_bw()

# big chunk of missing data in 2016

## time series decomposition

# make into a timeseries

alpowa_ts <- ts(alpowa$water_temp_complete, start = 1, frequency = 365) 
  # start is the numeric position where the start date occurs in its data column
  # since we filtered all previous data and sorted the data, it is position 1
  # frequency = 365 for days in the year. for this to work, dataset must have exactly 365 entries (so remove leap days and make sure each day is present even if data is NA) 

# other notes on time series objects
  # in time series objects, date is now an integer -- that is, days after January 1, 1970 
  # (this is how computers store dates for some reason)
  # run this to check: 
  # as.date(12204, origin = "1970-01-01") 
  # (that is the first day in the Alpowa time series) 
  # how to find that start date as an integer 
  # as.numeric(as.date("2011-06-30"))

# seasonal decomposition of time series by Loess

water_temp_stl <- stl(alpowa_ts, s.window = "periodic", t.window = 25, na.action = na.exclude, robust = TRUE)  
autoplot(water_temp_stl) #year 8 is when the cut-off begins

## ETS
# too many time points - need to collapse
alpowa$semimonth <- cut(alpowa$julian, breaks = 24, include.lowest = TRUE,
                        labels = paste0("biweek_", 1:24))

alpowa_semi <- alpowa %>% group_by(Year, semimonth) %>% 
  summarise(flow = mean(flow_cfs, na.rm = TRUE),
            water_temp = mean(water_temp_complete), 
            julian_days = mean(julian)) %>% 
  arrange(Year, semimonth) 

alpowa_ts24 <- ts(alpowa_semi$water_temp, start = 2, frequency = 24) # starts at '2' because an extra period is carried otherwise
  
ets_1 <- ets(alpowa_ts24, "ZZZ")
autoplot(ets_1)
            
            

Many options for the `model` argument (check the documentation). `model = "ZZZ"` allows for automatic selection. 

```{r}
#water_temp_ets <- ets(mydata_ts_h2o_imp, model = "ZZZ")
```

*(did not work - too many data points in each period)*
  
  ## Time Series with Aggregated data
  
  Aggregate the data into 24 equal-sized portions (as best as possible)
```{r}
mydata_agg <- mydata |> group_by(Year) |> 
  arrange(date_) |> 
  mutate(N = 1:n()) |> 
  mutate(grp = cut(N, breaks = 24, include.lowest = TRUE, 
                   labels = paste0("group_", 1:24))) |> 
  ungroup() |> 
  group_by(Year, grp) |> 
  mutate(flow = mean(flow_cfs, na.rm = TRUE), 
         water_temp = mean(water_temp_c, na.rm = TRUE)) |> 
  select(site, Year, grp, flow, water_temp, improvement) |> 
  distinct() |> ungroup() |> 
  filter(!(Year == "2011" & grp == "group_12" & improvement == "before")) |> 
  # filter out that one observation that bridges the time between before and after
  arrange(Year, grp) # order it in preparation to make a time series object
```

check missingness 


Make a time series object and impute
```{r}
mydata_ts_h2o_agg <- ts(mydata_agg$water_temp, start = 1, frequency = 24) 
mydata_ts_h2o_agg <- na_seadec(mydata_ts_h2o_agg, algorithm = "interpolation") 
```


### Times Series Decompositions on Aggregated Data

```{r}
water_temp_stl <- stl(mydata_ts_h2o_agg, 
                      s.window = "periodic", 
                      #t.window = 800,  
                      robust = TRUE)  
autoplot(water_temp_stl)  + #year 8 is when the cut-off begins
  geom_vline(xintercept = 8, color = "red")
```



```{r}
ets(mydata_ts_h2o_agg)  |> 
  autoplot()  
```

#### what is this???

```{r}
mydata$decompose_h2o <- mydata_dec_h2o$trend

boxplot(decompose_h2o ~ improvement, data = mydata)
#t.test(decompose_h2o ~ improvement, data = mydata)
```

#### Seasonal Decomposition with Moving Average

```{r}
alpowa_flow_sea <- decompose(alpowa_ts_flow_imp, type = "additive") 

autoplot(alpowa_flow_sea) +
  geom_vline(xintercept = 8, color = "red") +
  ggtitle("Seasonal Decomposition with moving average (additive)", "Alpowa stream flow") + 
  theme_bw() 
```

**Extract results and plot**
  
  ```{r}
alpowa$water_flow_sea <- seasadj(alpowa_flow_sea) 
alpowa$water_flow_sea_ma <- alpowa_flow_sea$trend
```

```{r message=FALSE, warning=FALSE}
ybar = alpowa |> filter(date_ == "2011-07-01") |> pull(water_flow_sea_ma)

ggplot(alpowa, aes(x = date_, y = water_flow_sea)) +
  geom_line(color = "gray35", alpha = 0.3) +
  geom_vline(xintercept = as.Date("2011-07-01"), col = "red2", linewidth = 0.75) + 
  geom_hline(yintercept = ybar, col = "black", linewidth = 1) + 
  geom_line(aes(y = water_flow_sea_ma), color = "cornflowerblue", linewidth = 1.5, alpha = 0.6) +
  geom_smooth(method = "lm", col = "blue", alpha = 0.6) + 
  ylab("Water Flow (CFS)") +
  ggtitle("Alpowa Creek", "Moving Average") + 
  theme_minimal(base_size = 12) +
  scale_y_continuous(trans='log10') +
  theme(axis.title.x = element_blank())
```

#### Seasonal Decomposition with Moving Average

```{r}
alpowa_temp_sea <- decompose(alpowa_ts_temp_imp, type = "additive") 

autoplot(alpowa_temp_sea) +
  geom_vline(xintercept = 8, color = "red") +
  ggtitle("Seasonal Decomposition with moving average (additive)", "Alpowa water temp") + 
  theme_bw() 
```

**Extract results and plot**
  
  ```{r}
alpowa$water_temp_sea <- seasadj(alpowa_temp_sea) 
alpowa$water_temp_sea_ma <- alpowa_temp_sea$trend
```

```{r message=FALSE, warning=FALSE}
ybar = alpowa |> filter(date_ == "2011-07-01") |> pull(water_temp_sea_ma)

ggplot(alpowa, aes(x = date_, y = water_temp_sea)) +
  geom_line(color = "gray35", alpha = 0.3) +
  geom_vline(xintercept = as.Date("2011-07-01"), col = "red2", linewidth = 0.75) + 
  geom_hline(yintercept = ybar, col = "black", linewidth = 1) + 
  geom_line(aes(y = water_temp_sea_ma), color = "cornflowerblue", linewidth = 1.5, alpha = 0.6) +
  geom_smooth(method = "lm", col = "blue", alpha = 0.6) + 
  ylab("Water Temperature (°C)") +
  ggtitle("Alpowa Creek", "Moving Average") + 
  theme_minimal(base_size = 12) +
  scale_y_continuous(trans='log10') +
  theme(axis.title.x = element_blank())
```

1. What about working with lagged data? 
  
  ```{r}
# daily differences
diffs_alpowa_temp <- diff(alpowa_ts_temp_imp, 1) 
# seasonal differences
diffs_alpowa_temp_seas <- diff(alpowa_ts_temp_imp, 365) 
# doubly diffed
diffs_alpowa_temp_both <- diff(diffs_alpowa_temp_seas, 1) 
```



KPSS test (to check for stationarity)

```{r}
nsdiffs(alpowa_ts_temp_imp) # number of seasons to establish st
urca::ur.kpss(diffs_alpowa_temp, type = "tau", lags = "short") # no
urca::ur.kpss(diffs_alpowa_temp_seas, type = "tau", lags = "short") # yes
urca::ur.kpss(diffs_alpowa_temp_both, type = "tau", lags = "short") # no
```

            