source("indicator\\qntfyLines.R")

con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "postgres",
                 dbname = "urmo")

qntfyLines(con, "grid.hex_4000", "gid" , "the_geom", "osm.berlin_network", "osm_type", "shape")

