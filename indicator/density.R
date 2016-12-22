# Calculation of Density of Geometries per Area of examination (for (Multi)Lines the density will be calculated
# as length per area km/km2



#' Spatial Indicator for density.
#' Calculates Density of Features in an Area.
#' 
#' @param con : A connection to the PostGIS database.
#' @param schema1: As string - Name of the Schema that contains ex_area
#' @param ex_area as string: the name of the table in the PostGIS database containing the geometry 
#'  that represents your area of examination (Grid, etc.) must have Polygon or Multipolygon Geometry
#' @param schema2: As string - Name of the Schema that contains obj
#' @param obj: As string - the feature which density shall be calculated. Can be Point, Polygon or Line.
#' @param output: As string - Name of the Output-Table that will be created in the Database (in schema1)
#'                Tables with the same name as output will be overwritten. Please change the output parameter
#'                if you want to keep all tables of subsequent Density-Querys


#' @examples 
#    gid area_km2 totale     density
#1   20   1.5645    473 302.3330137
#2   23   1.5645    441 281.8791946
#3   33   1.5645    411 262.7037392
#4   17   1.5645    343 219.2393736
#5   11   1.5645    322 205.8165548
#6   10   1.5645    305 194.9504634
#7   34   1.5645    303 193.6720997

# The Function to be used is at the End of the script called dsty 
# dsty(con, schema1, ex_area, schema2, obj)
# The Function will check the geometry of the obj parameter and execute the appriate procedure to calculate
# the density.
# If the chosen area of examination is not a (Multi)Polygon an Error-Message will be returned

# setwd("X:\\DLR\\Daten")
# 
# # Required Library
# library(RPostgreSQL)

#Variable that will be used to establish the connection to the database





###########DENSITY POINT IN POLYGON################


dsty_poi = function (connection, ex_area, obj, output) {
  density = dbGetQuery(connection, sprintf("SELECT * INTO %s FROM
                                           (SELECT %s.gid as GID, st_area(%s.geom)/1000000 AS ex_area_km2, 
                                           count(%s.geom) AS totale, 
                                           count(%s.geom)/(st_area(%s.geom)/1000000) AS density
                                           FROM %s LEFT JOIN %s
                                           ON st_contains(%s.geom, %s.geom)
                                           GROUP BY %s.gid
                                           ORDER BY density DESC) AS foo;
                                           ALTER TABLE %s ADD PRIMARY KEY(GID);
                                           SELECT * FROM %s;",
                                           output, ex_area, ex_area, obj, obj, ex_area, ex_area, obj, ex_area, obj, ex_area, output, output))
  density
}


##########DENSITY POLYGON in POLYGON###############
###############VIA CENTROIDS#######################



dsty_poly = function (connection, ex_area, obj, output) {
  density = dbGetQuery(connection, sprintf("SELECT * INTO %s FROM
                                           (SELECT %s.gid as GID, st_area(%s.geom)/1000000 AS ex_area_km2, 
                                           count(st_centroid(%s.geom)) AS totale,
                                           count(st_centroid(%s.geom))/(st_area(%s.geom)/1000000) AS density
                                           FROM %s LEFT JOIN %s
                                           ON st_contains(%s.geom, st_centroid(%s.geom))
                                           GROUP BY %s.gid
                                           ORDER BY density DESC) As foo;
                                           ALTER TABLE %s ADD PRIMARY KEY(GID);
                                           SELECT * FROM %s;",
                                           output, ex_area, ex_area, obj, obj, ex_area, ex_area, obj, ex_area, obj, ex_area, output, output))
  density
}


##########DENSITY LINE IN POLYGON (LENGTH PER AREA)###############

dsty_line = function(connection, ex_area, obj, output) {
  density = dbGetQuery(connection, sprintf("SELECT * INTO %s FROM
                                           (SELECT %s.gid as GID, st_area(%s.geom)/1000000 AS ex_area_km2,
                                           count(%s.geom) AS totale,
                                           SUM(ST_Length(ST_INTERSECTION(%s.geom, %s.geom)))/1000 as sum_length,
                                           (SUM(ST_Length(ST_INTERSECTION(%s.geom, %s.geom)))/1000)/
                                           (st_area(%s.geom)/1000000) as density 
                                           FROM %s LEFT JOIN %s
                                           ON ST_INTERSECTS(%s.geom, %s.geom)
                                           GROUP BY %s.gid ORDER BY density DESC) as foo;
                                           ALTER TABLE %s ADD PRIMARY KEY(GID);
                                           SELECT * FROM %s;",
                                           output, ex_area, ex_area, obj,ex_area, obj,ex_area, obj, ex_area, ex_area, obj, ex_area, obj,ex_area, output, output))
  density
  
}

