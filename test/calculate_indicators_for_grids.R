source("indicator\\qntfyLines.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")

qntfyLines(con,"public.hex_8000_osm_ind", "grid.hex_8000", "gid" , "the_geom", "osm.berlin_network", "osm_type", "shape")

