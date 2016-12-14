## Function for qunatification of Line Types
## First calculating the total length of line type per Aggregation area, write those to table
## secondly calculation of ratio of line Type against all selected line Types
##
## Option for selection of which line types to calc or to choose ALL the lines



# # FOR PERSONAL USE
# ## Creating the db connection
# drv <- dbDriver("PostgreSQL")
# connection <- dbConnect(drv, dbname = "DLR", host = "localhost", port= "5432", user = "postgres", password = "postgres")
# dbListTables(connection)


# ## Defintion of Variables:
# connection = con
# Agg_Area ="planungsraum_mitte"
# Agg_ID = "schluessel"
# Agg_geom = "geom"
# Ex_Area = "strassennetzb_rbs_od_blk_2015_mitte"
# Ex_Obj = "strklasse"
# Ex_geom = "geom"

#setwd("d:\\Manuel\\git\\Urmo-SpatCharIndicatorTool")
library(RPostgreSQL)
library(rgdal)
library(RODBC)




## setting helper functions
##
##########  FUNCTION  ##########  
## writing intersection table
##
##  IMPORTANT NOTICE.Personal check WHERE clause if switching between urmo and localhost
##
  
createInterSecTable <- function (
    connection,
    Agg_Area,
    Agg_ID,
    Agg_geom,
    Ex_Area,
    Ex_Obj,
    Ex_geom
  ) 
  {
    
    intersectTable <- dbGetQuery(connection, sprintf(
      
      "DROP TABLE IF EXISTS InterSec;
      
      SELECT * INTO public.InterSec FROM
      (SELECT 
        row_number() over (order by 1) as key,
        Agg_Area.%s AS Agg_ID,
        Ex_Area.%s AS LineType,
        --Ex_Area.vmax AS speed,	
        ST_Multi(ST_Intersection(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))::geometry(multiLineString, 25833) as geom
          FROM
            %s AS Agg_Area
            LEFT JOIN %s AS Ex_Area
              ON (ST_INTERSECTS(Agg_Area.%s, ST_Transform(Ex_Area.%s, 25833)))
                
                WHERE (
                
                Ex_Area.osm_type LIKE ('%ssecondary') OR
                Ex_Area.osm_type LIKE ('%stertiary') OR
                Ex_Area.osm_type LIKE ('%sprimary') OR
                Ex_Area.osm_type LIKE ('%sresidential') OR
                Ex_Area.osm_type LIKE ('%sunclassified') OR
                Ex_Area.osm_type LIKE ('%slivingstreet') )
                
                AND Ex_Area.%s NOT LIKE '%s' AND
                ST_isValid(Agg_Area.%s) = TRUE AND ST_isValid(ST_Transform(Ex_Area.%s, 25833)) = TRUE 
                
      ) as foo
      
      ;
      
      ALTER TABLE InterSec ADD PRIMARY KEY (key);",
      
      Agg_ID,                       ## Agg_Area   -- column with the unique Agg_Area_ID e.g. PLR-id
      Ex_Obj,                       ## Ex_Obj.    -- column with linetype specification
      ## Ex_speed,                        -- column holding the max speed per line type, or any secondary objects
      Agg_geom, Ex_geom,            ## ST_Multi   -- geometrie columns of both Agg and Ex objects
      Agg_Area,                     ## FROM       -- table containing the Aggreation Area geometries 
      Ex_Area,                      ## LEFT JOIN  -- table containing the Examination Object  geometries and information here: lineTypes
      Agg_geom, Ex_geom,            ## ON         -- geometrie columns of both Agg and Ex objects
      "%", "%", "%", "%", "%", "%", ## set wildcards in the select to get aroubd the . in highway. bla
      Ex_Obj, "track;%",            ## WHERE      -- type of Line and query for highway in its description --> its an OSM-special
      Agg_geom, Ex_geom             ## WHERE      -- geometrie columns of both Agg and Ex objects

    ))
    
    return(intersectTable)
    
    
  }
  



#qntfyLines(con, Agg_Area, Agg_ID, Agg_geom, Ex_Area, Ex_Obj, Ex_geom)
#
#



