#source("indicator\\qntfyLines.R")
source("indicator\\qntfyLines_forCleanOSM_Bike.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")






#qntfyLinesBike(con,'tvz_network_ind', "urmo.tvz", "tvz_id" , "the_geom", "osm.berlin_network", "osm_type", "shape")



#for(grid_size in grids){
qntfyLinesBike(con, 'sg_network_bike_ind', "urmo.sg", "sg_id" , "the_geom", "osm.test_network", "mode_bike", "the_geom")
#}
