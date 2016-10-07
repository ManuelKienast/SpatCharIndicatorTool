#--------------------------------------------fishnet function-----------------------------------------------------------------

#this function creates a grid fitted to the extent of a layer chosen by the user. User specifies the reference layer(table), 
#as well as the desired cellsize in the function call -> fkt_fishnet(con, x_cell, y_cell, table,name)
# The fishnet will be fitted to the extent of the reference layer and the get the same SRID as the reference layer

#' @param con : A connection to the PostGIS database.
#' @param x_cell: As numeric - width of grid cells
#' @param y_cell: As numeric - height of grid cells
#' @param schema1: As string - Name of the Schema in which the reference layer(table) is located
#' @param table: As string - reference layer over which the grid shall be cast
#' @param schema2: As string - Name of the Schema in where the fishnet shall be created
#' @param name: As string - name of the fishnet to be created


#-----------------------------------------------------------------------------------------------------------------------------
# setwd("X:\\DLR\\Daten")
# 
# library(rgdal)
# library(RPostgreSQL)
# 
# #creates connection to the database 
# con <- dbConnect(dbDriver("PostgreSQL"),
#                  dbname = "DLR",
#                  host = "localhost",
#                  user = "postgres", 
#                  password = "postgres")
# 
# #Lists all tables of chosen database
# dbListTables(con)


x_cell      # Cellwidth in unit of chosen  SRID
y_cell      # Cellheighth in unit of chosen SRID
schema1     # Name of the Schema in which the reference layer table is located
table       # Reference layer for extent
schema2     # Name of the Schema in which the Fishnet shall be created
name        # Name of output table



fishnet <- function(con, x_cell, y_cell, schema1, table, schema2, name) {
  
  tableS = paste(schema1, table, sep = ".")
  nameS  = paste(schema2, name, sep = ".")
  
  clear = dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;", nameS))  
  
  get_SRID = dbGetQuery(con, sprintf("SELECT FIND_SRID('%s', '%s', 'geom');", schema1, table)) 
  
  w_layer = dbGetQuery(con, sprintf("select ceil((st_xmax(st_extent(%s.geom)) - 
                                   st_xmin(st_extent(%s.geom)))/%s)  FROM %s;", tableS, tableS, x_cell, tableS))
  
  h_layer = dbGetQuery(con, sprintf("select  ceil((st_ymax(st_extent(%s.geom)) - 
                                   st_ymin(st_extent(%s.geom)))/%s) AS height_layer FROM %s;", tableS, tableS, y_cell, tableS))
  
  
  create_fish = dbGetQuery(con, sprintf("CREATE OR REPLACE FUNCTION ST_CreateFishnet(
                                          nrow integer, ncol integer,
                                          xsize float8, ysize float8,
                                          x0 float8 DEFAULT 0, y0 float8 DEFAULT 0,
                                          OUT \"row\" integer, OUT col integer,
                                          OUT geom geometry)
                                        RETURNS SETOF record AS
                                        $$
                                        SELECT i + 1 AS row, j + 1 AS col, ST_Translate(cell, j * $3 + $5, i * $4 + $6) AS geom
                                        FROM generate_series(0, $1 -1) AS i,
                                             generate_series(0, $2 -1) AS j,
                                        
                                        (SELECT ('POLYGON((0 0, 0 '||$4||', '||$3||' '||$4||', '||$3||' 0, 0 0))')::geometry AS cell) AS foo;
                                        $$ LANGUAGE sql IMMUTABLE STRICT;
                                        
                                        
                                        CREATE TABLE %s AS
                                        SELECT *
                                        FROM ST_CreateFishnet(%s, %s, %s, %s, 
                                        (SELECT ST_xmin(St_extent(geom)) FROM %s),
                                        (SELECT ST_ymin(St_extent(geom)) FROM %s)) AS cells;

                                        ALTER TABLE %s
                                        ADD COLUMN gid serial PRIMARY KEY;

                                        ALTER TABLE %s
                                        ALTER COLUMN geom TYPE geometry(Polygon, %s)
                                        USING ST_SetSRID(geom, %s);"
                                        , nameS, h_layer, w_layer, x_cell, y_cell, tableS, tableS, nameS, nameS, get_SRID, get_SRID
                                        
                                        
  ))
  
}




#----------------------------------------------------------------------------------------------------------------------

#Usage:

# fishnet(con, 2000, 2000, "public", "tvz", "public", "fishnet")
# 
# 
# 
# 
# #-----------------------------------------------------------------------------------------------------------------------
# 
# 
# #disconnect DB Connection
# dbDisconnect(con)


#-----------------------------------------------------------------------------------------------------------------------


#SQL-Queries:

#
# clear existing table: DROP TABLE IF EXISTS name;
# 
# get SRID of ex_area: SELECT FIND_SRID('public', 'table', 'geom');
#
#
# w_layer: get optimal number of columns for the grid depending on x_cell:
# SELECT CEIL((st_xmax(st_extent(table.geom)) - 
# st_xmin(st_extent(table.geom)))/x_cell)  FROM table;
#
#
# h_layer: get optomal number of rows for the grid depending on y_cell:
# SELECT CEIL((st_ymax(st_extent(table.geom)) - 
# st_ymin(st_extent(table.geom)))/y_cell) AS height_layer FROM table;
#
#
# create and call fct. fishnet:
#-------------------------------------------------
# CREATE OR REPLACE FUNCTION ST_CreateFishnet(
# nrow integer, ncol integer,
# xsize float8, ysize float8,
# x0 float8 DEFAULT 0, y0 float8 DEFAULT 0,
# OUT \"row\" integer, OUT col integer,
# OUT geom geometry)
# RETURNS SETOF record AS
# $$
# SELECT i + 1 AS row, j + 1 AS col, ST_Translate(cell, j * $3 + $5, i * $4 + $6) AS geom
# FROM generate_series(0, $1 -1) AS i,
# generate_series(0, $2 -1) AS j,

# (SELECT ('POLYGON((0 0, 0 '||$4||', '||$3||' '||$4||', '||$3||' 0, 0 0))')::geometry AS cell) AS foo;
# $$ LANGUAGE sql IMMUTABLE STRICT;


# CREATE TABLE name AS
# SELECT *
# FROM ST_CreateFishnet(h_layer, w_layer, x_cell, y_cell, 
# (SELECT ST_xmin(St_extent(geom)) FROM table),
# (SELECT ST_ymin(St_extent(geom)) FROM table)) AS cells;

# ALTER TABLE name
# ADD COLUMN gid serial PRIMARY KEY;

# ALTER TABLE name
# ALTER COLUMN geom TYPE geometry(Polygon, get_SRID)
# USING ST_SetSRID(geom, get_SRID);"

