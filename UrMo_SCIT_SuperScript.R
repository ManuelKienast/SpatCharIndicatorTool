## SuperScript calling on all other functions of the UrMo-SpatCharIndicatorTool


## Set Up, working directory needs to contain all the scripts of SCIT
setwd("d:\\Manuel\\git\\Urmo-SpatCharIndicatorTool")
library(RPostgreSQL)
library(rgdal)
library(RODBC)

## loading all Functions from the SCIT
source("_Function_CountPointsinPolygon.R")  ##  psqlAvMean()
source("_Function_PlaygrounArea.R")
source("_Function_Statistic_Ratios.R")
source("function_categorize.R")
source("function_count.R")
source("function_density.R")
source("function_entropy.R")
source("function_fishnet.R")
source("function_hex_grid.R")
source("function_landuse.R")


## Creating the db connection
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "DLR", host = "localhost", port= "5432", user = "postgres", password = "postgres") 
dbListTables(con)



PlayArea()
psqlAvMean()


