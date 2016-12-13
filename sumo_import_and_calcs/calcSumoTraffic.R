##
##
## calculate the traffic computed with sumo over the selected gridsize
##
## 

setwd("D:\\Manuel\\git\\SpatCharIndicatorTool")

source("sumo_import_and_calcs\\functions_compilation.R")

library(RPostgreSQL)


###### PARAMETERS #################################
#' @param connection                       A connection to the PostGIS database.
#' @param importTables_schema     -String- the schema in teh db in which the tables are going to be written into (assumption is all tables will be written to the same schema)
#' @param table_name_compiled     -String- the name of table in which all three-(node, edge, aggregateresult)-tables are compiled as one 
#' @param table_name_nod          -String- the name given to the node table written into the db
#' @param filepath_nod            -String- the file location of the node .csv file e.g. ("d:\\data\\sumoresults\\node.csv") please take note of "\\"
#' @param table_name_edg          -String- the name given to the edge table written into the db
#' @param filepath_edg            -String- the file location of the edge .csv file
#' @param table_name_aggregated   -String- the name given to the aggregate table aka modeling results aka edge loading table written into the db
#' @param filepath_aggregated     -String- the file location of the aggregate .csv file
#' @param set_CS2                 -Integer- the EPSG-code of the coordinate system the geometries shall be transformed(projected) into
#' @param resultTable_schema      -String- the schema in which the resutls table shall be written into the db
#' @param resultTable_name        -String- the name given to the final results table, holding the No. of trips per grid-cell written into the db
#' @param grid_schema             -String- the schema holding the grid tables in the db
#' @param grid_name               -String- the name of the grid-table
#' @param grid_geom               -String- the name of the geometry-column of the grid table




### simply run getAll2import once, followed by calcTraffic as often as you want to change the aggregation area, i.e. the grid_% parameteres,
### or try the loop-build below for all the grids

getAll2import( con,
               importTables_schema, table_name_compiled,
               table_name_nod, filepath_nod,
               table_name_edg, filepath_edg,
               table_name_aggregated, filepath_aggregated,
               set_CS2
               )



calcTraffic( con,
             resultTable_schema, resultTable_name,
             grid_schema, grid_name, grid_geom,
             importTables_schema, table_name_compiled
             )



##USAGE -1- :
# gridsize <- c("500", "1000", "2000", "4000")
# 
# for (i in gridsize){
#   calcTraffic(con, "public", sprintf("SumoTraffic_fish_%s",i), "grids", sprintf("fish_%s",i), "geom", "public", "compiledimport")
#   }



##USAGE -2- :
getAll2import( con,
              "sumo_traffic", "sumoData_Cmpltn",
              "sumoData_nod", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
              "sumoData_edg", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
              "sumoData_aggregated", "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
              "25833")

calcTraffic( con,
             "sumo_traffic", "sumotraffic_tvz",
             "urmo", "tvz", "the_geom",
             "sumo_traffic", "sumoData_Cmpltn")



# ##### OR both
# 
# doAll <- function (con,
#                    importTables_schema, table_name_compiled,
#                    table_name_nod, filepath_nod,
#                    table_name_edg, filepath_edg,
#                    table_name_aggregated, filepath_aggregated,
#                    set_CS2,
#                    resultTable_schema, resultTable_name,
#                    grid_schema, grid_name, grid_geom,
#                    )
# {
#   getAll2import( con,
#                  importTables_schema, table_name_compiled,
#                  table_name_nod, filepath_nod,
#                  table_name_edg, filepath_edg,
#                  table_name_aggregated, filepath_aggregated,
#                  set_CS2
#                   )
#     calcTraffic( con,
#                resultTable_schema, resultTable_name,
#                grid_schema, grid_name, grid_geom,
#                importTables_schema, table_name_compiled
#                 )
# }
# 
# 
# 
# # # USAGE:
#  doAll( con,
#         "sumo_traffic", "dataCmpltn",
#         "sumoData_nod", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
#         "sumoData_edg", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
#         "sumoData_aggregated", "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
#         "25833",
#         "sumo_traffic", "sumotraffic_tvz",
#         "urmo", "tvz", "the_geom"
#          )
# 
# ## USAGE:
# doAll( con,
#              "sumo_traffic", "sumotraffic_tvz",
#              "urmo", "tvz", "the_geom",
#              importTables_schema, table_name_compiled
# )



