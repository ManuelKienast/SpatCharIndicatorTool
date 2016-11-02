##
## The three funtions for importation are defined in here. ORDER: importPlainNodCSV, importPlainEdgeCSV, importaggregatedOneShot
##

##
## Import Script for 'net_plain.nod.csv' data
##


importPlainNodCSV <- function ( connection,
                                table_schema, table_name_nod,
                                set_CS2, filepath_nod)
{
  
  plainNodCSV <- dbGetQuery(connection, sprintf(
    
    "
    DROP TABLE IF EXISTS %s.%s;
    CREATE TABLE %s.%s (
    gid SERIAL PRIMARY Key,
    nodes_version FLOAT,
    node_id VARCHAR (100),
    node_type VARCHAR (20),
    node_x FLOAT,
    node_y FLOAT,
    geom GEOMETRY (Point, %s));
    
    
    COPY %s.%s (nodes_version, node_id, node_type, node_x, node_y)
    FROM '%s' WITH CSV HEADER DELIMITER ';';
    
    UPDATE %s.%s
    SET geom = ST_Transform(St_GeomFromText('Point ('|| %s.node_x ||' '|| %s.node_y || ')', 4326), %s);
    
    "
    ,
    table_schema, table_name_nod,    ## DROP TABLE
    table_schema, table_name_nod,    ## CREATE TABLE
    set_CS2,                     ## "geom"
    table_schema, table_name_nod,    ## COPY
    filepath_nod,                    ## FROM
    table_schema, table_name_nod,    ## COPY
    table_name_nod, table_name_nod, set_CS2 ## SET geom
  ))
}

# USAGE:
#   importPlainNodCSV (con, "public", "importTest", "25833", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv")



##
# ########################################################################################################################################
# #
# # Raw SQL-Code
# DROP TABLE IF EXISTS public.testImport;
# CREATE TABLE public.testImport (
#   "gid" SERIAL PRIMARY Key,
#   "nodes_version" FLOAT,
#   "node_id" VARCHAR (100),
#   "node_type" VARCHAR (20),
#   "node_x" FLOAT,
#   "node_y" FLOAT,
#   "geom" GEOMETRY (Point, 25833));
# 
# 
# COPY public.testImport (nodes_version, node_id, node_type, node_x, node_y)
# FROM 'D:\Manuel\vonSimon\Von Matthias\net_plain.nod.csv' WITH CSV HEADER DELIMITER ';'
# 
# UPDATE public.testimport
# SET geom = ST_Transform(St_GeomFromText('Point ('|| testImport.node_x ||' '|| testImport.node_y || ')', 4326), 25833);


##
# ########################################################################################################################################
# ########################################################################################################################################
##
##
## Import Script for 'net_plain.edg.csv' data
##


importPlainEdgCSV <- function ( connection,
                                table_schema, table_name_edg,
                                set_CS2, filepath_edg)
{
  
  plainEdgCSV <- dbGetQuery(connection, sprintf(
    
    "
    DROP TABLE IF EXISTS %s.%s;
    CREATE TABLE %s.%s (
    gid SERIAL PRIMARY Key,
    edges_version FLOAT,
    edge_from VARCHAR (100),
    edge_id VARCHAR (100),
    edge_name VARCHAR (100),
    edge_numLanes INTEGER,
    edge_priority INTEGER,
    edge_shape VARCHAR (2500),
    edge_speed FLOAT,
    edge_spreadType VARCHAR (20),
    edge_to VARCHAR (100),
    roundabout_edges VARCHAR (250),
    roundabout_nodes VARCHAR (250),
    geom GEOMETRY (MultiLineString, %s));
    
    
    COPY %s.%s (edges_version, edge_from, edge_id, edge_name, edge_numLanes, edge_priority, edge_shape, edge_speed,
    edge_spreadType, edge_to, roundabout_edges, roundabout_nodes)
    FROM '%s' WITH CSV HEADER DELIMITER ';';
    
    UPDATE %s.%s
    SET edge_shape = REPLACE(edge_shape, ' ', '#');
    UPDATE %s.%s
    SET edge_shape = REPLACE(edge_shape, ',', ' ');
    UPDATE %s.%s
    SET edge_shape = REPLACE(edge_shape, '#', ', ');
    
    UPDATE %s.%s
    SET geom = ST_Transform(St_GeomFromText('MultiLineString ((' || %s.edge_shape || '))', 4326), %s);
    
    "
    ,
    table_schema, table_name_edg,    ## DROP TABLE
    table_schema, table_name_edg,    ## CREATE TABLE
    set_CS2,                     ## "geom"
    table_schema, table_name_edg,    ## COPY
    filepath_edg,                    ## FROM
    table_schema, table_name_edg,    ## UPDATE -1- 
    table_schema, table_name_edg,    ## UPDATE -2-
    table_schema, table_name_edg,    ## UPDATE -3-
    table_schema, table_name_edg,    ## UPDATE -4-
    table_name_edg, set_CS2          ## SET geom
    ))
}

# USAGE:
#   importPlainEdgCSV (con, "public", "importTestEdge", "25833", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv")



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



##
# ########################################################################################################################################
# ########################################################################################################################################
# #

##
## Import Script for 'aggregated_oneshot_meso.csv' data
##

importaggregatedOneShotCSV <- function ( connection,
                                         table_schema, table_name_aggregated,
                                         filepath_aggregated)
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
    table_schema, table_name_aggregated,    ## DROP TABLE
    table_schema, table_name_aggregated,    ## CREATE TABLE
    table_schema, table_name_aggregated,    ## COPY
    filepath_aggregated                     ## FROM
    
  ))
}

#USAGE:
#  importaggregatedOneShotCSV (con, "public", "importTestaggro","D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv")

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