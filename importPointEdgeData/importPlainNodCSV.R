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