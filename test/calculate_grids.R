source("grid\\function_hex_grid.R")
source("grid\\function_fishnet.R")
library(RPostgreSQL)
con <- dbConnect(dbDriver("PostgreSQL"),
                        host = "localhost",
                        port = 5432,
                        user = "postgres",
                        password = "postgres",
                        dbname = "urmo")


## Gridsizes in meter
grids <- c(8000, 4000, 2000, 1000, 500)


## HExGrids
for(grid in grids){
  hexgrid(con, grid, "urmo", "plr", "the_geom", "grid", paste("hex_", grid, sep="")) 
}


## FishNet
for(grid in grids){
  fishnet(con, grid, grid, "urmo", "plr", "the_geom", "grids", paste("Fish_", grid, sep="")) 
}