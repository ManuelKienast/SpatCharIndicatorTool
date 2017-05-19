#------------------------------  Counting occurrences of point features and the centroids of areas
#---------------------------------------in polygons and returning a statistical overview  ----------------------------------
#'
#'
#' @param connection : A connection to the PostGIS database.
#' @param ouputTable AS string -- Table to create and write results into
#' @param schema1      AS string -- schema of table 1
#' @param schema2      AS string -- schema of table 2
#' @param table1       AS string -- table cotaining the point features = "mietobjekte", ## Point Feature Table
#' @param Id1          AS string -- unique identifier for table 1
#' @param table2       AS string -- table containig the aggregation geometries
#' @param Id2          AS string -- unique identifier of table 2
#' @param geom1        AS string -- the column containg the geometry, usually "geom"
#' @param geom2        AS string -- the column containg the geometry, usually "geom"

#' @examples -- output is one row
#      n  mean stddev min max
#1 5752 50.02  38.12   1 162
#
#-----------------------------------------------------------------------------------------------------------------------------------------


# ## Setting Up
# setwd("d:\\__projekt\\")
# library(RPostgreSQL)
# library(rgdal)
# library(RODBC)

# ## Erstellen der DB-Verbindung
# drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname = "DLR", host = "localhost", user = "postgres", password = "postgres") 
# dbListTables(con)



##
### Function calculating statistics for points in polygons:
##

psqlAvMean <- function(
  
  connection = con,
  ouputTable = "veu_survey.berlin_num_restaurants_1km",   ## Table name to create in PostGreSQL and write results into    ## table 2 schema
  table1  = "veu_survey.berlin_facilities_restaurant", ## Point Feature Table
  Id1     = "id",         ## unique identifier
  table2  = "veu_survey.berlin_adressen_2016_survey_buffer1km",         ## Grid table
  Id2     = "gid",        ## unique identifier per grid cell 2
  geom1   = "pos",        ## geometry column of table 1
  geom2   = "geom")        ## geometry column of table 2
  
  {
    AvMean <- dbGetQuery(connection, sprintf(
      "DROP TABLE IF EXISTS %s;
      
      SELECT * INTO %s 
        FROM(
      SELECT 
        sum(count) AS n,
        count(count) AS areaNo ,
        ROUND(AVG(count), 2) as Mean,
        ROUND(stddev(count), 2) AS StdDev,
        min(count),
        max(count)
          FROM(
            SELECT 
              count(%s.%s) AS count,
              %s.%s 
                FROM %s,%s 
                WHERE ST_Within (st_centroid(ST_Transform(%s.%s, 25833)), %s.%s)
      GROUP BY %s.%s
      ORDER BY %s.%s) as counts)
      as Foo;
      
      
      SELECT * FROM %s;",
      
      ouputTable,
      ouputTable,
      table1, Id1,
      table2, Id2,
      table1, table2,
      table1, geom1, table2, geom2,
      table2, Id2,
      table2, Id2,
      ouputTable))

  AvMean
}


# ##------------- default ----------------------------------------------------------------------
# #Usage:
# psqlAvMean()
# 
# ##------------- with fishnet as grid cells-----------------------------------------------------
# #Usage:
# psqlAvMean(table2 = "fishnet", Id2 = "gid")
# 
# 
# ##--------------with buildings in tvz -----------------------
# psqlAvMean(table1 = "buildings", Id1 = "gid")



#########----------------------SQL-Queries-------------------------------------------------------
# 
# SELECT 
# count(count) AS n,
# ROUND(avg(count),2) AS average,
# ROUND(stddev(count),2) AS StdDev,
# ROUND(min(count), 2) AS min,
# ROUND(max(count), 2) AS max
# FROM (
#   SELECT 
#   count(mietobjekte.gid) AS count,
#   tvz.code
#   FROM mietobjekte, tvz
#   WHERE ST_Within (mietobjekte.geom, tvz.geom)
#   Group BY tvz.code
#   order by tvz.code)
# as counts
# ;
