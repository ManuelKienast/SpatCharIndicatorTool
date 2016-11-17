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
##
##                   area    <- c(0_125_km2, 0_5_km2, 2_km2, 8_km2)
## for hex_grids:    hexgrid <- c(408, 816, 1633, 3266)
## for fish_grids:  fishgrid <- c(354, 707, 1414, 2828)



#### Equal width
## Gridwidth in meter
grids <- c("4000", "2000", "1000", "500")


## HExGrids
for(grid in grids){
  hexgrid(con, grid, "urmo", "plr", "the_geom", "grid", paste("hex_", grid, sep="")) 
}


## FishNet
for(grid in grids){
  fishnet(con, grid, grid, "urmo", "plr", "the_geom", "grids", paste("Fish_", grid, sep="")) 
}


##### Equal Area
## grid area, gridwidth for hex and fishgrids, respectively
area    <- c("a_0_125_km2", "a_0_5_km2", "a_2_km2", "a_8_km2")
hexgrids <- c(408, 816, 1633, 3266)
fishgrids <- c(354, 707, 1414, 2828)


## HExGrids
for(i in seq_along(hexgrids)){
  hexgrid(con, hexgrids[i], "urmo", "plr", "the_geom", "grids", paste("hex_", area[i], sep="")) 
}

## FishNet
for(i in seq_along(fishgrid)){
  fishnet(con, fishgrid[i], fishgrid[i], "urmo", "plr", "the_geom", "grids", paste("Fish_", area[i], sep="")) 
}

