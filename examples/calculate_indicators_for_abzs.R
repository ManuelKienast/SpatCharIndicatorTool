#source("indicator\\qntfyLines.R")
source("indicator\\qntfy_lines_clean_osm_bike.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")






qntfyLinesBike(con,'public.abz_network_ind', "urmo.abz", "abz_id" , "the_geom", "osm.berlin_network", "osm_type", "shape")



#for(grid_size in grids){
qntfyLinesBike(con, 'public.abz_network_bike_ind', "urmo.abz", "abz_id" , "the_geom", "osm.berlin_network", "bikeusage", "shape")
#}
