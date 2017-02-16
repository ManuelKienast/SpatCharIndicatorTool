#source("indicator\\qntfyLines.R")
source("indicator\\osmIndicators.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")






#qntfyLinesBike(con,'tvz_network_ind', "urmo.tvz", "tvz_id" , "the_geom", "osm.berlin_network", "osm_type", "shape")

# modeVector <- c('mode_bike', 'mode_mit', 'mode_walk', 'mode_pt')
# 
# for(mode in modeVector){
#   suffix <- strsplit(mode,"_")[[1]][2]
#   print(suffix)
#   calculateHighwayPercentages(con, sprintf('sg_network_%s',suffix), "urmo.sg", "sg_id" , "the_geom", "osm.test_network", mode, "the_geom")
#   dbGetQuery(con, sprintf("DROP TABLE sg_network_%s_intersec", suffix))
#   dbGetQuery(con, sprintf("ALTER TABLE sg_network_%s RENAME ratio_true TO ratio_%s_osm", suffix, suffix))
#   
#   
#   }
#data <- dbGetQuery(con, sprintf("""SELECT ratio_bike_osm, ratio_mit_osm, ratio_walk_osm, ratio_pt_osm FROM public.sg_network_bike, public.sg_network_walk, public.sg_network_mit, public.sg_network_pt WHERE public.sg_network_bike.key==public.sg_network_walk.key==public.sg_network_pt.key==public.sg_network_bike.mit"""))
calculateHighwayPercentages(con, 'sg_network_ind', "urmo.sg", "sg_id" , "the_geom", "osm.berlin_network", "street_type", "the_geom")
