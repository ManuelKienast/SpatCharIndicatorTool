# Christina am 06.09.2016
# Berechnung von  Flaechenanteilen pro Aggregationszelle



#' calculates the proportion of landuse in the examination_areas by summation of all areas belonging to the same category
#' and division by the total area of the gridd-cell
#' Note, that split areas will be kept and calculated to the aggregation unit it intersects with. 
#' 
#' @param con                A con       connection to the PostGIS database.
#' @param ex_table_schema    A string    the name of the scheme in the database, in which the tables are included
#' @param ex_table           A string    the name of the table in the PostGIS database containing the geometry you want to know the ratio of
#' @param ex_table_id        A string    the name of the id column of the ex_table with the landuse-categories
#' @param ex_table_geom      A string    the name of the geometry column of the examination table
#' @param grid_table         A string    the name of the table in the PostGIS database containing the aggregation units
#' @param grid_id            A string    the column with unique identifier of the aggregation units
#' @param grid_geom          A string    the column holding the geometries of the grid
#' @param resultTable_schema A string    the name of the schema the resutlTable is to be written into
#' @param resultTable_name   A string    the name of the resultTable whcih is going ot be created by this func
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

calcAreaRatio <- function( con,
                       ex_table_schema = "public", ex_table, ex_table_id, ex_table_geom,
                       grid_schema = "public", grid_table, grid_id, grid_geom,
                       resultTable_schema = "public", resultTable_name
                       )

  {
  
  #creates a table intersecting the input data with aggregation cells
  #erstellt eine Tabelle die die überschneiden Flächen von Landuse mit den Flächen der TVZ je TVZ ausgibt

  interSection <- dbGetQuery(con, sprintf(

    "DROP TABLE IF EXISTS public.%s_intersec;

    CREATE TABLE public.%s_intersec (
      gid serial PRIMARY KEY,
      aggr_unit integer,
      use varchar(20));

    ALTER TABLE public.%s_intersec ADD COLUMN geom geometry (MultiPolygon, 25833);
    ALTER TABLE public.%s_intersec ADD COLUMN grid_geom geometry (MultiPolygon, 25833);

    INSERT INTO public.%s_intersec (
      SELECT
        row_number() over (order by 1) as gid,
        b.%s::numeric as aggr_unit,
        a.%s as usage,
        ST_Multi(ST_Intersection(a.%s, b.%s))::geometry(MultiPolygon, 25833) as geom,
        b.%s AS grid_geom
          FROM %s.%s AS a,
               %s.%s AS b
      WHERE ST_Intersects(a.%s, b.%s) AND ST_isvalid(a.%s) = TRUE);
      ",
    resultTable_name,
    #resultTable_schema,
    resultTable_name,
    resultTable_name,
    resultTable_name,
    resultTable_name,
    grid_id,
    ex_table_id,
    ex_table_geom, grid_geom,
    grid_geom,
    ex_table_schema, ex_table,
    grid_schema, grid_table,
    ex_table_geom, grid_geom, ex_table_geom
    ))


  ## calculates the part of area per aggregation unit
  ## Berechnet den Flächenanteil pro landuse-Kategorie in jeder TVZ
   
  ratio <- dbGetQuery(con, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s;

    SELECT * INTO %s.%s FROM(
      
      SELECT 
        row_number() over (order by 1) as gid,
        a.aggr_unit,
        a.use,
        round(sum(ST_AREA(a.geom))::numeric, 2) as area,
        round((100/ (ST_AREA(b.%s))*sum(ST_AREA(a.geom)))::numeric,2) as area_ratio,
        a.grid_geom
          FROM %s_intersec as a 
            LEFT JOIN %s.%s as b 
              ON a.aggr_unit = b.%s::numeric
      GROUP BY  a.aggr_unit,
                a.use,
                b.%s,
                a.grid_geom
      ORDER BY a.aggr_unit
      )as foo
      ;"
      ,
      
      resultTable_schema, resultTable_name,
      resultTable_schema, resultTable_name,
      grid_geom,
      resultTable_name,
      grid_schema, grid_table,
      grid_id,
      grid_geom
    )) 
    
  #delete <- dbGetQuery(con, sprintf("DROP TABLE %s_intersec;", resultTable_name))
  
    
 } 

#----------------------------------------------------------------------------------------------------------------------
#Usage:

# ##calcAreaRatio( con, 
#                ex_table_schema = "urmo", ex_table= "fls", ex_table_id = "os_id", ex_table_geom = "the_geom",
#                grid_schema = "grids", grid_table = "fish_4000", grid_id = "gid", grid_geom = "the_geom",
#                resultTable_schema = "public", resultTable_name = "a_test_landuseRatio_II"
#                )

# ratio(con,
#       "public", "a_test_landuseratio",
#       "the_geom", "grids", "fish_4000", "gid")
#
# #-----------------------------------------------------------------------------------------------------------------------
# 
# #disconnect DB Connection
# dbDisconnect(con)

#-----------------------------------------------------------------------------------------------------------------------

#SQL-Query:

#DROP TABLE IF EXISTS intersection;
#CREATE TABLE intersection (gid serial PRIMARY KEY, aggr_unit integer, use varchar);
#ALTER TABLE intersection ADD COLUMN geom geometry (MultiPolygon, 25833);

#INSERT INTO intersection (SELECT row_number() over (order by 1) as gid, b.grid_id, a.ex_table_id, ST_Multi(ST_Intersection(a.geom, b.geom))::geometry(MultiPolygon, 25833) as geom
#FROM ex_table_schema.ex_table a, grid_schema.grid_table b WHERE ST_Intersects(a.geom, b.geom));

#DROP TABLE IF EXISTS resultTable_schema.resultTable_name;
#CREATE TABLE resultTable_schema.resultTable_name (gid serial PRIMARY KEY, aggr_unit varchar, category varchar, area numeric, ratio numeric); 
#INSERT INTO resultTable_schema.resultTable_name (
#SELECT row_number() over (order by 1) as gid, a.aggr_unit, a.use, round(sum(ST_AREA(a.geom))::numeric, 2) as area, round((100/ (ST_AREA(b.geom))*sum(ST_AREA(a.geom)))::numeric,2) as area_ratio 
#FROM public.intersection as a LEFT JOIN grid_schema.grid_table as b ON a.aggr_unit = b.grid_id 
#GROUP BY a.aggr_unit, a.use, b.geom
#ORDER BY a.aggr_unit;

#DROP TABLE intersection;

