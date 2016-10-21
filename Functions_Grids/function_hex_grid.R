#--------------------------------------------hex-grid function-----------------------------------------------------------------

#this function creates a hex:grid fitted to the extent of a layer chosen by the user. User specifies the reference layer(table) 
#as well as the desired cellwidth
# The hex_grid will be fitted to the extent of the reference layer and the get the same SRID as the reference layer

#' @param con : A connection to the PostGIS database.
#' @param hex_width: As numeric - Width of grid cells
#' @param schema1: As string - Name of the Schema in which the reference layer(table) is located
#' @param table: As string - Reference layer over which the grid shall be cast
#' @param schema2: As string - Name of the Schema where the fishnet shall be created
#' @param name: As string - Name of the hex_grid to be created


#-----------------------------------------------------------------------------------------------------------------------------


# setwd("X:\\DLR\\Daten")
# library(rgdal)
# library(RPostgreSQL)
# FOR PERSONAL USE
# ## Creating the db connection
# drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname = "DLR", host = "localhost", port= "5432", user = "postgres", password = "postgres")
# dbListTables(con)


# #creates connection to the database 
# drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname = "urmo", host = "129.247.28.69", port= "5432", user = "urmo", password = "urmo") 
# dbListTables(con)




hexgrid <- function(con, hex_width, Agg_Schema, Agg_Area, Agg_geom, schema2, name) {
  
  tableS = paste(Agg_Schema, Agg_Area, sep = ".")
  nameS = paste(schema2, name, sep = ".")
  
  clear = dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;", nameS))
  
  get_SRID = dbGetQuery(con, sprintf("SELECT FIND_SRID('%s', '%s', '%s');", Agg_Schema, Agg_Area, Agg_geom))
  
  xmin = dbGetQuery(con, sprintf("select (st_xmin(st_extent(%s.%s)) - (0.5*%s)) FROM %s;", tableS, Agg_geom, hex_width, tableS)) 
  
  ymin = dbGetQuery(con, sprintf("select (st_ymin(st_extent(%s.%s)) - (0.5*%s)) FROM %s;", tableS, Agg_geom, hex_width, tableS)) 
  
  xmax = dbGetQuery(con, sprintf("select (st_xmax(st_extent(%s.%s)) + (0.5*%s)) FROM %s;", tableS, Agg_geom, hex_width, tableS)) 
  
  ymax = dbGetQuery(con, sprintf("select (st_ymax(st_extent(%s.%s)) + (0.5*%s)) FROM %s;", tableS, Agg_geom, hex_width, tableS)) 
  
  
  create_hexgrid = dbGetQuery(con, sprintf("CREATE TABLE %s (gid serial not null primary key);
                                           
                                           SELECT addgeometrycolumn('%s', '%s','%s', 0, 'POLYGON', 2);
                                           
                                           CREATE OR REPLACE FUNCTION genhexagons(width float, xmin float, ymin  float, xmax float, ymax float  )
                                           
                                           RETURNS float AS $total$
                                           declare
                                           
                                           b float :=width/2;
                                           a float :=b/2; --sin(30)=.5
                                           c float :=2*a;
                                           
                                           height float := 4*a+c;  --1.1547*width;
                                           ncol float :=ceil(abs(xmax-xmin)/width);
                                           nrow float :=ceil(abs(ymax-ymin)/height);
                                           
                                           polygon_string varchar := 'POLYGON((' ||
                                           0 || ' ' || 0     || ' , ' ||
                                           b || ' ' || a     || ' , ' ||
                                           b || ' ' || a+c   || ' , ' ||
                                           0 || ' ' || a+c+a || ' , ' ||
                                           -1*b || ' ' || a+c   || ' , ' ||
                                           -1*b || ' ' || a     || ' , ' ||
                                           0 || ' ' || 0     ||
                                           '))';
                                           
                                           BEGIN
                                           INSERT INTO %s (%s) SELECT 
                                           st_translate(%s, x_series*(2*a+c)+xmin, y_series*(2*(c+a))+ymin)
                                           
                                           from generate_series(0, ncol::int , 1) as x_series,
                                           generate_series(0, nrow::int, 1 ) as y_series,
                                           (SELECT polygon_string::geometry as %s
                                           UNION
                                           SELECT ST_Translate(polygon_string::geometry, b , a+c)  as %s
                                           ) as two_hex;
                                           
                                           
                                           
                                           ALTER TABLE %s
                                           ALTER COLUMN %s TYPE geometry(Polygon, %s)
                                           USING ST_SetSRID(%s, %s);
                                           RETURN NULL;
                                           END;
                                           $total$ LANGUAGE plpgsql;
                                           
                                           SELECT genhexagons(%s,%s,%s,%s,%s);", 
                                           nameS,
                                           schema2, name, Agg_geom,
                                           nameS, Agg_geom,
                                           Agg_geom,
                                           Agg_geom,
                                           Agg_geom,
                                           nameS,
                                           Agg_geom, get_SRID,
                                           Agg_geom, get_SRID,
                                           hex_width, xmin, ymin, xmax, ymax)                   
                              
                              
                              
  )
  
}



