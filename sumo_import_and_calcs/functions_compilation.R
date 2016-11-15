## Necessary funtions for import, compilation and calculation of sumo modeling results aka edge loads
## The eight following funtions defined in here are in ORDER BY 

      # 1- importPlainNodCSV           - import of node data
      # 2- importPlainEdgeCSV          - import of edge data
      # 3- importaggregatedOneShot     - import of edge loads - the results
      # 4- compile2Table               - compilation of the above imports into one table
      # 5- getAll2import               - compilation of the four (above) import funcs, into one handy package

      # 6- createSumoInterSectionTable - creation of the intersection table btwn the node geometries and the aggregation grid
      # 7- calcTrafficTable            - calculation of the the edge loadings per grid cell
      # 8- calcTraffic                 - aggregation of the above two functions (createSumoInterSectionTable, calcTrafficTable)





############################################################################################## 
# -1-  #  ##  ##    Import Script for 'net_plain.nod.csv' data     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

importPlainNodCSV <- function( connection,
                               importTables_schema, table_name_nod,
                               set_CS2, filepath_nod
                               )
{
  plainNodCSV <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s;
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
    importTables_schema, table_name_nod,    ## DROP TABLE
    importTables_schema, table_name_nod,    ## CREATE TABLE
    set_CS2,                         ## "geom"
    importTables_schema, table_name_nod,    ## COPY
    filepath_nod,                    ## FROM
    importTables_schema, table_name_nod,    ## COPY
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






############################################################################################## 
# -2-  #  ##  ##    Import Script for 'net_plain.edg.csv' data     ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################

importPlainEdgCSV <- function( connection,
                               importTables_schema, table_name_edg,
                               set_CS2, filepath_edg
                               )
{
  plainEdgCSV <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s;
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
      SET geom = ST_Transform(St_GeomFromText('MultiLineString ((' || %s.edge_shape || '))', 4326), %s)
    ;"
    ,
    importTables_schema, table_name_edg,    ## DROP TABLE
    importTables_schema, table_name_edg,    ## CREATE TABLE
    set_CS2,                     ## "geom"
    importTables_schema, table_name_edg,    ## COPY
    filepath_edg,                    ## FROM
    importTables_schema, table_name_edg,    ## UPDATE -1- 
    importTables_schema, table_name_edg,    ## UPDATE -2-
    importTables_schema, table_name_edg,    ## UPDATE -3-
    importTables_schema, table_name_edg,    ## UPDATE -4-
    table_name_edg, set_CS2          ## SET geom
    ))
}

# USAGE:
#   importPlainEdgCSV (con, "public", "importTestEdge", "25833", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv")
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






############################################################################################## 
# -3-  #  ##  ##    Import Script for 'aggregated_oneshot_meso.csv' data   ##  ##  ##  ##  ##  ##  ##
##############################################################################################

importAggregatedOneShotCSV <- function( connection,
                                        importTables_schema, table_name_aggregated,
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
    importTables_schema, table_name_aggregated,    ## DROP TABLE
    importTables_schema, table_name_aggregated,    ## CREATE TABLE
    importTables_schema, table_name_aggregated,    ## COPY
    filepath_aggregated                     ## FROM
    
  ))
}

#USAGE:
#  importaggregatedOneShotCSV (con, "public", "importTestaggro","D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv")
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






############################################################################################## 
# -4-  #  ##  ##   compilation function    ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################

### Importantnotice: the Node-geometries are the geometries of the node_tos, i.e. all information is tacked onto the 
### target node, and not the departure node

compile2Table <- function( connection,
                           importTables_schema, table_name_compiled,
                           table_name_nod, table_name_edg, table_name_aggregated
                           )
  
{
  new_table <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s;
    
    SELECT * INTO %s.%s FROM
      (SELECT
        a.interval_begin,
        a.edge_arrived,
        a.edge_departed,
        a.edge_entered,
        a.edge_left,
        e.edge_id,
        e.edge_to,
        e.edge_from,
        n.geom
          FROM %s.%s AS a
            LEFT JOIN %s.%s AS e
              ON (a.edge_id = e.edge_id)
            LEFT JOIN %s.%s As n
              ON (e.edge_to = n.node_id)
      )as foo;
    
    ALTER TABLE %s.%s
      ADD COLUMN gid SERIAL PRIMARY KEY;
    
    CREATE INDEX %s_gix
      ON %s.%s
      USING GIST (geom);"
    ,
    importTables_schema, table_name_compiled,      ## DROP TABLE
    importTables_schema, table_name_compiled,      ## CREATE TABLE
    importTables_schema, table_name_aggregated,    ## FROM as a
    importTables_schema, table_name_edg,           ## LEFT JOIN -1- as e
    importTables_schema, table_name_nod,           ## LEFT JOIN -2- as n
    importTables_schema, table_name_compiled,      ## ALTER ADD PKEY
    table_name_compiled,                    ## CREATE INDEX
    importTables_schema, table_name_compiled       ## INDEX ON
    
  ))
}

#USAGE:
#  compile2Table (con, "public", "compiledimport", "test_nod", "test_edg", "test_aggregated")
##
# ########################################################################################################################################
# #
# # Raw SQL-Code
# 
# SELECT a.interval_begin, a.edge_arrived, a.edge_departed, a.edge_entered, a.edge_left, e.edge_id, n.node_id, n.geom
#   FROM test_Aggregated AS a
#     LEFT JOIN test_edg AS e
#       ON (a.edge_id = e.edge_id)
#     LEFT JOIN test_nod As n
#       ON(e.edge_to = n.node_id)
    





