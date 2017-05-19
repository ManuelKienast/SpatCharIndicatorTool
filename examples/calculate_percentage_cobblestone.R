source("indicator\\osmIndicators.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "129.247.28.69",
                 port = 5432,
                 user = "urmo",
                 password = "urmo",
                 dbname = "urmo")
#for(grid_size in grids){
calculateHighwayPercentages(con, 'veu_survey.berlin_adressen_2016_survey_buffer1km_cobblestone', "veu_survey.berlin_adressen_2016_survey_buffer1km", "ga_id" , "geom", "veu_survey.berlin_cobblestone_ways", "osm_tag", "the_geom")
#}