## Function for qunatification of Line Types
## First:  calculation of the total length of each line type per Aggregation area & writing of those to the resutl_table_name
## Second: calculation of the ratio of the length of each line Type against the combined length of all selected line Types
## Output: two sets of columns: 
##        1) the sum of the length of each linetype per aggreagtion/grid area, 
##        2) the ratio of the length of sum of each linetype in comparison to the total length of all lines in the aggregation area


## This script contains 6 helper funtions and one to rule them all, with brief explanations those are:
          
       #  1-  createInterSecTable   - writes the intersection table between the lineNetWork(edge_table_name) and the aggregationArea(grid_name), e.g. TVZ|PLR|Grid
       #  2-  getVDist              - constructs the list of unique values identifying each line type in one specific column, e.g. osm_type
       #  3-  createResultTable     - sets up the resultTable with the iD and geom of the aggreagtionArea
       #  4-  updateTable           - for each element in the VDist-list adds a col to resultTable and computes the length of line in km
       #  5-  sumLength             - writes the total length of all lines into the table (based on iteratively adding the length of each element of VDist)
       #  6-  ratioLines2Table      - add a new column for each of VDist and compute its ratio [length(i)/length(total)]
       #  7-  qntfyLines            - calls all previous functions, adding the necessary loops.
## 
## Currently, without editing, it is only possible to compute all values occuring in the selected type column.
## the best way to work around would be to write VDist by oneself and remove getVDist from qntyLines


###### PARAMETERS #################################

#' @param connection             A connection to the PostGIS database.
#' @param result_table_schema    -String- the schema of the table in which the results are written, will be created
#' @param resultTable_name      -String- the name of the table in which the results are written, will be created
#' @param edge_table_name        -String- the name of the table containing the edge/line-geoms; if other then public-schema: table_name --> schema.table_name
#' @param edge_type_col          -String- the column which defines the line/edge - types, e.g. osm_type
#' @param edge_geom              -String- the column holding the geometries of the edges/lines
#' @param grid_name              -String- the name of the grid/aggregation table, e.g. fish_2000 / TVZ, if not in public. the schema needs to be specified, i.e. schema.grid_name
#' @param grid_id                -String- the column with the unique grid-cell id
#' @param grid_geom              -String- the column holding the grid geometries


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
##  IMPORTANT NOTICE.  PLZ be advised that the WHERE-clause in funct "createInterSecTable" is important, as it stands
##                     it needs to be adapted to the needs aka the line type to be quantified and the network used
##                     In its current iteration this funct. tries to qntfy highway%s., which are intermixed in the berlin_network with types of railway.%s
##                     Therefore the WHERE-clause filters for all line types LIKE (highway.)
##                     If the funct is to used more generically this WHERE-clause NEEDS to be adapted to the needs of the user,
##                     e.g. qntfcation of specified bike lanes with just a yes|no choice, in that case it needs to be commented out.



createInterSecTable(con, "bz_network_bike_ind", "urmo.bz", "bz_id" , "the_geom", "osm.berlin_network_old", "bikeusage", "shape")
 

createInterSecTable <- function (
                                  connection,
                                  resultTable_name,
                                  grid_name, grid_id, grid_geom,
                                  edge_table_name, edge_type_col, edge_geom
                                  ) 
{
  intersectTable <- dbGetQuery(connection, sprintf(
    "
    DROP TABLE IF EXISTS public.%s_interSect;
      
    SELECT * INTO public.%s_interSect FROM(
      SELECT 
        row_number() over (order by 1) as key,
        Agg_Area.%s AS Agg_ID,
        Ex_Area.%s AS LineType,
        ST_Multi(ST_Intersection(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))::geometry(multiLineString, 25833) as geom
      FROM %s AS Agg_Area
        LEFT JOIN %s AS Ex_Area
          ON (ST_INTERSECTS(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))
      -- WHERE Ex_Area.%s LIKE '%s'
      ) as foo
      ;
      
      ALTER TABLE %s_interSect ADD PRIMARY KEY (key)
      ;"
      ,
      resultTable_name,           ## DROP TABLE IF
      resultTable_name,           ## SELECT * INTO
      grid_id,                    ## Agg_Area   -- column with the unique Agg_Area_ID e.g. PLR-id
      edge_type_col,              ## edge_type_col.    -- column with linetype specification
      grid_geom, edge_geom,       ## ST_Multi   -- geometry columns of both Agg and Ex objects
      grid_name,                  ## FROM       -- table containing the Aggreation Area geometries 
      edge_table_name,            ## LEFT JOIN  -- table containing the Examination Object  geometries and information here: lineTypes
      grid_geom, edge_geom,       ## ON         -- geometrie columns of both Agg and Ex objects
      edge_type_col, "highway%",  ## WHERE      -- type of Line and query for highway in its description --> its an OSM-special
      resultTable_name            ## ALTER TABLE
    ))
    
    return(intersectTable)
  }