#----------------------------------------------------------------------------------------------------------------------

# #Usage:
# 
# con <- dbConnect(dbDriver("PostgreSQL"),
#                  dbname = "urmo",
#                  host = "localhost",
#                  user = "postgres",
#                  password = "postgres")

# 
# 
# hexgrid(con, 500, "public", "tvz", "geom", "public", "hex_500")
# 
# 
# 
# #-----------------------------------------------------------------------------------------------------------------------
# 
# 
# #disconnect DB Connection
# dbDisconnect(con)


#SQL-Queries:

#hex_grid function:
#
# clear existing table: DROP TABLE IF EXISTS name;

# get SRID of ex_area: SELECT FIND_SRID('public', 'table', 'geom');

# get xmin (offset by: -hex_width/2) of bounding box  of ex_area : 
# SELECT (st_xmin(st_extent(table.geom)) - (0.5*hex_width)) FROM table; 
#
# get ymin (offset by: -hex_width/2) of bounding box  of ex_area :
# SELECT (st_ymin(st_extent(table.geom)) - (0.5*hex_width)) FROM table;
#
# get xmax (offset by: +hex_width/2) of bounding box  of ex_area :
# SELECT (st_xmax(st_extent(table.geom)) + (0.5*hex_width)) FROM table;
#
# get ymax (offset by: +hex_width/2) of bounding box  of ex_area :
# SELECT (st_ymax(st_extent(table.geom)) + (0.5*hex_width)) FROM table;
# 
# create and call fct hex_grid:

# CREATE TABLE hex_grid (gid serial not null primary key);

# SELECT addgeometrycolumn('hex_grid','geom', 0, 'POLYGON', 2);
#
# CREATE OR REPLACE FUNCTION genhexagons(width float, xmin float, ymin  float, xmax float, ymax float  )

# RETURNS float AS $total$
#  declare

# b float :=width/2;
# a float :=b/2; --sin(30)=.5
# c float :=2*a;

# height float := 4*a+c;  --1.1547*width;
# ncol float :=ceil(abs(xmax-xmin)/width);
# nrow float :=ceil(abs(ymax-ymin)/height);

# polygon_string varchar := 'POLYGON((' ||
#   0 || ' ' || 0     || ' , ' ||
#   b || ' ' || a     || ' , ' ||
#   b || ' ' || a+c   || ' , ' ||
#   0 || ' ' || a+c+a || ' , ' ||
#   -1*b || ' ' || a+c   || ' , ' ||
#   -1*b || ' ' || a     || ' , ' ||
#   0 || ' ' || 0     ||
#   '))';

# BEGIN
# INSERT INTO hex_grid (geom) SELECT 
# st_translate(geom, x_series*(2*a+c)+xmin, y_series*(2*(c+a))+ymin)

# from generate_series(0, ncol::int , 1) as x_series,
# generate_series(0, nrow::int, 1 ) as y_series,
# (SELECT polygon_string::geometry as geom
#  UNION
#  SELECT ST_Translate(polygon_string::geometry, b , a+c)  as geom
# ) as two_hex;
#
# ALTER TABLE hex_grid RENAME TO name;
#
# ALTER TABLE name
# ALTER COLUMN geom TYPE geometry(Polygon, get_SRID)
# USING ST_SetSRID(geom, get_SRID);
# RETURN NULL;
# END;
# $total$ LANGUAGE plpgsql;

# SELECT genhexagons(hex_width, xmin, ymin, xmax, ymax)                   

