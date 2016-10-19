
library(RPostgreSQL)
library(dplyr)
library(tidyr)
library(splitstackshape)


get_field_names <-function(con, table_name){
  column_names <- dbGetQuery(con,sprintf("SELECT column_name, data_type from information_schema.columns  WHERE table_name = '%s'", table_name))
  return(column_names)
}

get_unique_values <- function(con,schema_name, table_name, column_name){
  queryString = paste("SET search_path TO ", schema_name, "")
  unique_vals <- dbGetQuery(con, sprintf("SELECT DISTINCT %s FROM %s.%s;", column_name, schema_name, table_name))
}

generate_select_string <- function(unique_vals, drop_table_if_exists = "TRUE"){
  select_string<-""
  for(unique_val in unique_vals){
    select_string <- sprintf("%s %s", select_string, unique_val)
   
  }
  return(as.character(select_string))
}




closeOpenPSQLConnections <- function(){
  
  all_cons <- dbListConnections(PostgreSQL())
  for(con in all_cons)
    +  dbDisconnect(con) 
}




table_name <- "berlin_network"
field_name <- "osm_type"
schema_name <- "osm"

con <- dbConnect(dbDriver("PostgreSQL"), 
                 host = "localhost", 
                 port = 5432, 
                 user = "postgres", 
                 password = "postgres", 
                 dbname = "urmo") 


field_names <- get_field_names(con, table_name)

unique_vals <- get_unique_values(con, schema_name, table_name, field_name)

select_string <- generate_select_string(unique_vals)
select_string <- paste(select_string, collapse= ", ")

select_string <- paste("Selektiere und Berechne irgendwas mit: ", select_string)
print(select_string)
dbDisconnect(con)


