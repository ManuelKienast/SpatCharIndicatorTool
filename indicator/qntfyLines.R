## Function for qunatification of Line Types
## First calculating the total length of line type per Aggregation area, write those to table
## secondly calculation of ratio of line Type against all selected line Types
## two sets of output columns: 1) the sum of lientype length per aggreagtion area, 2) the ratio of the length of the linetype in comparison
##  to the total length of all lines in the aggregation area
##
## This script contains 6 helper funtions and one to rule them all, with brief explanations those are:
          
       #  1-  createInterSecTable   - writes the intersection table between the lineNetWork and the aggregationArea, e.g. TVZ|PLR|Grid
       #  2-  getVDist              - constructs the list of unique values identifying each line type in one specific column, e.g. osm_type
       #  3-  createResultTable     - sets up the resultTable with the iD and geom of the aggreagtionArea
       #  4-  updateTable           - for each element in the VDist-list adds a col to resultTable and computes the length of line in km
       #  5-  sumLength             - writes the total length of all lines into the table (based on iteratively adding the length of each element of VDist)
       #  6-  ratioLines2Table      - add a new column for each of VDist and compute its ratio [length(i)/length(total)]
       #  7-  qntfyLines            - calls all previous functions, adding the necessary loops.
## 
## Currently, without editing, it is only possible to compute all values occuring in the selected type column.
## the best way to work around would be to write VDist by oneself and remove getVDist from qntyLines

library(RPostgreSQL)
library(rgdal)
library(RODBC)

##
## setting helper functions
##
############################################################################################## 
# -1-  #  ##  ##    Script writing the Intersection Table     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
##  IMPORTANT NOTICE.Personal check WHERE clause if switching between urmo and localhost

createInterSecTable <- function (
                                  connection,
                                  Agg_Area,
                                  id_column,
                                  Agg_geom,
                                  Ex_Area,
                                  label_column,
                                  Ex_geom
                                  ) 
{
  intersectTable <- dbGetQuery(connection, sprintf(
    "
    DROP TABLE IF EXISTS InterSec;
      
    SELECT * INTO public.InterSec FROM(
      SELECT 
        row_number() over (order by 1) as key,
        Agg_Area.%s AS Agg_ID,
        Ex_Area.%s AS LineType,
        --Ex_Area.vmax AS speed,	
        ST_Multi(ST_Intersection(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))::geometry(multiLineString, 25833) as geom
      FROM %s AS Agg_Area
        LEFT JOIN %s AS Ex_Area
          ON (ST_INTERSECTS(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))
      WHERE Ex_Area.%s LIKE '%s'
        AND ST_isValid(Agg_Area.%s) = TRUE
        AND ST_isValid(ST_Transform(Ex_Area.%s, 25833)) = TRUE 
      ) as foo
      ;
      
      ALTER TABLE InterSec ADD PRIMARY KEY (key)
      ;"
      ,
      id_column,                  ## Agg_Area   -- column with the unique Agg_Area_ID e.g. PLR-id
      label_column,               ## label_column.    -- column with linetype specification
      ## Ex_speed,                -- column holding the max speed per line type, or any secondary objects
      Agg_geom, Ex_geom,          ## ST_Multi   -- geometry columns of both Agg and Ex objects
      Agg_Area,                   ## FROM       -- table containing the Aggreation Area geometries 
      Ex_Area,                    ## LEFT JOIN  -- table containing the Examination Object  geometries and information here: lineTypes
      Agg_geom, Ex_geom,          ## ON         -- geometrie columns of both Agg and Ex objects
      label_column, "highway%",   ## WHERE      -- type of Line and query for highway in its description --> its an OSM-special
      Agg_geom, Ex_geom,          ## WHERE      -- geometrie columns of both Agg and Ex objects
      Agg_geom, Ex_geom           ## WHERE      -- geometrie columns of both Agg and Ex objects
    ))
    
    return(intersectTable)
  }




############################################################################################## 
# -2-  #  ##  ##    writing the distinct vector of linetypes     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
## reminder: switch WHERE linetype to 'highway%' for OSM data, otherwise no WHERE is needed

getVDist <- function( 
                      connection
                      )
{
  VDistdf <- dbGetQuery(connection, sprintf(
  "
  SELECT DISTINCT linetype 
  FROM Intersec
  ;"
  ))

VDist <- VDistdf[,1]

return(VDist)    
}





############################################################################################## 
# -3-  #  ##  ##    Create the resultTable & insert grid_id & geom   ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

