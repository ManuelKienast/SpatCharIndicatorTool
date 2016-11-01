##
## Import Script for 'aggregated_oneshot_meso.csv' data
##

importaggregatedOneShotCSV <- function ( connection,
                                table_schema, table_name,
                                filepath)
{
  
  aggregatedOneShotCSV <- dbGetQuery(connection, sprintf(
    
    "
    DROP TABLE IF EXISTS %s.%s;
    CREATE TABLE %s.%s (
    gid SERIAL PRIMARY Key,
    interval_begin FLOAT,
    interval_end FLOAT,
    interval_id VARCHAR (20),
    edge_arrived INTEGER,
    edge_density FLOAT,
    edge_departed INTEGER,
    edge_entered INTEGER,
    edge_id VARCHAR (75),
    edge_laneChangedFrom INTEGER,
    edge_laneChangedTo INTEGER,
    edge_left INTEGER,
    edge_occupancy FLOAT,
    edge_sampledseconds FLOAT,
    edge_speed FLOAT,
    edge_travelTime FLOAT,
    edge_waitingTime FLOAT);
    
    
    COPY %s.%s (interval_begin, interval_end, interval_id, edge_arrived, edge_density, edge_departed, edge_entered, edge_id, edge_laneChangedFrom,
					      edge_laneChangedTo, edge_left, edge_occupancy, edge_sampledseconds, edge_speed, edge_travelTime, edge_waitingTime)
    FROM '%s' WITH CSV HEADER DELIMITER ';';
    
    "
    ,
    table_schema, table_name,    ## DROP TABLE
    table_schema, table_name,    ## CREATE TABLE
    table_schema, table_name,    ## COPY
    filepath                     ## FROM
    
    ))
}

USAGE:
importaggregatedOneShotCSV (con, "public", "importTestaggro","D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv")

##
##
# ########################################################################################################################################
# #
# # Raw SQL-Code
# DROP TABLE IF EXISTS public.testImportEdge;
# CREATE TABLE public.testImportEdge (
#   gid SERIAL PRIMARY Key,
#   edges_version FLOAT,
#   edge_from VARCHAR (100),
#   edge_id VARCHAR (100),
#   edge_name VARCHAR (100),
#   edge_numLanes INTEGER,
#   edge_priority INTEGER,
#   edge_shape VARCHAR (2500),
#   edge_speed FLOAT,
#   edge_spreadType VARCHAR (20),
#   edge_to VARCHAR (100),
#   roundabout_edges VARCHAR (250),
#   roundabout_nodes VARCHAR (250),
#   geom GEOMETRY (MultiLineString, 25833));
# 
# 
# COPY public.testImportEdge (edges_version, edge_from, edge_id, edge_name, edge_numLanes, edge_priority, edge_shape, edge_speed,
#                             edge_spreadType, edge_to, roundabout_edges, roundabout_nodes)
# FROM 'D:\Manuel\vonSimon\Von Matthias\net_plain.edg.csv' WITH CSV HEADER DELIMITER ';'
# 
# UPDATE public.testImportEdge
# SET edge_shape = REPLACE(edge_shape, ' ', '#')
# SET edge_shape = REPLACE(edge_shape, ',', ' ');
# SET edge_shape = REPLACE(edge_shape, '#', ', ');
# 
# UPDATE public.testImportEdge
# SET geom = ST_Transform(St_GeomFromText('MultiLineString ((' || testImportEdge.edge_shape || '))', 4326), 25833);