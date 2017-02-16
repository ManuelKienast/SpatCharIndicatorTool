#source("indicator\\qntfyLines.R")
source("indicator\\osmIndicators.R")
source("indicator\\qntfyLines_forCleanOSM_Bike.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "129.247.28.69",
                 port = 5432,
                 user = "admin",
                 password = "Urb4n3M0bi1it%t",
                 dbname = "urmo")






#qntfyLinesBike(con,'tvz_network_ind', "urmo.tvz", "tvz_id" , "the_geom", "osm.berlin_network", "osm_type", "shape")

#modeVector <- c('mode_bike', 'mode_mit', 'mode_walk', 'mode_pt')

# for(mode in modeVector){
#   suffix <- strsplit(mode,"_")[[1]][2]
#   print(suffix)
#   calculateHighwayPercentages(con, sprintf('net.berlin_net_iv_visum_%s',suffix), "urmo.sg", "sg_id" , "the_geom", "net.net.berlin_net_all_visum_170111", mode, "the_geom")
#   dbGetQuery(con, sprintf("DROP TABLE net.berlin_net_iv_visum_%s_intersec", suffix))
#   dbGetQuery(con, sprintf("ALTER TABLE net.berlin_net_iv_visum_%s_%s RENAME ratio_true TO ratio_%s_osm", suffix, suffix))
#   
#   
# }
#data <- dbGetQuery(con, sprintf("""SELECT ratio_bike_osm, ratio_mit_osm, ratio_walk_osm, ratio_pt_osm FROM public.sg_network_bike, public.sg_network_walk, public.sg_network_mit, public.sg_network_pt WHERE public.sg_network_bike.key==public.sg_network_walk.key==public.sg_network_pt.key==public.sg_network_bike.mit"""))
calculateHighwayPercentages(con, 'tvz_network_ind_navteq2012q2', "urmo.tvz", "tvz_id" , "the_geom", "net.berlin_net_all_navteq2012q2_161221", "street_type", "the_geom")
