#--------------------------------------------  Calculating the area of PlayGround available per child  ----------------------------------
#' Function Calculating the
#' Ratio of PlayGroundArea per Child available in a selected aggregation Area;
#' working examples include TVZ-Mitte and Fishnet.
#'
#'
#' @param connection : A connection to the PostGIS database.
#' @param WriteToTable AS string -- Table to create and write results into
#' @param Agg          AS string -- AggregationTable - containig geometries of Aggregation units, e.g. TVZ or Fishnet
#' @param Agg_sche     AS string -- schema of the AggregationTable
#' @param sourcee      AS string -- SourceInformation - geometries containing the cells with childrens count
#' @param sourc_sche   AS string -- schema of the ScourceInformation table
#' @param Agg_ID       AS string -- unique ID of Aggregation Areas  i.e. TVZ-Identifier number
#' @param Source_ID    AS string -- unique ID of source Areas to facilitate the connection to the children per Planungsraum table
#' @param PlayGrounds  AS string -- table containg the PlayGround geometries
#' @param childNos     AS string -- table cointaing children information
#' @param childNos_ID  AS string -- Identifier to JOIN ON : Source_ID to combine childrens # and their geometries
#' @param childage     AS string -- Column in which the children are stored, see usage examples below

#' @examples 
#    subcell_id  pg_child
# 1    110100111      7.14
# 2    110100121    453.85
# 3    110100122        NA
#
#-----------------------------------------------------------------------------------------------------------------------------------------

## Setting Up
setwd("d:\\__projekt\\")
library(RPostgreSQL)
library(rgdal)
library(RODBC)

## Creating the db connection
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "DLR", host = "localhost", port= "5433", user = "postgres", password = "postgres") 
dbListTables(con)


## For the computation three steps are necessary:
## 1) creation of geometry table holding the intersection between the geometries of the 
##    aggregation Area and the geometries of the Source Area (the information about the # of children), deleted during final steps
## 2) setting up a preliminary results table, preparing for grouping of values in the final results table, deleted during final steps
## 3) the query, combining the # of children, the areas of the playgorunds inside the selected aggreagtion Area


##
## 1) Function for creation of the sub-cell geometrie table  --> the intersection table
##
# 
# -- returned columns ARE:
# -- GID			    GID of the created sub-cells                    -- created
# -- TVZ_ID		      	ID of the Aggregation polygon                   -- tvz.vbz_no / fishnet.gid
# -- PLR_ID		      	ID of the children-information source polygon   --  plr.schluessel / gid-source polygon
# -- AREA_tvz_plr		area of the resulting sub-cell                  --  St_Area(ST_Multi(ST_Intersection(aggregationPoly.geom, sourcePoly.geom)))
# -- AREA_PLR	    	area of the source polygon                      --  St_Area(sourcePoly.geom)



PlayArea <- function(
  connection  = con,
  WriteToTable= "Result_PlayArea",              ## Table name to create in PostGreSQL and write results into
  Agg         = "tvz",                          ## AggregationTable - containig geometries of Aggregation units, e.g. TVZ or Fishnet
  Agg_sche    = "public",                       ## Schema of Agg table
  sourcee     = "planungsraum_mitte",           ## SourceInformation - geometries containing the cells with childrens count
  Sourc_sche  = "public",                       ## schema of scourcee table
  Agg_ID      = "vbz_no",                       ## unique ID of Aggregation Areas  i.e. TVZ-Identifier number
  Source_ID   = "schluessel",                   ## unique ID of source Areas; here it is used to facilitate the connection to the children per Planungsraum table
  PlayGrounds = "spielplaetze",                 ## table containg the PlayGround geometries
  childNos    = "spielplaetze_oeff_planungsr",  ## table cointaing children information, beeing joined to sourcee (source information geometries, the spatial reference for the childrens count table)
  childNos_ID = "planungsra",                   ## Identifier to JOIN ON : Source_ID to combine childrens # and their geometries
  childage    = "kinder0_18"                    ## Column in which the children are stored..
  
  ) 
{
  
  SubCells <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS SubCell;
    
      CREATE TABLE SubCell (
          gid serial PRIMARY KEY,
          SubCell_ID integer,
          PLR_ID integer,
          area_SubCell decimal(20,2),
          area_PLR decimal(20,2));
      ALTER TABLE SubCell ADD COLUMN geom geometry (MultiPolygon, 25833);
    
    INSERT INTO SubCell (
      
    SELECT 
      row_number() over (order by 1) as gid,
      tvz.%s AS SubCell_ID,
      plr.%s::integer AS PLR_ID,
      st_area(ST_Multi(ST_Intersection(tvz.geom, plr.geom))) AS SubCellArea,
      st_area(plr.geom) AS PlrArea,
      ST_Multi(ST_Intersection(tvz.geom, plr.geom))::geometry(multipolygon, 25833) as geom
      FROM %s.%s as tvz
      INNER JOIN %s.%s as plr
      ON ST_Intersects(tvz.geom, plr.geom)
      WHERE Not ST_IsEmpty(ST_Intersection(tvz.geom, plr.geom)));
    
      --SELECT * FROM SubCell ORDER BY SubCell_ID
      ;",    


      Agg_ID,             ## SELECT 2nd row
      Source_ID,          ## SELECT 3rd row
      Agg_sche, Agg,      ## FROM
      Sourc_sche, sourcee ## INNER JOIN
      
    ))
  
  
  
  
    TempResult   <- dbGetQuery(connection, sprintf(
      
      "DROP TABLE if EXISTS RESULT;
      SELECT * INTO RESULT
      FROM (SELECT
                SubCell_ID,
                (area_SubCell/area_plr*%s) as ChildPerSubCell,
                sum(St_area(s.geom)) As PlayGroundArea
          FROM SubCell as t 
            LEFT JOIN %s as s
            ON ST_Intersects (t.geom, st_centroid(s.geom)) 
                LEFT JOIN %s AS so 
                ON (t.plr_id = so.%s::integer) 
      GROUP BY SubCell_ID, st_area(s.geom), t.geom, ChildPerSubCell, plr_id
      ORDER BY SubCell_ID  ) as foo;
      
      -- SELECT * From result
      ;",
      
      childage ,    ## SELECT 2nd row
      PlayGrounds,  ## LEFT JOIN 1st
      childNos,     ## LEFT JOIN 2nd
      childNos_ID   ## ON () 2nd
      
    ))
    
      
  ResultPlayArea   <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s;
    SELECT * Into %s FROM 
    (SELECT
    SubCell_ID,
    ROUND((sum(playgroundarea)/sum(childpersubcell))::decimal, 2) AS PG_Child
    FROM result
    Group by SubCell_ID
    order by SubCell_ID ) as foo;
    
    
    ALTER TABLE %s ADD PRIMARY KEY (SubCell_ID);
    
    -- DROP TABLE Result;
    
    -- DROP TABLE SubCell;
    
    SELECT * FROM %s
    -- WHERE playgroundperchild > 0;
    ",
      
      WriteToTable,  ## DROP TABLE IF
      WriteToTable,  ## SELECT * Into
      WriteToTable,  ## Alter Table
      WriteToTable   ## SELECT *
    ))
  
  ResultPlayArea
}