############################################################################################## 
# -5-       #  ##  ##    createSumoInterSectionTable    ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################

getAll2import <- function( con,
                           importTables_schema, table_name_compiled,
                           table_name_nod, filepath_nod,
                           table_name_edg, filepath_edg,
                           table_name_aggregated, filepath_aggregated,
                           set_CS2
                           )
{
  
  plainNod<-  importPlainNodCSV( con,
                                 importTables_schema, table_name_nod,
                                 set_CS2, filepath_nod)
  
  plainEdg <- importPlainEdgCSV( con,
                                 importTables_schema, table_name_edg,
                                 set_CS2, filepath_edg)
  
  aggregate <-  importAggregatedOneShotCSV( con,
                                            importTables_schema, table_name_aggregated,
                                            filepath_aggregated)
  
  comilationTable <- compile2Table( con,
                                    importTables_schema, table_name_compiled,
                                    table_name_nod, table_name_edg, table_name_aggregated)
  
}


#USAGE:
 # getAll2import( con,
 # "public", "compiledimport",
 # "test_nod", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
 # "test_edg", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
 # "test_aggregated", "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
 # "25833"
 # )





############################################################################################## 
# -6-       #  ##  ##    createSumoInterSectionTable    ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################

createSumoInterSectionTable <- function( connection,
                                         resultTable_schema, resultTable_name,
                                         grid_schema, grid_name, grid_geom,
                                         importTables_schema, table_name_compiled
                                         ) 
  
{
  tempISTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s_intersect;
    
    SELECT * INTO %s.%s_intersect FROM
    (
      SELECT 
        row_number() over (order by 1) as key,
        ci.interval_begin,
        ci.edge_arrived,
        ci.edge_departed,
        ci.edge_entered,
        ci.edge_left,
        ci.edge_id,
        ci.edge_to,
        ci.edge_from,
        ci.geom as geom_point,
        r.%s as geom_grid,
        r.gid
          FROM %s.%s AS ci 
            JOIN %s.%s AS r 
              ON ST_Within(ci.geom, r.%s) 
      )as foo;
    
    
    DROP INDEX IF EXISTS %s_intersect_gix;
    
    CREATE INDEX %s_intersect_gix 
      ON %s.%s_intersect
      USING GIST (geom_point);
    "
    ,
    resultTable_schema, resultTable_name, ###  DROP TABLE ...
    resultTable_schema, resultTable_name, ###  CREATE TABLE ...
    grid_geom,                            ###  r.% as geom_grid
    importTables_schema, table_name_compiled,    ###  FROM AS ci
    grid_schema, grid_name,               ###  JOIN
    grid_geom,                            ###  St_within
    resultTable_name,                     ###  DROP INDEX
    resultTable_name, ###  CREATE INDEX
    resultTable_schema, resultTable_name  ###  ON
  ))
  
  return(tempISTable)
}






############################################################################################## 
# -7-          #  ##  ##    calcTrafficTable    ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################

calcTrafficTable <- function ( connection,
                               resultTable_schema, resultTable_name
                               )
{
  traffic_per_grid <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s;
    SELECT * INTO %s.%s FROM (
    
      WITH startingTrips AS(
        SELECT
          sum(edge_departed) AS trips_d,
          gid,
          geom_grid
            FROM %s.%s_intersect
        GROUP BY gid,
                 geom_grid),
    
      EnteringTrips AS(
        SELECT
          sum(a.edge_entered) AS trips_e,
          a.gid
            FROM %s.%s_intersect a
            LEFT JOIN %s.%s_intersect b
              ON a.edge_from = b.edge_to
        WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
        GROUP BY a.gid)

    SELECT
      a.gid,
      a.trips_d,
      b.trips_e,
      COALESCE(a.trips_d,0)+COALESCE(b.trips_e,0) as total,
      a.geom_grid
        FROM startingTrips a
          LEFT JOIN enteringTrips b
            ON a.gid = b.gid
      )as foo
    ;"
    ,
    resultTable_schema, resultTable_name,    ### DROP IF
    resultTable_schema, resultTable_name,    ### CREATE TABLE 
    resultTable_schema, resultTable_name,    ### FROM - STARTING trips
    resultTable_schema, resultTable_name,    ### FROM - ENTERING trips
    resultTable_schema, resultTable_name     ### LEFT JOIN - ENTERING trips
    
  ))
    
}







############################################################################################## 
# -8-  #  ##  ##    calcTraffic    ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################

calcTraffic <- function( connection,
                         resultTable_schema, resultTable_name,
                         grid_schema, grid_name, grid_geom,
                         importTables_schema, table_name_compiled
                         )
  
{
  createSumoInterSectionTable(connection, resultTable_schema, resultTable_name, grid_schema, grid_name, grid_geom, importTables_schema, table_name_compiled) 
  
  calcTrafficTable(connection, resultTable_schema, resultTable_name)
}          


#USAGE:
  # calcTraffic(con, "public", "sumotraffic_hex4000", "grids", "hex_4000", "the_geom", "public", "compiledimport")
  # test: for (i in grids)

?lm()
