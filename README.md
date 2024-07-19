## Analysis

### Directory & File Structure

#### data 
All data files.

#### scripts
All programming scripts, numbered in the order they are intended to be run. Any files containing "WIP" is a a work-in-progress not intended to be run. 

#### outputs
Any intermediate or final output from the analysis. 

#### extra

Any other additional files.

### Analytical Overview

-   Data visualization
-   Time Series Decomposition
    -   Seasonal Decomposition of Time Series by Loess (STL)
        -   Mann-Kendall test
    -   Seasonal Decomposition with Moving Average
    -   Exponential Smoothing State Space Model (ETS)

### Other Resources

[General Guide](https://hess.copernicus.org/articles/25/3937/2021/) (2001)

[Forecasting: princples and practice](https://otexts.com/fpp3/) (great book)

### Other R Packages

-   [Hydrology CRAN Task View](https://CRAN.R-project.org/view=Hydrology)
    -   [hydrostats](https://CRAN.R-project.org/package=hydrostat): Calculates a suite of hydrologic indices for daily time series data that are widely used in hydrology and stream ecology
    -   [hydroTSM](https://CRAN.R-project.org/package=hydroTSM): functions for management, analysis, interpolation and plotting of time series used in hydrology and related environmental sciences
    -   [FAdist](https://CRAN.R-project.org/package=FAdist): Distributions that are Sometimes Used in Hydrology (related: the [Extreme Value task view](https://CRAN.R-project.org/view=ExtremeValue))
    -   [EFlowStats](https://github.com/DOI-USGS/EflowStats): Calculates a suite of ecological flow statistics and fundamental properties of daily streamflow for a given set of data
-   [Environmetrics CRAN Task View](https://CRAN.R-project.org/view=Environmetrics)
    -   [strucchange](https://CRAN.R-project.org/package=strucchange), [dynlm](https://CRAN.R-project.org/package=dynlm), [dyn](https://CRAN.R-project.org/package=dyn), [Rbeast](https://CRAN.R-project.org/package=Rbeast): packages for linear modelling of time series and change point detection
-   [Time Series CRAN Task View](https://CRAN.R-project.org/view=TimeSeries)
-   [imputeTS](https://CRAN.R-project.org/package=imputeTS), [imputeTestbench](imputeTestBench): imputing missing data in a time series
-   [forecast](https://CRAN.R-project.org/package=forecast): standard forecasting (already being used)
-   [bfast](https://CRAN.R-project.org/package=bfast), [seas](https://CRAN.R-project.org/package=seas) and many other packaged for time series decompositin
-   [mvgam](https://CRAN.R-project.org/package=mvgam): multivariate general additive models
-   some deep learning forecasting models
-   many non-linear regression packages
