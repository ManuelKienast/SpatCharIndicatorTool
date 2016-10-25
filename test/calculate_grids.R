source("grid\\function_hex_grid.R")
library(RPostgreSQL)
con <- dbConnect(dbDriver("PostgreSQL"),
                        host = "localhost",
                        port = 5432,
                        user = "postgres",
                        password = "postgres",
                        dbname = "urmo")


grids <- c(8000, 4000, 2000, 1000, 500)

for(grid in grids){
  hexgrid(con, grid, "urmo", "plr", "the_geom", "grid", paste("hex_", grid, sep="")) 
}