##########  FUNCTION  ##########  
## writing results table
## create result table with Agg_Area_Id and its geom to select other results into
  
  createResultTable <- function (
                           connection,
                           Agg_ID,
                           Agg_geom,
                           Agg_Area
                          )
 {resultTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS result;
    
    SELECT 
      row_number() over (order by 1) as key,
      %s AS Agg_Id,
      %s AS geom
        INTO public.result 
        FROM %s AS Agg_Area
        WHERE ST_isValid(Agg_Area.%s) = TRUE AND ST_isSimple(Agg_Area.%s) = TRUE
    ;
    
    ALTER TABLE result ADD PRIMARY KEY (key);"
    ,
    Agg_ID,       ## SELECT #1   -- column with the unique Agg_Area_ID e.g. PLR-id  
    Agg_geom,     ## SELECT #2   -- geometrie columns of Agg_Area
    Agg_Area,     ## FROM        -- table containing the Aggreation Area geometries 
    Agg_geom, Agg_geom      ## WHERE       -- geometrie columns of Agg_Area
    ))  
  
  return(resultTable)
 
 }
 

##########  FUNCTION  ##########
## getting the vector of dictinct variables from Agg_Area table
## reminder: switch WHERE linetype to 'highway%' for OSM data, otherwise no WHERE is needed

getVDist <- function (connection)

  {VDistdf <- dbGetQuery(connection, sprintf(
    
    "SELECT DISTINCT cycleway 
    FROM osm.berlin_network
    WHERE cycleway NOT LIKE '%s' AND cycleway != 'none'
    ;"
    ,
    "track\\;%"))
  
VDist <- VDistdf[,1]

return(VDist)    
}


##########  FUNCTION  ##########
## updating a table (create and fill columns)
## containing the lengths of lines per aggregation Area
##
## TROUBLE cannot loop through the necessary VDIST renamed 2 way_whatever and the necessary way.whatever for selection
## of distinct values simultaneously, need to update the loop or else
##

  
  updateTable <- function (
                      connection,
                      VDist
                          ) 
  {UpdateLength <- dbGetQuery(connection, sprintf( 
      
      "ALTER TABLE result DROP COLUMN IF EXISTS sum_%s;
      ALTER TABLE result ADD COLUMN sum_%s FLOAT;
      UPDATE result 
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
      WHERE result.Agg_ID = foo.Agg_ID
      
      ;"
      ,
      gsub('\\.','_',VDist) ,         ## DROP COl     -- vector containing distinct values
      gsub('\\.','_',VDist),         ## ALTER TABLE  -- vector containing distinct values
      gsub('\\.','_',VDist), gsub('\\.','_',VDist),  ## SET          -- vector containing distinct values
      gsub('\\.','_',VDist),         ## SUM          -- vector containing distinct values      
      VDist              ## WHERE        -- vector containing distinct values 
      ))
 
 }


##########  FUNCTION  ##########  
## inserting the total length into Table results
## calc the total length of selected line types

  sumLength <- function (
                          connection,
                          VDist
                                )
  {sumLength <- dbGetQuery(connection, sprintf(
    
    "UPDATE result
    SET sum_length = COALESCE(sum_length,0)+COALESCE(sum_%s,0)  -- summation of all values listed in the V(Dist)
    
    ;"
    ,
    VDist
    ))
  }



##########  FUNCTION  ##########  
## setting Function for line quantification

ratioLines2Table <- function (
                              connection,
                              VDist
                                    ) 
{   calcRatios <- dbGetQuery(connection, sprintf( 
  
      "ALTER TABLE result DROP COLUMN IF EXISTS ratio_%s;
      ALTER TABLE result ADD COLUMN ratio_%s FLOAT;
  
      UPDATE result 
      SET ratio_%s = sum_%s/sum_length
      ;"
      ,
      VDist,         ## DROP COl     -- vector containing distinct values
      VDist,         ## ALTER TABLE  -- vector containing distinct values
      VDist, VDist   ## SET          -- vector containing distinct values
    ))
}
  


##########  FUNCTION  ##########  
## the complete Function

qntfyLinesBike <- function (
                        connection,
                        result_table_name,
                        Agg_Area,
                        Agg_ID,
                        Agg_geom,
                        Ex_Area,
                        Ex_Obj,
                        Ex_geom
                        )

