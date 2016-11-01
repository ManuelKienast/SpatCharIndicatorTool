##
## Import Script for 'aggregated_oneshot_meso.csv' data
##

source(\\importPOintEdgeData)


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
  
plainNod<-  importPlainNodCSV( connection,
                               table_schema, table_name_nod,
                               set_CS2, filepath_nod)

plainEdg <- importPlainEdgCSV( connection,
                               table_schema, table_name_edg,
                               set_CS2, filepath_edg)
      
aggregate <-  importaggregatedOneShotCSV( connection,
                                          table_schema, table_name_aggregated,
                                         filepath_aggregated)
  
  }
  
      