
source("indicator\\qntfyLines_forCleanOSM_Bike.R")

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
qntfyLinesBike(con, sprintf("berlin_hexgrid_%s_ind", 1000), "grid.hex_1000", "gid" , "the_geom", "osm.berlin_network", "street_type", "the_geom")

#for(grid_size in grids){
#  qntfyLinesBike(con, sprintf("osm.kopenhagen_hexgrid_%s_ind", grid_size), sprintf("grid.kopenhagen_hexgrid_%s",grid_size), "gid" , "the_geom", "osm.kopenhagen_network", "osm_type", "shape")
#}