############################################################################################## 
# -2-  #  ##  ##    writing the distinct vector of linetypes     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
## reminder: switch WHERE linetype to 'highway%' for OSM data, otherwise no WHERE is needed

getVDist <- function( 
                      connection,
                      resultTable_name
                      )
{
  vDistdf <- dbGetQuery(connection, sprintf(
  "
  SELECT DISTINCT linetype 
  FROM %s_interSect
  ;"
  ,
  resultTable_name
  ))

  return(vDistdf)    
}





############################################################################################## 
# -3-  #  ##  ##    Create the resultTable & insert grid_id & geom   ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

createResultTable <- function(  connection,
                                  result_table_schema, resultTable_name,
                                  grid_id,
                                  grid_geom,
                                  grid_name
                                  )
 {
    dbGetQuery(connection, sprintf(
    "
    DROP TABLE IF EXISTS %s.%s;
    
    SELECT 
      row_number() over (order by 1) as key,
      %s AS Agg_Id,
      %s AS geom
    INTO %s.%s
    FROM %s AS Agg_Area
    WHERE ST_isValid(Agg_Area.%s) = TRUE
      AND ST_isSimple(Agg_Area.%s) = TRUE
    ;
    
    ALTER TABLE %s.%s ADD PRIMARY KEY (key)
    ;"
    ,
    result_table_schema, resultTable_name,   ## DROP  
    grid_id,                                  ## SELECT #1   -- column with the unique Agg_Area_ID e.g. PLR-id  
    grid_geom,                                ## SELECT #2   -- geometrie columns of Agg_Area
    result_table_schema, resultTable_name,   ## INTO
    grid_name,                                ## FROM        -- table containing the Aggreation Area geometries 
    grid_geom, grid_geom,                     ## WHERE       -- geometry columns of Agg_Area 
    result_table_schema, resultTable_name    ## ALTER TABLE
    ))  
 }
 

# USAGE:
## createResultTable( con, "public", "rent_asl_tvz", "code", "geom", "urmo.tvz12")

  
############################################################################################## 
# -4-  #  ##  ##    Update resultTable with the length of lines     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
## TROUBLE cannot loop through the necessary VDIST renamed 2 way_whatever and the necessary way.whatever for selection
## of distinct values simultaneously, need to update the loop or else

updateTable <- function(  connection,
                          vDist,
                          result_table_schema, resultTable_name
                          ) 
  {
    dbGetQuery(connection, sprintf( 
      
      "ALTER TABLE %s.%s DROP COLUMN IF EXISTS sum_%s;
      ALTER TABLE %s.%s ADD COLUMN sum_%s FLOAT;
      
      UPDATE %s.%s 
        SET sum_%s = foo.sum_%s
          FROM (
            SELECT 
              Agg_ID,
              SUM(ST_Length(geom))/1000 AS sum_%s
            FROM %s_interSect
            WHERE lineType = '%s'
            GROUP BY Agg_ID
            ORDER BY Agg_ID
          ) as foo
        WHERE %s.Agg_ID = foo.Agg_ID
      ;"
      ,
      result_table_schema, resultTable_name, gsub('\\.','_',vDist),  ## ALTER DROP COl
      result_table_schema, resultTable_name, gsub('\\.','_',vDist),  ## ALTER ADD COl     -- vector containing distinct values
       
      result_table_schema, resultTable_name,                         ## UPDATE
      gsub('\\.','_',vDist), gsub('\\.','_',vDist),                   ## SET          -- vector containing distinct values
      gsub('\\.','_',vDist),                                          ## SUM          -- vector containing distinct values      
      resultTable_name,                                              ## FROM 
      vDist,                                                          ## WHERE  IN SELECT (foo)
      resultTable_name                                               ## WHERE        -- vector containing distinct values 
      ))
 }

  
  
  
