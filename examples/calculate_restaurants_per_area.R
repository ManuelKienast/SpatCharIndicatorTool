#source("indicator\\countPointsinPolygon.R")
source("indicator\\density.R")
con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "129.247.28.69",
                 port = 5432,
                 user = "urmo",
                 password = "urmo",
                 dbname = "urmo")


   
#dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_facilities_health", "veu_survey.berlin_num_health_1km" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "public.pla", "veu_survey.berlin_num_playground_1km" )
