# Christina am 06.09.2016
# Berechnung von  Flaechenanteilen pro Aggregationszelle



#' Spatial Indicator for a proportion of areas.
#' Builds a proportion of areas of a selected category per aggregation cell.
#' Note, that splitted areas will be kept and calculated to the aggregation unit it intersects with. 
#' 
#' @param con A connection to the PostGIS database.
#' @param schema A string: the name of the scheme in the database, in which the tables are included.
#' @param table A string: the name of the table in the PostGIS database containing the geometry you want to know the ratio.
#' @param category A string: the name of the column of the categories.
#' @param aggregation A string: the name of the table in the PostGIS database containing the aggregation units.
#' @param aggr_id A string: the name of the identifier of the aggregation units.
#' @param intersection A string: the name of the new table containing the intersected areas.
#' 
#' @return area A data.frame containing the aggretaion units, their categories (use), the area of that category and the proportion of that area to the area of the aggregation unit in percent. 
#' 
#' @examples 
#' areaRatio(con, "public", "landuse", "landuse", "TVZ", "VBZ_NO")
#'            aggr_unit           landuse      area area_ratio
#'        1   110100111        commercial  46508.39       6.22
#'        2   110100111      construction   1035.61       0.14
#'        3   110100111             grass   5049.22       0.68



# setwd("d:\\Projekt\\")
# #install.packages("L:\\Projekt\\Packages\\RPostgreSQL_0.4-1.zip",repos = NULL) 
# #install.packages("L:\\Projekt\\Packages\\DBI_0.5.zip", repos = NULL)
# library(RPostgreSQL)
# 
# ## Connect to database
# drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname = "dlr2", host = "localhost", user = "postgres", password = "postgres") 
# dbListTables(con)


#Gives the proportion of areas of a selected category per aggregation cell.
#Note, that splitted areas will be kept and calculated to the aggregation unit it intersects with. 

areaRatio <- function(con, schema = "public", table, category, aggr_schema = "public", aggregation, aggr_id, out_schema = "public", output, intersection = "intersection") {
  #creates a table intersecting the input data with aggregation cells
  #erstellt eine Tabelle die die ?berschneiden Fl?chen von Landuse mit den Fl?chen der TVZ je TVZ ausgibt
  interSection <- dbGetQuery(con, sprintf(
    "DROP TABLE IF EXISTS %s;
      CREATE TABLE %s (gid serial PRIMARY KEY, aggr_unit integer, use varchar);
      ALTER TABLE %s ADD COLUMN geom geometry (MultiPolygon, 25833);

      INSERT INTO %s (
      SELECT row_number() over (order by 1) as gid, b.%s::numeric, a.%s, ST_Multi(ST_Intersection(a.geom, b.geom))::geometry(MultiPolygon, 25833) as geom
      FROM %s.%s a, %s.%s b WHERE ST_Intersects(a.geom, b.geom));
      ", intersection, intersection, intersection, intersection, aggr_id, category, schema, table, aggr_schema, aggregation))

  #calculates the part of area per aggregation unit 
  #Berechnet den Fl?chenanteil pro landuse-Kategorie in jeder TVZ
    ratio <- dbGetQuery(con, sprintf(
      "DROP TABLE IF EXISTS %s.%s;
      CREATE TABLE %s.%s (gid serial PRIMARY KEY, aggr_unit varchar, category varchar, area numeric, ratio numeric); 
      INSERT INTO %s.%s (
      SELECT row_number() over (order by 1) as gid, a.aggr_unit, a.use, round(sum(ST_AREA(a.geom))::numeric, 2) as area, round((100/ (ST_AREA(b.geom))*sum(ST_AREA(a.geom)))::numeric,2) as area_ratio 
      FROM public.%s as a LEFT JOIN %s.%s as b ON a.aggr_unit = b.%s::numeric
      GROUP BY a.aggr_unit, a.use, b.geom
      ORDER BY a.aggr_unit);
      ", out_schema, output, out_schema, output, out_schema, output, intersection, aggr_schema, aggregation, aggr_id)) 
    delete <- dbGetQuery(con, "DROP TABLE intersection")
    ratio
    
} 



#----------------------------------------------------------------------------------------------------------------------

#Usage:

#areaRatio(con, "public", "landuse", "landuse", "public", "tvz", "vbz_no", "public", "arearatio")

#areaRatio(con, table = "landuse", category = "landuse", aggregation = "vkz", aggr_id = "visum_no", output = "arearatio")

#areaRatio(con, "public", table = "landuse", category = "landuse",  aggregation = "rbs_od_blk_2015_mitte", aggr_id = "blk", output = "arearatio")



# #-----------------------------------------------------------------------------------------------------------------------
# 
# #disconnect DB Connection
# dbDisconnect(con)

#-----------------------------------------------------------------------------------------------------------------------

#SQL-Query:

#DROP TABLE IF EXISTS intersection;
#CREATE TABLE intersection (gid serial PRIMARY KEY, aggr_unit integer, use varchar);
#ALTER TABLE intersection ADD COLUMN geom geometry (MultiPolygon, 25833);

#INSERT INTO intersection (SELECT row_number() over (order by 1) as gid, b.aggr_id, a.category, ST_Multi(ST_Intersection(a.geom, b.geom))::geometry(MultiPolygon, 25833) as geom
#FROM schema.table a, aggr_schema.aggregation b WHERE ST_Intersects(a.geom, b.geom));

#DROP TABLE IF EXISTS out_schema.output;
#CREATE TABLE out_schema.output (gid serial PRIMARY KEY, aggr_unit varchar, category varchar, area numeric, ratio numeric); 
#INSERT INTO out_schema.output (
#SELECT row_number() over (order by 1) as gid, a.aggr_unit, a.use, round(sum(ST_AREA(a.geom))::numeric, 2) as area, round((100/ (ST_AREA(b.geom))*sum(ST_AREA(a.geom)))::numeric,2) as area_ratio 
#FROM public.intersection as a LEFT JOIN aggr_schema.aggregation as b ON a.aggr_unit = b.aggr_id 
#GROUP BY a.aggr_unit, a.use, b.geom
#ORDER BY a.aggr_unit;

#DROP TABLE intersection;

