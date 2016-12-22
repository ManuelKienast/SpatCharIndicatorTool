source("indicator\\qntfyLines.R")
source("indicator\\qntfyLinesBike.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")



grids <- c(500, 1000, 2000, 4000, 8000)

#for(grid_size in grids){
#  qntfyLines(con,sprintf("public.hex_%s_osm_ind", grid_size), sprintf("grid.hex_%s",grid_size), "gid" , "the_geom", "osm.berlin_network", "osm_type", "shape")
#}


for(grid_size in grids){
  qntfyLinesBike(con, sprintf("public.hex_%s_osm_ind", grid_size), sprintf("grid.hex_%s",grid_size), "gid" , "the_geom", "osm.berlin_network", "osm_type", "shape")
}