##
##
## calculate the traffic computed with sumo over the selected gridsize
##
## 

source("sumo_import_and_calcs\\functions_compilation.R")

library(RPostgreSQL)


### simply run getAll2import once, followed by calcTraffic as often as you want to change the aggregation area
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




gridsize <- c("500", "1000", "2000", "4000")

for (i in gridsize){
  calcTraffic(con, "public", sprintf("SumoTraffic_fish_%s",i), "grids", sprintf("fish_%s",i), "geom", "public", "compiledimport")
  }




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
