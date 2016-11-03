##
## Import Script for 'aggregated_oneshot_meso.csv' data
## and possibly compiling all 'relevant' information into one table (see function @bottom)
##

source("importPOintEdgeData\\getAll_functionCompilation.r")



getAll2import <- function( con,
                            table_schema,
                            table_name_nod,
                            filepath_nod,
                            table_name_edg,
                            filepath_edg,
                            table_name_aggregated,
                            filepath_aggregated,
                            set_CS2)
{
  
plainNod<-  importPlainNodCSV( con,
                               table_schema, table_name_nod,
                               set_CS2, filepath_nod)

plainEdg <- importPlainEdgCSV( con,
                               table_schema, table_name_edg,
                               set_CS2, filepath_edg)
      
aggregate <-  importaggregatedOneShotCSV( con,
                                          table_schema, table_name_aggregated,
                                         filepath_aggregated)
  
  }
  

#USAGE:
  getAll2import( con,
                             "public",
                             "test_nod",
                             "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
                             "test_edg",
                             "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
                             "test_aggregated",
                             "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
                             "25833")

    
##
# ########################################################################################################################################
# ########################################################################################################################################
##
  
  
  ### Importantnotice: the Node-geometries are the geometries of the node_tos, i.e. all information is tacked onto the 
  ### target node, and not the departure node
    
  compile2Table <- function ()
    
  {
    
    new_table <- dbGetQuery(connection, sprintf(
      
      "
      DROP TABLE IF EXISTS public.compiledImport;
      
      SELECT * INTO public.compiledImport FROM
        (SELECT 
          a.interval_begin,
          a.edge_arrived,
          a.edge_departed,
          a.edge_entered,
          a.edge_left,
          e.edge_id,
          a.edge_to,
          a.edge_from,
          n.geom
        FROM test_Aggregated AS a
          LEFT JOIN test_edg AS e
            ON (a.edge_id = e.edge_id)
          LEFT JOIN test_nod As n
            ON(e.edge_to = n.node_id)
                
      ) as foo;
      
      ALTER TABLE public.compiledImport
      ADD COLUMN gid SERIAL PRIMARY KEY;

      CREATE INDEX compiledImport_gix 
        ON public.compiledImport
        USING GIST (geom);
      "
      ))
}
  
  
  ##
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
  #     
  
  
#   ##
#   ##  (UN-)DEAD-END
#   # ########################################################################################################################################  
#   ## Create Table with a single Geom per point and not 68 like above
#   
#   
#   ## get the vector fot time intervals
#   
#   getV_tint <- function (connection)
#     
#     {V_tintdf <- dbGetQuery(connection, sprintf(
#       "SELECT DISTINCT interval_begin 
#       FROM public.compiledImport
#       ORDER BY interval_begin
#   
#   ;"))
#   
#   V_tint <- V_tintdf[,1]
#   
#   return(V_tint)    
#   }
#   
#   V_tint <- getV_tint (con)
#   
#   
#   ## Create base table
#   
#   createBaseTable <- function (connection)
#     
#     {
#     baseTable <- dbGetQuery(connection, sprintf(
#       
#       "DROP TABLE IF EXISTS public.cImport;
#       SELECT * INTO public.cImport
#         FROM (SELECT DISTINCT
#           node_id,
#           geom,
#           edge_id
#             FROM public.compiledImport
#               )as Foo;
#       
#       ALTER TABLE public.cImport
#         ADD COLUMN gid SERIAL PRIMARY KEY;
#       
#       CREATE INDEX cImport_gix 
#         ON public.cImport
#       USING GIST (geom);
#       "))
#     }
# 
#   cImport <- createBaseTable(con)
#   
#   ### adding the loop to fill the cols with data acccording to the timeframe defined in the V_tint
#   
#   ###VColnames <- c("interval_begin", "edge_arrived", "edge_departed", "edge_entered", "edge_left", "edge_id", "node_id")
#   
#   
#   
#   compile2SingleGeomTable <- function (con, V_tint)  
#    
#   { 
#     singlegeomTable <- dbGetQuery(connection, sprintf(
#     "
#   ALTER TABLE public.cImport DROP COLUMN IF EXISTS interval_begin_%s;
#   ALTER TABLE public.cImport ADD COLUMN interval_begin_%s FLOAT;
# 
#   ALTER TABLE public.cImport DROP COLUMN IF EXISTS edge_arrived_%s;
#   ALTER TABLE public.cImport ADD COLUMN edge_arrived_%s FLOAT;
# 
#   ALTER TABLE public.cImport DROP COLUMN IF EXISTS edge_departed_%s;
#   ALTER TABLE public.cImport ADD COLUMN edge_departed_%s FLOAT;
# 
#   ALTER TABLE public.cImport DROP COLUMN IF EXISTS edge_entered_%s;
#   ALTER TABLE public.cImport ADD COLUMN edge_entered_%s FLOAT;
# 
#   ALTER TABLE public.cImport DROP COLUMN IF EXISTS edge_left_%s;
#   ALTER TABLE public.cImport ADD COLUMN edge_left_%s FLOAT;
#   "
#   ,
#    V_tint,V_tint,
#     V_tint,V_tint,
#     V_tint,V_tint,
#     V_tint,V_tint,
#     V_tint,V_tint))
# 
# }
# 
# for ( i in V_tint ) compile2SingleGeomTable (con, i)
# 
#     UPDATE public.cImport
#       SET interval_begin_%s = c.interval_begin,
#       SET edge_arrived_%s   = c.edge_arrived,
#       SET edge_departed_%s  = c.edge_departed,
#       SET edge_entered_%s   = c.edge_entered,
#       SET edge_left_%s      = c.edge_left
#         FROM public.cIMport 
#           LEFT JOIN public.compiledImport AS c
#            ON node_id = c.node_id
#         WHERE c.interval_begin = '%s' AND node_id = c.node_id
#     ;"
#  
#   
#    V_tint,V_tint,V_tint,V_tint,V_tint,
#   
#    V_tint
# 
#   ))
#   }
#   
#   for ( i in V_tint ) compile2SingleGeomTable (con, i)