{
intersectTable <- createInterSecTable(connection, Agg_Area, Agg_ID, Agg_geom, Ex_Area, Ex_Obj, Ex_geom)


resultTable <- createResultTable(connection, Agg_ID, Agg_geom, Agg_Area)


VDist <- getVDist(connection)

VDistname <- gsub('\\.','_',VDist)


for (i in VDist) {updateTable(connection, i)}


addSumLengthCol <- dbGetQuery(connection, sprintf("ALTER TABLE result DROP COLUMN IF EXISTS sum_length;
                                                  ALTER TABLE result ADD COLUMN sum_length FLOAT;"))
  
for (i in VDistname) {sumLength(connection, i)}

for (i in VDistname) {ratioLines2Table(connection, i)}

}


#qntfyLinesBike(connection = connection, Agg_Area = "urmo.plr", Agg_ID = "plr_id", Agg_geom = "the_geom", Ex_Area = "osm.berlin_network",
#           Ex_Obj = "cycleway", Ex_geom = "shape")

# 
# ## Defintion of Variables:

# Agg_Area ="urmo.plr"
# Agg_ID = "plr_id"
# Agg_geom = "the_geom"
# Ex_Area = "osm.berlin_network"
# Ex_Obj = "cycleway"
# Ex_geom = "shape"


##########  FUNCTION  ##########  
## disconnect all cons

closeOpenPSQLConnections <- function(){
  
  all_cons <- dbListConnections(PostgreSQL())
  for(con in all_cons)
    +  dbDisconnect(con) 
}

closeOpenPSQLConnections()


# #################### PLAYGORUND ##################### 
# ############### BEWARE OF STRAY FUNCTS ##############
# 
# VectorDist <- dbGetQuery(con, sprintf("SELECT DISTINCT linetype FROM Intersec;"))
# str(VectorDist)
# 
# veclist <- VectorDist[,1]
# str(veclist)
# 
# for (i in veclist)  {
#   x = paste(i,2)
#   print(x)
#   }
# 
# lapply(VectorDist, function(x) paste(x,2))
# 
# ?read.delim()
# ?cbind()
# ?dim
# ?na.rm
# 
# ########################################################################################################
# ########################################################################################################
# ##   RAW SQL - Code
# ########################################################################################################
# 
# 
# --- Create InterSec table holding Linestrings cut to Agg_Area-size tagged with Agg_area_ID
# DROP TABLE IF EXISTS InterSec;
# SELECT * INTO InterSec FROM (
#   SELECT 
#   Agg_Area.schluessel AS Agg_ID,
#   Ex_Obj.strklasse AS LineType,
#   --Ex_Obj.vmax AS speed,	
#   ST_Multi(ST_Intersection(Agg_Area.geom, Ex_Obj.geom))::geometry(multiLineString, 25833) as geom
#   FROM
#   planungsraum_mitte AS Agg_Area LEFT JOIN 
#   strassennetzb_rbs_od_blk_2015_mitte AS Ex_Obj
#   ON (ST_INTERSECTS(Agg_Area.geom, ST_Transform(Ex_Obj.geom, 25833)))
# ) as foo;
# 
# --- Adds a pKey to the table as SERIAL
# ALTER TABLE InterSec ADD COLUMN key_column SERIAL PRIMARY KEY;
# SELECT * FROM InterSec;
# 
# -- Select for creation of the R-vector to loop through for distance calcs
# SELECT DISTINCT linetype 
# FROM Intersec
# WHERE linetype LIKE 'highway%'
# ;
# 
# -- create result table with Agg_Area_Id and its geom to select othe results into
# DROP TABLE IF EXISTS result;
# SELECT schluessel AS Agg_Id, geom 
# INTO result 
# FROM planungsraum_mitte AS Agg_Area;
# SELECT * FROM RESULT;
# 
# -- loop through this using the V(Distinct); calc total length of items listed in vector(Dist) and write to table
# 
# ALTER TABLE result ADD COLUMN sum_G FLOAT;
# 
# UPDATE result 
# SET sum_G = foo.sum_G
# FROM (SELECT 
#       Agg_ID,
#       SUM(ST_Length(geom))/1000 AS sum_G
#       FROM InterSec
#       WHERE lineType = 'G'
#       GROUP BY Agg_ID
#       ORDER BY Agg_ID
# ) as foo
# WHERE result.Agg_ID = foo.Agg_ID
# ;
# 
# -- calc the total length of selected line types
# 
# ALTER TABLE result ADD COLUMN sum_length FLOAT;
# UPDATE result 
# SET sum_length = sum_g  -- summation of all values listed in the V(Dist)
# ;
# 
# --- loop adding the columns for the ratios and then filling them with value(dist)/sum_length
# 
# 
# SELECT * FROM result
# ORDER BY Agg_ID;