# 
# grids <- c("fish_500", "fish_1000", "fish_2000", "fish_4000")
# 
# for (i in grids) {calcSumoTraffic( 
#                  con,
#                  "public", sprintf("a_test_result_%s",i),
#                  "grids", i, "geom",
#                  "public", "a_test_compiled"
#                  )}
# 
# calcTraffic(con, "public", "sumotraffic_hex4000", "grids", "hex_4000", "geom", "public", "compiledimport")
# 
# 
# ### trying to loop 
# 
# calcSumoTraffic <- function( connection,
#                              importTables_schema, table_name_compiled,
#                              table_name_nod, filepath_nod,
#                              table_name_edg, filepath_edg,
#                              table_name_aggregated, filepath_aggregated,
#                              set_CS2,
#                              resultTable_schema, resultTable_name,
#                              grid_schema, grid_geom
#                              )
# {
#   # fishSize <- c()
#   # 
#   # hexSize <- c()
#   # 
#   # gridName <- c()
#   
#   grids <- c("fish_500", "fish_1000", "fish_2000", "fish_4000")
# 
#   getAll2import( con,
#                   importTables_schema, table_name_compiled,
#                   table_name_nod, filepath_nod,
#                   table_name_edg, filepath_edg,
#                   table_name_aggregated, filepath_aggregated,
#                   set_CS2
#                   )
# 
#   for (i in grids)
#     {calcTraffic( con,
#                     resultTable_schema, sprintf(resultTable_name_%s, i),
#                     grid_schema, i , grid_geom,
#                     importTables_schema, table_name_compiled
#                     )
#     }
# }                            
# 
# 
# 
# 
# # USAGE:
#  calcSumoTraffic( con,
#                   "public", "a_test_compiled",
#                   "a_test_nod", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
#                   "a_test_edg", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
#                   "a_test_aggregated", "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
#                    "25833",
#                    "public", "a_test_result",
#                    "grids", "geom"
#                    )
# 
#  
#  ############################################################################################## 
#  # -5-       #  ##  ##    testing jsut the loop    ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
#  ##############################################################################################
#  
#  
#  calcSumoTraffic <- function( connection,
#                               importTables_schema, table_name_compiled,
#                               resultTable_schema, resultTable_name,
#                               grid_schema, grid_geom
#  )
# {
#    
#    grids <- c("fish_500", "fish_1000", "fish_2000", "fish_4000")
#    
#    for (i in grids)
#    {calcTraffic( con,
#                  resultTable_schema, paste(resultTable_name_, i, sep = ""),
#                  grid_schema, i , grid_geom,
#                  importTables_schema, table_name_compiled
#                 )
#    }
# }
#  
#  
#  calcSumoTraffic( con,
#                   "public", "a_test_compiled",
#                   "public", "a_test_result",
#                   "grids", "geom"
#  )
#  
#  
#  (nth <- paste0(1:12, c("st", "nd", "rd", rep("th", 9))))
#  paste0(nth, collapse = ", ")
#  paste("1st", "2nd", "3rd", collapse = ", ")                   
#  paste("1st", "2nd", "3rd", sep = ", ")
#  
#  vals <- rnorm(3)
#  n    <- length(vals)
#  lhs  <- paste("a",    1:n,     sep="")
#  rhs  <- paste("vals[",1:n,"]", sep="")
#  eq   <- paste(paste(lhs, rhs, sep="<-"), collapse=";")
#  eval(parse(text=eq))
#  
#  
# 
#   
# 
# 
# 
# #calcTrafficTable(connection, "SumoTraffic_hex4000")
# #
# # vgrid <- c(1000, 2000)
# # 
# #   for(grid_size in vgrid){
# #     calcTraffic(con, "grids", sprintf("hex_", grid_size), sprintf("sumo_traffic_hex_%s",grid_size))
# #   }
# #   
