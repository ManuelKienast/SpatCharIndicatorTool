
## Function for qunatification of Line Types
## First calculating the total length of line type per Aggregation area, write those to table
## secondly calculation of ratio of line Type against all selected line Types
##
## Option for selection of which line types to calc or to choose ALL the lines



setwd("d:\\Manuel\\git\\Urmo-SpatCharIndicatorTool")
library(RPostgreSQL)
library(rgdal)
library(RODBC)

## Creating the db connection
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "DLR", host = "localhost", port= "5432", user = "postgres", password = "postgres") 
dbListTables(con)





## setting helper functions

##########  FUNCTION  ##########
## getting the vector of dictinct variables from Agg_Area table

  getVDist <- function (con
                        )
    {VDistdf <- dbGetQuery(connection, sprintf(
      "SELECT DISTINCT linetype 
      FROM Intersec 
      ;"))
  
    VDist <- VDistdf[,1]
    return(VDist)    
   }

  getVDist()

  

##########  FUNCTION  ##########  
## writing intersection table
  
  createInterSecTable <- function (
    connection = con,
    Agg_Area ="planungsraum_mitte",
    Agg_ID = "schluessel",
    Agg_geom = "geom",
    Ex_Area = "strassennetzb_rbs_od_blk_2015_mitte",
    Ex_Obj = "strklasse",
    Ex_geom = "geom"
  ) 
  {
    
    intersectTable <- dbGetQuery(connection, sprintf(
      
      "DROP TABLE IF EXISTS InterSec;
      
      SELECT * INTO InterSec FROM
      ( SELECT 
      row_number() over (order by 1) as key,
      Agg_Area.%s AS Agg_ID,
      Ex_Obj.%s AS LineType,
      --Ex_Obj.vmax AS speed,	
      ST_Multi(ST_Intersection(Agg_Area.%s, Ex_Obj.%s))::geometry(multiLineString, 25833) as geom
      FROM
      planungsraum_mitte AS Agg_Area
      LEFT JOIN strassennetzb_rbs_od_blk_2015_mitte AS Ex_Obj
      ON (ST_INTERSECTS(Agg_Area.geom, ST_Transform(Ex_Obj.geom, 25833)))
      ) as foo;
      
      ALTER TABLE InterSec ADD PRIMARY KEY (key);",
      
      Agg_ID,          ## Agg_Area    -- column with the unique Agg_Area_ID e.g. PLR-id
      Ex_Obj,          ## Ex_Obj.     -- column with linetype specification
      ## Ex_speed,                    -- column holding the max speed per line type, or any secondary objects
      Agg_geom, Ex_geom,  ## ST_Multi -- geometrie columns of both Agg and Ex objects
      Agg_Area,   ## planungsraum_mitte    -- table containing the Aggreation Area geometries 
      Ex_Area,     ## LEFT JOIN       -- table caontaing the Examination Object  geometries and information here: lineTypes
      Agg_geom, Ex_geom  ## ON        -- geometrie columns of both Agg and Ex objects
    ))
    
    return(intersectTable)
  }
  
  
  
##########  FUNCTION  ##########  
## writing results table
## create result table with Agg_Area_Id and its geom to select other results into
  
  createResultTable <- function (
                           Agg_ID,
                           Agg_geom,
                           Agg_Area
                          )
 {   resultTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS result;
    
  SELECT 
    row_number() over (order by 1) as test,
    %s AS Agg_Id,
    %s 
      INTO result 
      FROM %s AS Agg_Area;
    
    ALTER TABLE result ADD PRIMARY KEY (key);
    ",
    
    Agg_ID,       ## SELECT #1   -- column with the unique Agg_Area_ID e.g. PLR-id  
    Agg_geom,     ## SELECT #2   -- geometrie columns of Agg_Area
    Agg_Area      ## FROM        -- table containing the Aggreation Area geometries 
  
    ))  
  
  return(resultTable)
 }
 
   resultTable <- 

     createResultTable(Agg_ID, Agg_geom, Agg_Area)
  
  
