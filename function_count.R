# Christina am 08.09.2016
# Zählt Polygone z.B. Gebaeude, die in einem Abschnitt liegen



#' Spatial Indicator for a count.
#' Counts geometries (points, lines and polygons) per aggregation unit. 
#' 
#' @param con A connection to the PostGIS database.
#' @param schema A string: the name of the scheme in the database, in which the tables are included.
#' @param table A string: the name of the table in the PostGIS database containing the geometry you want to count.
#' @param to_count A sring: the name of the column of the geometrie's identifier.
#' @param aggr_schema A string: the name of the scheme in the database, containing the aggregation table.
#' @param aggregation A string: the name of the table in the PostGIS database containing the aggregation units.
#' @param aggr_id A string: the name of the identifier of the aggregation units.
#' @param out_schema A string: the name of the scheme in the database, that should contain the output table.
#' @param output A string: the name of the table, that should contain the output.
#' 
#' @return counter A data.frame containing the aggregation and the count of geometries in that aggregation unit.
#' 
#' @examples 
#' countPolis(con,table = "mietobjekte", to_count = "gid", aggregation = "rbs_od_blk_2015_mitte", aggr_id = "blk", output = "counter")
#'         unit 		count
#' 1   		001001     0
#' 2   		001002     0
#' 3   		001007     6
#'        ...



setwd("d:\\Projekt\\")
#install.packages("L:\\Projekt\\Packages\\RPostgreSQL_0.4-1.zip",repos = NULL) 
#install.packages("L:\\Projekt\\Packages\\DBI_0.5.zip", repos = NULL)
library(RPostgreSQL)

## Connect to database
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "dlr", host = "localhost", user = "postgres", password = "postgres") 
dbListTables(con)



#Counts points per aggregation unit. Counts lines and polygons as well without creating Centroids.
#Gives empty aggregation units with a count of 0 as well.

countPolis <- function(con, schema = "public", table, to_count, aggr_schema = "public", aggregation, aggr_id, out_schema= "public", output){
  counter <- dbGetQuery(con, sprintf(
      "SELECT * INTO %s.%s FROM(SELECT a.%s as unit, count(b.%s) 
        FROM %s.%s as a LEFT JOIN %s.%s as b ON ST_Intersects(a.geom, b.geom)
        GROUP BY a.%s
        ORDER BY a.%s) as foo;
      SELECT * FROM %s.%s;", out_schema, output, aggr_id, to_count, aggr_schema, aggregation, schema, table, aggr_id, aggr_id, out_schema, output))
  counter
  
}



#Counts points per aggregation unit. Creates Centroids for lines and polygons.
#Gives empty aggregation units with a count of 0 as well.

countPolis2 <- function(con, schema, table, to_count, aggr_schema, aggregation, aggr_id, out_schema, output){
  counter <- dbGetQuery(con, sprintf(
    "DROP TABLE IF EXISTS %s.%s;
    DROP FUNCTION counter();
    CREATE OR REPLACE FUNCTION counter ()
    RETURNS TABLE (unit varchar(10), count bigint) AS
    $func$
    BEGIN
    
    CASE (SELECT DISTINCT GeometryType(%s.geom)FROM %s) 
    WHEN 'POINT', 'MULTIPOINT'
    THEN
    RETURN QUERY (SELECT a.%s as unit, count(b.%s)
    FROM %s.%s as a LEFT JOIN %s.%s as b ON ST_Intersects(a.geom, b.geom)
    GROUP BY a.%s
    ORDER BY a.%s);
    ELSE
    RETURN QUERY (SELECT a.%s as unit, count(b.%s)  
    FROM %s.%s as a LEFT JOIN %s.%s as b ON ST_Intersects(a.geom, ST_Centroid(b.geom))
    GROUP BY a.%s
    ORDER BY a.%s);
    END CASE;
    
    END
    $func$ LANGUAGE plpgsql;
    
    SELECT * INTO %s.%s from counter();
    ALTER TABLE %s.%s ADD PRIMARY KEY (unit);", out_schema, output, table, table, 
    aggr_id, to_count, aggr_schema, aggregation, schema, table, aggr_id, aggr_id,
    aggr_id, to_count, aggr_schema, aggregation, schema, table, aggr_id, aggr_id,
    out_schema, output, out_schema, output))
  
  
}


#----------------------------------------------------------------------------------------------------------------------

#Usage:

#countPolis(con,table = "mietobjekte", to_count = "gid", aggregation = "rbs_od_blk_2015_mitte", aggr_id = "blk", output = "counter")

#countPolis2(con, "public", "buildings", "building", "public", "rbs_od_blk_2015_mitte", "blk", "public", "countbuild")


#-----------------------------------------------------------------------------------------------------------------------

#disconnect DB Connection
dbDisconnect(con)

#-----------------------------------------------------------------------------------------------------------------------

#SQL-Query:

#SELECT * INTO out_schema.output FROM(SELECT a.aggr_id as unit, count(b.to_count) 
#        FROM aggr_schema.aggregation as a LEFT JOIN schema.table as b ON ST_Intersects(a.geom, b.geom)
#GROUP BY a.aggr_id
#ORDER BY a.aggr_id) as foo;
#SELECT * FROM out_schema.output;




#
#DROP TABLE IF EXISTS counter;
#DROP FUNCTION counter();
#CREATE OR REPLACE FUNCTION counter ()
#RETURNS TABLE (unit varchar(10), count bigint) AS
#$func$
#  BEGIN

#CASE (SELECT DISTINCT GeometryType(mietobjekte.geom)FROM mietobjekte) 
#WHEN 'POINT', 'MULTIPOINT'
#THEN
#RETURN QUERY (SELECT a.blk as unit, count(b.obid)
#              FROM public.rbs_od_blk_2015_mitte as a LEFT JOIN public.mietobjekte as b ON ST_Intersects(a.geom, b.geom)
#              GROUP BY a.blk
#              ORDER BY a.blk);
#ELSE
#RETURN QUERY (SELECT a.blk as unit, count(b.obid)  
#              FROM public.rbs_od_blk_2015_mitte as a LEFT JOIN public.mietobjekte as b ON ST_Intersects(a.geom, ST_Centroid(b.geom))
#              GROUP BY a.blk
#              ORDER BY a.blk);
#END CASE;

#END
#$func$ LANGUAGE plpgsql;
#
#SELECT * INTO counter from counter();
#ALTER TABLE counter ADD PRIMARY KEY (unit);