##
## Import Script for 'net_plain.edg.csv' data
##


importPlainEdgCSV <- function ( connection,
                                table_schema, table_name,
                                set_CS2, filepath)
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
    table_schema, table_name,    ## DROP TABLE
    table_schema, table_name,    ## CREATE TABLE
    set_CS2,                     ## "geom"
    table_schema, table_name,    ## COPY
    filepath,                    ## FROM
    table_schema, table_name,    ## UPDATE -1- 
    table_schema, table_name,    ## UPDATE -2-
    table_schema, table_name,    ## UPDATE -3-
    table_schema, table_name,    ## UPDATE -4-
    table_name, set_CS2          ## SET geom
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