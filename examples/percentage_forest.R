#source("indicator\\countPointsinPolygon.R")
source("indicator\\areaPercentage.R")
con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "129.247.28.69",
                 port = 5432,
                 user = "urmo",
                 password = "urmo",
                 dbname = "urmo")

#dbGetQuery(con, "SELECT * INTO veu_survey.forest from urmo.blk where flt_id=55")

calcAreaRatio(con, 
               ex_table_schema = "veu_survey",
               ex_table= "forest", 
               ex_table_id = "gid", 
               ex_table_geom = "the_geom",
               grid_schema = "veu_survey", 
               grid_table = "berlin_adressen_2016_survey_buffer1km", 
               grid_id = "gid", 
               grid_geom = "geom",
               resultTable_schema = "veu_survey", 
              resultTable_name = "berlin_adressen_ratio_forest")