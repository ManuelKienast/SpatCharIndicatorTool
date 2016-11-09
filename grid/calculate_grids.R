source("grid\\function_hex_grid.R")
source("grid\\function_fishnet.R")
library(RPostgreSQL)
con <- dbConnect(dbDriver("PostgreSQL"),
                        host = "localhost",
                        port = 5432,
                        user = "postgres",
                        password = "postgres",
                        dbname = "urmo")


## Since grids computed with the same width are not equal in area (grid_fish A=w*w, yes those are squares;)|(grid_hex A=w*3/4w)
## these two vectors are proposed for nearly equal-area grids, with 
## area measurements of c(0.125 km², 0.5 km², 2 km², 8 km²)
## for hex_grids:       c(408.25, 816.5, 1633, 3266)
## for fish_grids:      C(353.55, 707.22, 1414.21, 2828.43)



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