source("grid\\function_hex_grid.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                        host = "localhost",
                        port = 5432,
                        user = "postgres",
                        password = "postgres",
                        dbname = "urmo")


grids <- c(500, 1000, 2000, 4000)

for(grid in grids){
  hexgrid(con, grid, "urmo", "plr", "the_geom", "grid", paste("hex_", grid, sep="")) 
}