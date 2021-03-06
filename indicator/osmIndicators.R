## Function for qunatification of Line Types
## First calculating the total length of line type per Aggregation area, write those to table
## secondly calculation of ratio of line Type against all selected line Types
##
## Option for selection of which line types to calc or to choose ALL the lines
library(RPostgreSQL)
library(rgdal)
library(RODBC)
##
## setting helper functions
##
##########  FUNCTION  ##########  
## writing intersection table
##
##  IMPORTANT NOTICE.Personal check WHERE clause if switching between urmo and localhost
##  Additionally the setting of the WHERE col LIKE hw_ is necessary for calc of all, not for calc of bike ratio yes|no
##




# ####### Debugguing: this is working for a reduced lineNetwork the Intersect table is written correctly
# createInterSecTable( connection, "_qntfyLine_lines_R_test", 
#                                  "urmo.abz", "abz_id", "the_geom",
#                                  "_qntfyLine_lines_test", "osm_type", "shape")
# 
# ### testing for the name_id column
# createInterSecTable( connection, "_qntfyLine_lines_R_test", 
#                      "urmo.bz", "bz_name", "the_geom",
#                      "_qntfyLine_lines_test", "osm_type", "shape")
# 
# 
# 
# ### testing for the whole lineNetwork; it itersected perfectly.
# createInterSecTable( connection, "_qntfyLine_lines_R_test_II", 
#                      "urmo.bz", "bz_id", "the_geom",
#                      "osm.berlin_network", "osm_type", "shape")



createInterSecTable <- function( connection,
                                 resultTable_name,
                                 Agg_Area, id_column, Agg_geom,
                                 Ex_Area, label_column, Ex_geom
) 
{
  
  intersectTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s_InterSec;
    
    SELECT * INTO %s_InterSec FROM
    (SELECT 
    row_number() over (order by 1) as key,
    Agg_Area.%s AS Agg_ID,
    Ex_Area.%s AS LineType,
    ST_Multi(ST_Intersection(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))::geometry(multiLineString, 25833) as geom
    FROM
    %s AS Agg_Area
    LEFT JOIN %s AS Ex_Area
    ON (ST_INTERSECTS(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))
     WHERE 

     ST_isValid(Agg_Area.%s) = TRUE AND ST_isValid(ST_Transform(Ex_Area.%s, 25833)) = TRUE 
    ) as foo;
    
    ALTER TABLE %s_InterSec ADD PRIMARY KEY (key)
    ;"
    ,
    resultTable_name,             ## Drop
    resultTable_name,             ## SLECT INTO
    id_column,                    ## Agg_Area         -- column with the unique Agg_Area_ID e.g. PLR-id
    label_column,                 ## label_column.    -- column with linetype specification
    
    Agg_geom, Ex_geom,            ## ST_Multi         -- geometry columns of both Agg and Ex objects
    Agg_Area,                     ## FROM             -- table containing the Aggreation Area geometries 
    Ex_Area,                      ## LEFT JOIN        -- table containing the Examination Object  geometries and information here: lineTypes
    Agg_geom, Ex_geom,            ## ON               -- geometrie columns of both Agg and Ex objects
    #label_column, "highway%",     ## WHERE            -- type of Line and query for highway in its description --> its an OSM-special
    Agg_geom, Ex_geom,            ## WHERE            -- geometrie columns of both Agg and Ex objects
    resultTable_name              ## Add primary key
    
    ))
  
  return(intersectTable)
}
#--Ex_Area.%s LIKE '%s' AND 

#qntfyLines(con, Agg_Area, id_column, Agg_geom, Ex_Area, label_column, Ex_geom)
#
#

##########  FUNCTION  ##########
## getting the vector of dictinct variables from Agg_Area table
## reminder: switch WHERE linetype to 'highway%' for OSM data, otherwise no WHERE is needed