##########  FUNCTION  ##########
## updating a table (create and fill columns)
## containing the lengths of lines per aggregation Area
  
  updateTable <- function (
    
    connection = con,          
    x
    ##VDist = VDist ## vector containing the distinct values to loop through for updating the table with
  ) 
  {
    
    UpdateLength <- dbGetQuery(connection, sprintf( 
      
      "ALTER TABLE result ADD COLUMN sum_%s FLOAT;
      
      UPDATE result 
      SET sum_%s = foo.sum_%s
      FROM (SELECT 
      Agg_ID,
      SUM(ST_Length(geom))/1000 AS sum_%s
      FROM InterSec
      WHERE lineType = '%s'
      GROUP BY Agg_ID
      ORDER BY Agg_ID
      ) as foo
      WHERE result.Agg_ID = foo.Agg_ID
      ;"
      ,
      x,         ## ALTER TABLE  -- vector containing distinct values
      x, x,  ## SET          -- vector containing distinct values
      x,         ## SUM          -- vector containing distinct values      
      X          ## WHERE        -- vector containing distinct values
      
      
    ))
  }
  
  ,
  VDist,         ## ALTER TABLE  -- vector containing distinct values
  VDist, VDist,  ## SET          -- vector containing distinct values
  VDist,         ## SUM          -- vector containing distinct values      
  VDist          ## WHERE        -- vector containing distinct values  
  

  
  
    
##########  FUNCTION  ##########  
## setting Function for line quantification
 
 
  
intersectTable <- createInterSecTable()




##-- Select for creation of the R-vector to loop through for distance calcs

  VDist <- getVDist()

  

  
  
  
  
##  -- loop through this using the V(Distinct); calc total length of items listed in vector(Dist) and write to table
  
  


qntfyLines()


x <- c("G","B")
x
for ( i in x ) {updateTable(i)}



#################### PLAYGORUND ##################### 
############### BEWARE OF STRAY FUNCTS ##############

VectorDist <- dbGetQuery(con, sprintf("SELECT DISTINCT linetype FROM Intersec;"))
str(VectorDist)

veclist <- VectorDist[,1]
str(veclist)

for (i in veclist)  {
  x = paste(i,2)
  print(x)
  }

lapply(VectorDist, function(x) paste(x,2))



########################################################################################################
########################################################################################################
##   RAW SQL - Code
########################################################################################################


--- Create InterSec table holding Linestrings cut to Agg_Area-size tagged with Agg_area_ID
DROP TABLE IF EXISTS InterSec;
SELECT * INTO InterSec FROM (
  SELECT 
  Agg_Area.schluessel AS Agg_ID,
  Ex_Obj.strklasse AS LineType,
  --Ex_Obj.vmax AS speed,	
  ST_Multi(ST_Intersection(Agg_Area.geom, Ex_Obj.geom))::geometry(multiLineString, 25833) as geom
  FROM
  planungsraum_mitte AS Agg_Area LEFT JOIN 
  strassennetzb_rbs_od_blk_2015_mitte AS Ex_Obj
  ON (ST_INTERSECTS(Agg_Area.geom, ST_Transform(Ex_Obj.geom, 25833)))
) as foo;

--- Adds a pKey to the table as SERIAL
ALTER TABLE InterSec ADD COLUMN key_column SERIAL PRIMARY KEY;
SELECT * FROM InterSec;

-- Select for creation of the R-vector to loop through for distance calcs
SELECT DISTINCT linetype 
FROM Intersec
WHERE linetype LIKE 'highway%'
;

-- create result table with Agg_Area_Id and its geom to select othe results into
DROP TABLE IF EXISTS result;
SELECT schluessel AS Agg_Id, geom 
INTO result 
FROM planungsraum_mitte AS Agg_Area;
SELECT * FROM RESULT;

-- loop through this using the V(Distinct); calc total length of items listed in vector(Dist) and write to table

ALTER TABLE result ADD COLUMN sum_G FLOAT;

UPDATE result 
SET sum_G = foo.sum_G
FROM (SELECT 
      Agg_ID,
      SUM(ST_Length(geom))/1000 AS sum_G
      FROM InterSec
      WHERE lineType = 'G'
      GROUP BY Agg_ID
      ORDER BY Agg_ID
) as foo
WHERE result.Agg_ID = foo.Agg_ID
;

-- calc the total length of selected line types

ALTER TABLE result ADD COLUMN sum_length FLOAT;
UPDATE result 
SET sum_length = sum_g  -- summation of all values listed in the V(Dist)
;

--- loop adding the columns for the ratios and then filling them with value(dist)/sum_length


SELECT * FROM result
ORDER BY Agg_ID;