createResultTable <- function(  connection,
                                  result_table_name,
                                  id_column,
                                  Agg_geom,
                                  Agg_Area
                                  )
 {
    dbGetQuery(connection, sprintf(
    "
    DROP TABLE IF EXISTS %s;
    
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
    result_table_name,       ## DROP  
    id_column,               ## SELECT #1   -- column with the unique Agg_Area_ID e.g. PLR-id  
    Agg_geom,                ## SELECT #2   -- geometrie columns of Agg_Area
    result_table_name,       ## INTO
    Agg_Area,                ## FROM        -- table containing the Aggreation Area geometries 
    Agg_geom, Agg_geom,      ## WHERE       -- geometry columns of Agg_Area 
    result_table_name        ## ALTER TABLE
    ))  
 }
 



  
############################################################################################## 
# -4-  #  ##  ##    Update resultTable with the length of lines     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
## TROUBLE cannot loop through the necessary VDIST renamed 2 way_whatever and the necessary way.whatever for selection
## of distinct values simultaneously, need to update the loop or else

updateTable <- function(  connection,
                            vDist,
                            result_table_name
                            ) 
  {
    dbGetQuery(connection, sprintf( 
      
      "ALTER TABLE %s DROP COLUMN IF EXISTS sum_%s;
      ALTER TABLE %s ADD COLUMN sum_%s FLOAT;
      
      UPDATE %s 
        SET sum_%s = foo.sum_%s
          FROM (
            SELECT 
              Agg_ID,
              SUM(ST_Length(geom))/1000 AS sum_%s
            FROM InterSec
            WHERE lineType = '%s'
            GROUP BY Agg_ID
            ORDER BY Agg_ID
          ) as foo
        WHERE %s.Agg_ID = foo.Agg_ID
      ;"
      ,
      result_table_name, gsub('\\.','_',vDist),      ## ALTER DROP COl
      result_table_name, gsub('\\.','_',vDist),      ## ALTER ADD COl     -- vector containing distinct values
       
      result_table_name,                             ## UPDATE
      gsub('\\.','_',vDist), gsub('\\.','_',vDist),  ## SET          -- vector containing distinct values
      gsub('\\.','_',vDist),                         ## SUM          -- vector containing distinct values      
      vDist,                                         ## WHERE  IN SELECT (foo)
      result_table_name                              ## WHERE        -- vector containing distinct values 
      ))
 }

  
  
  
############################################################################################## 
# -5-  #  ##  ##    calculate the sum(length) of all lines in aggregationArea   ##  ##  ##  ##  ##  ##
##############################################################################################
  
sumLength <- function( connection,
                       vDist,
                       result_table_name
                       )
  {
  sumLength <- dbGetQuery(connection, sprintf(
   "
    UPDATE %s
      SET sum_length = COALESCE(sum_length,0)+COALESCE(sum_%s,0)  -- summation of all values listed in the V(Dist)
    ;"
    ,
    result_table_name,
    vDist
    ))
  }




############################################################################################## 
# -6-  #  ##  ##    calculate the ratios and write them to resultTable    ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

ratioLines2Table <- function(
                              connection,
                              result_table_name,
                              vDist
                              ) 
  {
    calcRatios <- dbGetQuery(connection, sprintf( 
      "
      ALTER TABLE %s DROP COLUMN IF EXISTS ratio_%s;
      ALTER TABLE %s ADD COLUMN ratio_%s FLOAT;
  
      UPDATE %s 
        SET ratio_%s = sum_%s/sum_length
      ;"
      ,
      result_table_name, vDist,  ## ALTER TABLE DROP COl     -- vector containing distinct values
      result_table_name, vDist,  ## ALTER TABLE ADD COL      -- vector containing distinct values
      result_table_name,         ## UPDATE
      vDist, vDist               ## SET          -- vector containing distinct values
    ))
}
  



############################################################################################## 
# -7-  #  ##  ##    compilation of all the little helpers     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

qntfyLines <- function (
                        connection,
                        result_table_name,
                        Agg_Area,
                        id_column,
                        Agg_geom,
                        Ex_Area,
                        label_column,
                        Ex_geom
                        )
{
  createInterSecTable(connection, Agg_Area, id_column, Agg_geom, Ex_Area, label_column, Ex_geom)

  vDist <- getVDist(connection)

  vDistName <- gsub('\\.','_',vDist)

  resultTable <- createResultTable(connection, result_table_name, id_column, Agg_geom, Agg_Area)

  for (i in vDist) {updateTable(connection, i, result_table_name)}

  addSumLengthCol <- dbGetQuery(connection, sprintf("ALTER TABLE %s DROP COLUMN IF EXISTS sum_length;
                                                  ALTER TABLE %s ADD COLUMN sum_length FLOAT;", result_table_name, result_table_name))
  
  for (i in vDistName) {sumLength(connection, i, result_table_name)}

  for (i in vDistName) {ratioLines2Table(connection, result_table_name, i)}
}

#USAGE:
#qntfyLines(con, Agg_Area, id_column, Agg_geom, Ex_Area, label_column, Ex_geom)

  






# 