getVDist <- function (
  connection, 
  resultTable_name
)
{
  VDistdf <- dbGetQuery(connection, sprintf(
    
    "SELECT DISTINCT Linetype 
    FROM %s_InterSec
    ;"
    ,
    resultTable_name
  ))
  
  VDist <- VDistdf[,1]
  
  return(VDist)    
}


## DEBUGGING - working
#vDist <- getVDist(con, resultTable_name =  "bz_osm")

##########  FUNCTION  ##########  
## writing results table
## create result table with Agg_Area_Id and its geom to select other results into

createResultTable <- function( connection,
                               resultTable_name, id_column,
                               Agg_geom, Agg_Area
)
  
{
  dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s;
    
    SELECT 
    row_number() over (order by 1) as key,
    %s AS Agg_Id,
    %s AS geom
    INTO %s
    FROM %s AS Agg_Area
    WHERE ST_isValid(Agg_Area.%s) = TRUE AND ST_isSimple(Agg_Area.%s) = TRUE
    ;
    
    ALTER TABLE %s ADD PRIMARY KEY (key)
    ;"
    ,
    resultTable_name,        ## DROP If Exists
    id_column,               ## SELECT #1   -- column with the unique Agg_Area_ID e.g. PLR-id  
    Agg_geom,                ## SELECT #2   -- geometrie columns of Agg_Area
    resultTable_name,
    Agg_Area,                ## FROM        -- table containing the Aggreation Area geometries 
    Agg_geom, Agg_geom,
    resultTable_name         ## WHERE       -- geometry columns of Agg_Area
  ))  
  
}

## DEBUGGING -  working
#createResultTable( con, "bz_osm", "bz_id", "the_geom", "urmo.bz")




##########  FUNCTION  ##########
## updating a table (create and fill columns)
## containing the lengths of lines per aggregation Area
##
## TROUBLE cannot loop through the necessary VDIST renamed 2 way_whatever and the necessary way.whatever for selection
## of distinct values simultaneously, need to update the loop or else
##


updateTable <- function( connection,
                         vDist,
                         resultTable_name
)
  
{
  dbGetQuery(connection, sprintf( 
    
    "ALTER TABLE %s DROP COLUMN IF EXISTS sum_%s
    ;
    ALTER TABLE %s ADD COLUMN sum_%s FLOAT
    ;
    
    UPDATE %s 
    SET sum_%s = foo.sum_%s
    FROM (
    SELECT 
    Agg_ID,
    SUM(ST_Length(geom))/1000 AS sum_%s
    FROM %s_InterSec
    WHERE lineType = '%s'
    GROUP BY Agg_ID
    ORDER BY Agg_ID
    ) as foo
    WHERE %s.Agg_ID = foo.Agg_ID
    ;"
    ,
    resultTable_name, gsub('\\.','_',vDist),       ## ALTER TABLE DROP
    resultTable_name, gsub('\\.','_',vDist),       ## ALTER TABLE ADD COl     -- vector containing distinct values
    
    resultTable_name,                              ## UPDATE                  -- vector containing distinct values
    gsub('\\.','_',vDist), gsub('\\.','_',vDist),  ## SET                     -- vector containing distinct values
    gsub('\\.','_',vDist),                         ## SUM                     -- vector containing distinct values      
    resultTable_name,                              ## FROM                    -- vector containing distinct values
    vDist,                                         ## WHERE -1- Linetype
    resultTable_name                               ## WHERE -2- resutlTable   -- vector containing distinct values 
  ))
  
}

## DEBUGGING - working
#for (i in vDist) {updateTable(connection, i, "bz_osm")}




##########  FUNCTION  ##########  
## inserting the total length into Table results
## calc the total length of selected line types

sumLength <- function( connection,
                       vDist,
                       resultTable_name
)
  
{
  sumLength <- dbGetQuery(connection, sprintf(
    
    "UPDATE %s
    SET sum_length = COALESCE(sum_length,0)+COALESCE(sum_%s,0)  -- summation of all values listed in the V(Dist)
    ;"
    ,
    resultTable_name,
    vDist
  ))
}


