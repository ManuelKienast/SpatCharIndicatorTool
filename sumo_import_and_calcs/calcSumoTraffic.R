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





### trying to loop 

calcSumoTraffic <- function( connection,
                             importTables_schema, table_name_compiled,
                             table_name_nod, filepath_nod,
                             table_name_edg, filepath_edg,
                             table_name_aggregated, filepath_aggregated,
                             set_CS2,
                             resultTable_schema, resultTable_name,
                             grid_schema, grid_geom
                             )
{
  # fishSize <- c()
  # 
  # hexSize <- c()
  # 
  # gridName <- c()
  
  grids <- c("fish_500", "fish_1000", "fish_2000", "fish_4000")

  getAll2import( con,
                  importTables_schema, table_name_compiled,
                  table_name_nod, filepath_nod,
                  table_name_edg, filepath_edg,
                  table_name_aggregated, filepath_aggregated,
                  set_CS2
                  )

  for (i in grids)
    {calcTraffic( con,
                    resultTable_schema, resultTable_name_i,
                    grid_schema, i , grid_geom,
                    importTables_schema, table_name_compiled
                    )
    }
}                            


# USAGE:
 calcSumoTraffic( con,
                  "public", "a_test_compiled",
                  "a_test_nod", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
                  "a_test_edg", "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
                  "a_test_aggregated", "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
                   "25833",
                   "public", "a_test_result",
                   "grids", "geom"
                   )
                             
# gridsize <- c("500", "1000", "2000", "4000")
# 
# for (i in gridsize){
#   calcTraffic(con, "grids", sprintf("fish_%s",i), sprintf("SumoTraffic_fish_%s",i), "geom")
#   }
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
