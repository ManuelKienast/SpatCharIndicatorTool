#source("indicator\\qntfyLines.R")
source("indicator\\osmIndicators.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")






#qntfyLinesBike(con,'tvz_network_ind', "urmo.tvz", "tvz_id" , "the_geom", "osm.berlin_network", "osm_type", "shape")



#for(grid_size in grids){
calculateHighwayPercentages(con, 'tvz_network_ind_osm', "urmo.tvz", "tvz_id" , "the_geom", "osm.berlin_network", "street_type", "the_geom")
#}