## DEBUGGING - working
#addSumLengthCol <- dbGetQuery(connection, sprintf("ALTER TABLE %s DROP COLUMN IF EXISTS sum_length;
#                                                   ALTER TABLE %s ADD COLUMN sum_length FLOAT;", "bz_osm", "bz_osm"))

#for (i in vDistName) {sumLength(connection, i, "bz_osm")}



##########  FUNCTION  ##########  
## setting Function for line quantification

ratioLines2Table <- function( connection,
                              resultTable_name,
                              vDist
) 
  
{
  calcRatios <- dbGetQuery(connection, sprintf( 
    
    "ALTER TABLE %s DROP COLUMN IF EXISTS ratio_%s
    ;
    ALTER TABLE %s ADD COLUMN ratio_%s FLOAT
    ;
    
    UPDATE %s 
    SET ratio_%s = sum_%s/sum_length
    ;"
    ,
    resultTable_name, vDist,  ## ALTER TABLE DROP COl     -- vector containing distinct values
    resultTable_name, vDist,  ## ALTER TABLE ADD COL -- vector containing distinct values
    
    resultTable_name,         ## UPDATE  
    vDist, vDist              ## SET          -- vector containing distinct values
  ))
}


## DEBUGGING - 
#for (i in vDistName) {ratioLines2Table(connection, "bz_osm", i)}



##########  FUNCTION  ##########  
## the complete Function

calculateHighwayPercentages <- function( connection,
                            resultTable_name,
                            Agg_Area, id_column, in_geom_column,
                            label_column, mode, Ex_geom
)
  
{
  createInterSecTable(connection, resultTable_name, Agg_Area, id_column, in_geom_column, label_column, mode, Ex_geom)
  

  
  
  vDist <- getVDist(connection, resultTable_name)

  if(NA %in% vDist){
    vDist <- vDist[!is.na(vDist)]
  }

  vDistName <- gsub('\\.','_',vDist)
  
  createResultTable(connection, resultTable_name, id_column, in_geom_column, Agg_Area)
  
  
  for (i in vDist) {updateTable(connection, i, resultTable_name)}
  
  
  addSumLengthCol <- dbGetQuery(connection, sprintf("ALTER TABLE %s DROP COLUMN IF EXISTS sum_length;
                                                    ALTER TABLE %s ADD COLUMN sum_length FLOAT;", resultTable_name, resultTable_name))
  
  for (i in vDistName) {sumLength(connection, i, resultTable_name)}
  
  for (i in vDistName) {ratioLines2Table(connection, resultTable_name, i)}
  


}
## DEBUGGING - with bikeusage YES|NO updated table
# qntfyLinesBike ( con, "a_test_qntyfyLines_Clean_bz_test",
#                       "urmo.bz", "bz_id", "the_geom",
#                       "osm.berlin_network", "bikeusage", "shape")



##qntfyLines <- function (connection,result_table_name,Agg_Area,id_column,Agg_geom, Ex_Area,label_column,Ex_geom)

#for bikes -->  
#qntfyLinesBike(connection = con, result_table_name = "result_bike_hex_2000", Agg_Area = "grids.hex_2000", id_column = "gid", Agg_geom = "the_geom", Ex_Area = "osm.berlin_network", label_column = "bikeusage", Ex_geom = "shape")


# connection = con
# result_table_name = "result_bike_hex_2000"
# Agg_Area = "grids.hex_2000"
# id_column = "gid"
# Agg_geom = "the_geom"
# Ex_Area = "osm.berlin_network"
# label_column = "bikeusage"
# Ex_geom = "shape"

#qntfyLinesBike(con, 'public.abz_network_bike_ind', "urmo.abz", "abz_id" , "the_geom", "osm.berlin_network_old", "bikeusage", "shape")