############################################################################################## 
# -5-  #  ##  ##    calculate the sum(length) of all lines in aggregationArea   ##  ##  ##  ##  ##  ##
##############################################################################################
  
sumLength <- function( connection,
                       vDist,
                       result_table_schema, resultTable_name
                       )
  {
  sumLength <- dbGetQuery(connection, sprintf(
   "
    UPDATE %s.%s
      SET sum_length = COALESCE(sum_length,0)+COALESCE(sum_%s,0)  -- summation of all values listed in the V(Dist)
    ;"
    ,
    result_table_schema, resultTable_name,
    vDist
    ))
  }




############################################################################################## 
# -6-  #  ##  ##    calculate the ratios and write them to resultTable    ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

ratioLines2Table <- function(
                              connection,
                              result_table_schema, resultTable_name,
                              vDist
                              ) 
  {
    calcRatios <- dbGetQuery(connection, sprintf( 
      "
      ALTER TABLE %s.%s DROP COLUMN IF EXISTS ratio_%s;
      ALTER TABLE %s.%s ADD COLUMN ratio_%s FLOAT;
  
      UPDATE %s.%s 
        SET ratio_%s = sum_%s/sum_length
      ;"
      ,
      result_table_schema, resultTable_name, vDist,  ## ALTER TABLE DROP COl     -- vector containing distinct values
      result_table_schema, resultTable_name, vDist,  ## ALTER TABLE ADD COL      -- vector containing distinct values
      result_table_schema, resultTable_name,         ## UPDATE
      vDist, vDist                                    ## SET          -- vector containing distinct values
    ))
}
  



############################################################################################## 
# -7-  #  ##  ##    compilation of all the little helpers     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

qntfyLines <- function (
                        connection,
                        result_table_schema, resultTable_name,
                        edge_table_name, edge_type_col, edge_geom,
                        grid_name, grid_id, grid_geom
                        )
{
  createInterSecTable(connection, resultTable_name, grid_name, grid_id, grid_geom, edge_table_name, edge_type_col, edge_geom)

  vDistdf <- getVDist(connection, resultTable_name)
  
  VDist <- vDistdf[ , 1]

  vDistName <- gsub('\\.','_',vDist)

  resultTable <- createResultTable(connection, result_table_schema, resultTable_name, grid_id, grid_geom, grid_name)

  for (i in vDist) {updateTable(connection, i, result_table_schema, resultTable_name)}

  addSumLengthCol <- dbGetQuery(connection, sprintf("ALTER TABLE %s.%s DROP COLUMN IF EXISTS sum_length;
                                                    ALTER TABLE %s.%s ADD COLUMN sum_length FLOAT
                                                    ;"
                                                    , result_table_schema, resultTable_name,result_table_schema,  resultTable_name))
  
  for (i in vDistName) {sumLength(connection, i, result_table_schema, resultTable_name)}

  for (i in vDistName) {ratioLines2Table(connection, result_table_schema, resultTable_name, i)}
}


#USAGE:
#qntfyLines <- function (connection,result_table_schema, resultTable_name, edge_table_name, edge_type_col, edge_geom,
#                        grid_name, grid_id, grid_geom)
# qntfyLines(con, "public", "a_test_qnfyLines", "osm.berlin_network", "osm_type", "shape", "grids.fish_4000", "gid", "the_geom")

qntfyLines <- function (
  connection,
  result_table_schema, resultTable_name,
  edge_table_name, edge_type_col, edge_geom,
  grid_name, grid_id, grid_geom
)

qntfyLines(con, "public", "bz_network_bike_ind", "osm.berlin_network_old", "bikeusage", "shape", "urmo.bz", "bz_id" , "the_geom")
