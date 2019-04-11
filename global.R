# Create static variables for the Transportation Provider Shiny App. Any fields that are either directly, or 
# indirectly dependent on configurable inputs will be created within the server.R file
library(data.table); library(truncnorm); library(shiny)

rm(staticDf)
# Assign unique town names
townNames <- c("DOWNTOWN","DEEP_ELLUM","UPTOWN","ADDISON","ARLINGTON")

# Assign average loaded miles per trip for each town 
avgTownMiles <- c(8, 14, 12, 18, 22)

# Assign average deviation away from average mph across the entire population  
townMphFactor <- c(0.84, 0.91, 0.88, 1.04, 1.11)

# Assign time factor for each town +/- some random noise
townDf <- data.table(town = townNames,
                     town_mph_factor = townMphFactor,
                     avg_town_miles = avgTownMiles)

# Create data set of unique IDs and randomly assigned Town Names
staticDf <- data.table(id = seq(1, 10000, by=1),
                       town = sample(townNames, 10000, replace = TRUE),
                       num_customers = sample.int(2, 10000, replace=TRUE, prob=c(0.7, 0.3)),
                       specialty_equipment = rbinom(10000, size=1, prob = 0.3),
                       avg_mpg = 23)


staticDf <- merge(staticDf, townDf, by="town", all.x=TRUE)

# Assign average input variables 
fuelCostPerGallon <- 3.5
avgMph <- 45

# Assign factor multipliers to create noise in the data to help simulate real world data
townMileNoise <- rtruncnorm(n=10000, a=0.80, b=1.20, mean=0.90, sd=1)
townMphNoise <- rtruncnorm(n=10000, a=0.80, b=1.20, mean=1.10, sd=1)
addtl_trip_noise <- rtruncnorm(n=10000, a=-0.08, b=0.08, mean=-0.03, sd=1)
mpgNoise <- rtruncnorm(n=10000, a=-4, b=4, mean=0, sd=2)

staticDf$town_mph_factor <- round(staticDf$town_mph_factor*townMphNoise,2)
staticDf$loaded_miles <- ifelse(staticDf$num_customers==1, round(staticDf$avg_town_miles*townMileNoise,2),
                                round((staticDf$avg_town_miles*townMileNoise)+(staticDf$avg_town_miles*(0.33+addtl_trip_noise)),2))
staticDf$loaded_time <- round((staticDf$loaded_miles/(avgMph*staticDf$town_mph_factor)*60), 2)
staticDf$avg_mpg <- ifelse(staticDf$specialty_equipment==0, staticDf$avg_mpg,
                           round(0.95*staticDf$avg_mpg))
staticDf$fuel_cost <- round((staticDf$loaded_miles/(staticDf$avg_mpg+mpgNoise))*fuelCostPerGallon, 2)


# Order data frame by unique id
staticDf <- staticDf[order(staticDf$id, decreasing = FALSE),c("id","town","num_customers","loaded_miles","loaded_time","specialty_equipment","fuel_cost")]