##---------------- with defaults see above --------------------
#Usage:
PlayArea()


##---------------- with Fishnet already in db as "fishnet" ----------------
#Usage:  
PlayArea( Agg = "fishnet", Agg_ID = "gid" )


## --------------- childcol allows for selection of age group, as present in the datafile

# age: 0-6   -->  "kinderu6j"
# age: 6-12  -->  "kinder6_12"
# age: 12-18 -->  "kinder12_1"
# age: 0-18  -->  "kinder0_18"
#
# additionally, setting childage as "(kinderu6j+kinder6_12)" will produce the PlayGroundArea for the 0-12 years age group.

PlayArea( childage = "(kinderu6j+kinder6_12)")


##---------------- disconnect DB Connection ------------------
dbDisconnect(con)



##
##
# ########################################################################################################################################
# #
# # Raw SQL-Code computing on the aggregation level of the TVZ 
# #
# DROP TABLE IF EXISTS SubCell;
# CREATE TABLE SubCell (gid serial PRIMARY KEY, SubCell_ID integer, PLR_ID integer, area_SubCell decimal(20,2), area_PLR decimal(20,2));
# ALTER TABLE SubCell ADD COLUMN geom geometry (MultiPolygon, 25833);
# 
# INSERT INTO SubCell (
#   
#   SELECT 
#     row_number() over (order by 1) as gid,
#     tvz.gid AS SubCell_ID,
#     plr.schluessel::integer AS PLR_ID,
#     st_area(ST_Multi(ST_Intersection(tvz.geom, plr.geom))) AS SubCellArea,
#     st_area(plr.geom) AS PlrArea,
#     ST_Multi(ST_Intersection(tvz.geom, plr.geom))::geometry(multipolygon, 25833) as geom
#       FROM fishnet as tvz
#         INNER JOIN planungsraum_mitte as plr
#         ON ST_Intersects(tvz.geom, plr.geom)
#         WHERE Not ST_IsEmpty(ST_Intersection(tvz.geom, plr.geom)));
# 
#   SELECT * FROM SubCell ORDER BY SubCell_ID;
# 
# 
#   DROP TABLE if EXISTS RESULT;
#     SELECT * INTO RESULT FROM 
#       (SELECT
#         SubCell_ID,
#         (area_SubCell/area_plr*kinder0_18) as ChildPerSubCell,
#         sum(St_area(s.geom)) As PlayGroundArea
#           FROM SubCell as t 
#             LEFT JOIN spielplaetze as s
#             ON ST_Intersects (t.geom, st_centroid(s.geom)) 
#               LEFT JOIN spielplaetze_oeff_planungsr 
#               ON (t.plr_id = spielplaetze_oeff_planungsr.planungsra::integer) 
#     GROUP BY SubCell_ID, st_area(s.geom), t.geom, area_SubCell, area_plr, kinder0_18, plr_id
#     ORDER BY SubCell_ID  ) as foo;
# 
#   SELECT * From result;
# 
#   DROP TABLE IF EXISTS RESULT_PLAYAREA;
#     SELECT * Into RESULT_PlayArea FROM 
#       (SELECT
#         SubCell_ID,
#         sum(playgroundarea)/sum(childpersubcell) AS PlayGroundPerChild
#           FROM result
#   GROUP BY SubCell_ID
#   ORDER BY SubCell_ID ) as foo;
# 
#   ALTER TABLE RESULT_PlayArea ADD PRIMARY KEY (SubCell_ID);
# 
#   DROP TABLE Result;
# 
#   DROP TABLE SubCell;
# 
#   SELECT * FROM result_PlayArea
#   -- WHERE playgroundperchild > 0
# ;