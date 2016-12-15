##
##  CONNECTIONS
##

library(RPostgreSQL)
library(rgdal)
library(RODBC)

# # FOR LOCAL USE
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "urmo_locale", host = "localhost", port= "5432", user = "postgres", password = "postgres")
connection <- con
dbListTables(con)


## FOR USAGE ON server-db
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "[name]", host = "[server.ip]", port= "[port.#]", user = "[name]", password = "[pw]") 
dbListTables(con)


## Close All existing connections
dbDisconnect(con)
