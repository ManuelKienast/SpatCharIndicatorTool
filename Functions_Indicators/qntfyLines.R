
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



qntfyLines <- function (
              connection = con,
              Agg_Area ="planungsraum_mitte",
              Agg_ID = "schluessel",
              Agg_geom = "geom",
              Ex_Area = "strassennetzb_rbs_od_blk_2015_mitte",
              Ex_Obj = "strklasse",
              Ex_geom = "geom") 
  {
  
  intersectTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS InterSec;

    SELECT * INTO InterSec FROM
      ( SELECT 
        Agg_Area.%s AS Agg_ID,
        Ex_Obj.%s AS LineType,
        --Ex_Obj.vmax AS speed,	
        ST_Multi(ST_Intersection(Agg_Area.%s, Ex_Obj.%s))::geometry(multiLineString, 25833) as geom
          FROM
            planungsraum_mitte AS Agg_Area
            LEFT JOIN strassennetzb_rbs_od_blk_2015_mitte AS Ex_Obj
            ON (ST_INTERSECTS(Agg_Area.geom, ST_Transform(Ex_Obj.geom, 25833)))
      ) as foo;
    
    ALTER TABLE InterSec ADD COLUMN key_column SERIAL PRIMARY KEY;",
    
    Agg_ID,          ## Agg_Area    -- column with the unique Agg_Area_ID e.g. PLR-id
    Ex_Obj,          ## Ex_Obj.     -- column with linetype specification
    ## Ex_speed,                    -- column holding the max speed per line type, or any secondary objects
    Agg_geom, Ex_geom,  ## ST_Multi -- geometrie columns of both Agg and Ex objects
    Agg_Area,   ## planungsraum_mitte    -- table containing the Aggreation Area geometries 
    Ex_Area,     ## LEFT JOIN       -- table caontaing the Examination Object  geometries and information here: lineTypes
    Agg_geom, Ex_geom  ## ON        -- geometrie columns of both Agg and Ex objects
    ))
intersectTable


##-- Select for creation of the R-vector to loop through for distance calcs

  VectorDist <- dbGetQuery(connection, sprintf(
    "SELECT DISTINCT linetype 
    FROM Intersec 
    
    ;"
    
    
  ))
  VectorDist

}

qntfyLines()



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

lapply(VectorDist, function(x) ((x)+2))



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