##########FINAL-FUNCTION########################

dsty = function(con, schema1, ex_area, schema2, obj, output) {
  
  clear = dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;", output)) 
  ex_areaS = paste(schema1, ex_area, sep = ".")
  objS =  paste(schema2, obj, sep = ".")
  check1 = dbGetQuery(con, sprintf("SELECT ST_GeometryType(geom) FROM %s LIMIT 1;", ex_areaS))
  check2 = dbGetQuery(con, sprintf("SELECT ST_GeometryType(geom) FROM %s LIMIT 1;", objS))
  poly = c("ST_Polygon", "ST_MultiPolygon")
  point = c("ST_Point")
  line = c("ST_MultiLineString", "ST_Linestring")
  
  if (check1 %in% poly == TRUE && check2 %in% poly == TRUE) {
    
    dsty_poly(con, ex_areaS, objS, output)
    
  } else if (check1 %in% poly == TRUE && check2 %in% point == TRUE) {
    
    dsty_poi(con, ex_areaS, objS, output)
    
  } else if (check1 %in% poly == TRUE && check2 %in% line == TRUE ) {
    
    dsty_line(con, ex_areaS, objS, output)
    
  } else if (check1 %in% point == TRUE || check1 %in% line == TRUE) {
    
    print("Chosen area of examination does not have (Multi)Polygon Geometry")
    
  } else {
    
    
  }}




#----------------------------------------------------------------------------------------------------------------------

# #Usage:
# 
# con = dbConnect(dbDriver("PostgreSQL"), dbname = "dlr", host = "localhost", 
#                 user = "postgres", password = "postgres") 
# 
# 
# dsty(con, "test", "hex_grid", "public", "strassennetzb_rbs_od_blk_2015_mitte", "output1")
# 
# 
# 
# 
# 
# #-----------------------------------------------------------------------------------------------------------------------
# 
# 
# #disconnect DB Connection
# dbDisconnect(con)

#SQL-Queries:

# point in polygon:
#
#     SELECT ex_area.gid, st_area(ex_area.geom)/1000000 AS ex_area_km2, 
#      count(obj.geom) AS totale, 
#      count(obj.geom)/(st_area(ex_area.geom)/1000000) AS density
#      FROM ex_area LEFT JOIN obj
#      ON st_contains(ex_area.geom, obj.geom)
#      GROUP BY ex_area.gid
#      ORDER BY density DESC;
#
#
#
# centroid in polygon: 
#
#     SELECT ex_area.gid, st_area(ex_area.geom)/1000000 AS ex_area_km2, 
#     count(st_centroid(obj.geom)) AS totale,
#     count(st_centroid(obj.geom))/(st_area(ex_area.geom)/1000000) AS density
#     FROM ex_area LEFT JOIN obj
#     ON st_contains(ex_area.geom, st_centroid(obj.geom))
#     GROUP BY ex_area.gid
#     ORDER BY density DESC;",
#
#
# line lenghth per area:
#
#     SELECT ex_area.gid, st_area(ex_area.geom)/1000000 AS ex_area_km2,
#     SUM(ST_Length(ST_INTERSECTION(ex_area.geom, obj.geom)))/1000 as sum_length
#     (SUM(ST_Length(ST_INTERSECTION(ex_area.geom, obj.geom)))/1000) / (st_area(ex_area.geom)/1000000) as density 
#     FROM ex_area LEFT JOIN obj
#     ON ST_INTERSECTS(ex_area.geom, obj.geom)
#     GROUP BY ex_area.gid ORDER BY density DESC;",
#
# check geometry type of ex_area & obj
#
#     SELECT ST_GeometryType(geom) FROM ex_area LIMIT 1
#     SELECT ST_GeometryType(geom) FROM obj LIMIT 1




