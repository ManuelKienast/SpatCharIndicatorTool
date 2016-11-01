##
## Import Script for 'aggregated_oneshot_meso.csv' data
##

source("importPOintEdgeData\\importPlainNodCSV.r")
source("importPOintEdgeData\\importPlainEdgeCSV.r")
source("importPOintEdgeData\\importaggregatedOneShotCSV.r")


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
  

USAGE:
  getAll2import( con,
                             "public",
                             "test_nod",
                             "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.nod.csv",
                             "test_edg",
                             "D:\\Manuel\\vonSimon\\Von Matthias\\net_plain.edg.csv",
                             "test_aggregated",
                             "D:\\Manuel\\vonSimon\\Von Matthias\\aggregated_oneshot_meso.csv",
                             "25833")
      