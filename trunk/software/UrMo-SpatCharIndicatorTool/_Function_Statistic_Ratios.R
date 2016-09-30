#--------------------------------------------  Two Functions for calculating ratios either in the same or different tables  ----------------------------------
#' Function Calculating the
#' Ratio of PlayGroundArea per Child available in a selected aggregation Area;
#' working examples include TVZ-Mitte and Fishnet.
#'
#'
#' @param connection : A connection to the PostGIS database.
#' @param WriteToTable AS string -- Table to create and write results into
#' @param schema1      AS string -- schema of table 1
#' @param schema2      AS string -- schema of table 2
#' @param table1       AS string -- first table, containing the numerator
#' @param table2       AS string -- second table, containing the denominator
#' @param column1      AS string -- column of the numerator
#' @param column2      AS string -- column of the denominator
#' @param gid1         AS string -- "gid" of table 1, which creates the Join condition
#' @param gid2         AS string -- "gid" of table 2, which creates the Join condition

#' @examples 
#        gid  ratio
# 1    101001 7.14
# 2    101001 6.85
# 3    101001 5.56
#
#-----------------------------------------------------------------------------------------------------------------------------------------

## Setting Up
setwd("d:\\__projekt\\")
library(RPostgreSQL)
library(rgdal)
library(RODBC)

## Erstellen der DB-Verbindung
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "DLR", host = "localhost", user = "postgres", password = "postgres") 
dbListTables(con)




##
## Mean Basic Function, Proportion between two columns from different tables [(Table1.column1)/(Table2.Column2)] with:
##

Ratio <- function(
  connection = con,             ## connection to db
  WriteToTable = "KaltMiete",   ## results table, name given by user
  schema1 = "public",           ## schema of table 1 - numerator
  schema2 = "public",           ## schema of table 2 - denominator
  table1 = "mietobjekte",       ## table 1 - containing the numerator
  table2 = "mietobjekte",       ## table 2 - containing the denominator
  column1 = "mietekalt",        ## column 1 - the column containing the numerator
  column2 = "wohnflaech",       ## column 2 - the column containing the denominator
  gid1 = "gid",                 ## unique ID table 1
  gid2 = "gid")                 ## unique ID table 2
  {
  Ratio <- dbGetQuery(connection,sprintf(
    "DROP TABLE IF EXISTS %s;
    SELECT * INTO %s FROM
    (SELECT
    a.%s AS ID,
    round(a.%s/b.%s, 3) AS miete_m2 
    FROM %s.%s AS a 
    FULL JOIN %s.%s AS b 
    ON ( a.%s = b.%s)
    WHERE b.%s > 0
    ) as foo;

    ALTER TABLE %s ADD Primary Key (ID);

    SELECT * FROM %s",
    
    WriteToTable,
    WriteToTable,
    gid1,
    column1,column2,
    schema1,table1,
    schema2,table2,
    gid1,gid2,
    column2,
    WriteToTable,
    WriteToTable))
  
  Ratio
  
}

Ratio()




####### Ratio-Function with statistics on Aggregation Area

RatioStats <- function(
  connection = con,             ## connection to db
  WriteToTable = "RatioStats",  ## results table, name given by user
  schema1 = "public",           ## schema of table 1 - numerator
  schema2 = "public",           ## schema of table 2 - denominator
  table1 = "mietobjekte",       ## table 1 - containing the numerator
  table2 = "mietobjekte",       ## table 2 - containing the denominator
  column1 = "mietekalt",        ## column 1 - the column containing the numerator
  column2 = "wohnflaech",       ## column 2 - the column containing the denominator
  gid1 = "gid",                 ## unique ID table 1
  gid2 = "gid",                 ## unique ID table 2
  geom1 = "geom",               ## geometry column of table 1 - usually geom
  geom2 = "geom",               ## geometry column of table 2 - usually geom
  GeomSchema = "public",        ## the schema of the aggregation area table
  GeomTable = "TVZ",            ## the table containing the desired aggregation area, e.g. TVZ / PLR / Fishnet
  GeomTableID = "code",         ## unique ID
  Geomgeom = "geom"             ## geometry column of the aggregation area table
  ) {
  RatioStats <- dbGetQuery(connection, sprintf(
    "

    DROP TABLE IF EXISTS %s;
    SELECT * INTO %s FROM
    (
    SELECT
    g.%s AS ID,
	  count(a.%s/b.%s),
    ROUND(avg(a.%s/b.%s),2) AS average,    
    ROUND(stddev(a.%s/b.%s), 2) AS StdDev,
    ROUND(min(a.%s/b.%s), 2) AS min,
    ROUND(max(a.%s/b.%s), 2) AS max
      FROM  %s.%s AS g, 
            %s.%s as a 
            FULL JOIN %s.%s AS b 
            ON( a.%s = b.%s )
            WHERE ST_Within(a.%s, g.%s) AND b.%s > 0
    GROUP BY g.%s
    ORDER BY g.%s )
    AS Foo
   ; 

    ALTER TABLE %s ADD Primary Key (ID);

    SELECT * FROM %s;",
    
    WriteToTable,    ## Drop Table
    WriteToTable,    ## SELECT INTO
    GeomTableID,
    column1,column2, ## count
    column1,column2, ## ave
    column1,column2, ## StdDev
    column1,column2, ## min
    column1,column2, ## max
    GeomSchema, GeomTable, schema1, table1,  ## FROM
    schema2,table2,  ## FULL JOIN
    gid1, gid2,      ## ON
    Geomgeom, geom1, column2,  ## WHERE
    GeomTableID,     ## GROUP
    GeomTableID,     ## ORDER
    WriteToTable,    ## Alter Table
    WriteToTable))   ## SELECT ALL
  
  RatioStats
}

RatioStats()






#########----------------------SQL-Queries-------------------------------------------------------
# 
# SELECT 	
# tvz.code AS TVZ,
# ROUND(avg(m.mietekalt/m.wohnflaech),2) AS average,
# count(m.mietekalt/m.wohnflaech),
# ROUND(stddev(m.mietekalt/m.wohnflaech),2) AS StdDev,
# ROUND(min(m.mietekalt/m.wohnflaech), 2) AS min,
# ROUND(max(m.mietekalt/m.wohnflaech), 2) AS max
# FROM mietobjekte as m, tvz 
# WHERE  ST_Within (m.geom, tvz.geom) AND m.wohnflaech > 0
# GROUP BY tvz.code
# ORDER BY tvz.code
# ;
