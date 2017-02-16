#source("indicator\\qntfyLines.R")
source("indicator\\qntfyLines_forCleanOSM_Bike.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")



# closeOpenPSQLConnections <- function(){
#   
#   all_cons <- dbListConnections(PostgreSQL())
#   for(con in all_cons)
#     +  dbDisconnect(con) 
# }
# closeOpenPSQLConnections()

#qntfyLinesBike(con,'bz_network_ind', "urmo.bz", "bz_id" , "the_geom", "osm.berlin_network", "osm_type", "shape")



#for(grid_size in grids){
qntfyLinesBike(con, 'bz_network_bike_ind', "urmo.bz", "bz_id" , "the_geom", "osm.berlin_network", "bikeusage", "shape")
#}
