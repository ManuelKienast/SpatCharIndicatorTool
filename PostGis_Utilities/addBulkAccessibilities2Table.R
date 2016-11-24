##
## Set of functions to facilitate the automatic copying of all data-columns from one to another table (in the same db)
##
## automatic handling of input(copy from columns) of tables created with: SQL-Script: 20160719_join_accessibilities_tvz12.sql
##
## all columns except those specified in the AND COL_name NOT IN ()
## will be bulk copied into another table, incl creating the necessary cols et al.
##
## the only structural neccesity is that the table 2 update is populated with an ID.column which identifies the connection
## with the data from the accessibilities table (the table to copy from), e.g. the TVZ_id column
##
## if these identifier cols are present the script should also be able to handle bulk copies from other tables, 
## IF these cols contain data castable as FLOAT; geometry cols are automatically excluded if IN ('geom''the_geom''shape')

##
## The four following funtions are contained in this script
##
            
            # 1- getAccColNames               - reads all column names from the copyFrom_table besides those in the WHERE-clause
            # 2- updateTableWithAccColNames   - updates the table2update_name with the colnames from the vAccColNames vector created w/ 1
            # 3- insertAcc2table              - inserts (UPDATE COL SET COL FROM) the data form copyFromTable_name into table2update_name
            # 4- updateWithAccData            - compiles the above funcs and loops them for all items in vAccColNames



###### PARAMETERS #################################

#' @param connection                 A connection to the PostGIS database.
#' @param table2update_schema        -String- the schema of the table to copy the data into
#' @param table2update_name          -String- the name of table to copy the data into
#' @param table2update_id            -String- the name of the colum to connect both tables with 
#' @param copyFromTable_schema       -String- the schema of the table to copy the data from
#' @param copyFromTable_name         -String- the name of the table to copy the data from
#' @param copyFromTable_id           -String- the name of the colum to connect both tables with 





############################################################################################## 
# -1-  #  ##  ##    reading the column names form the source table    ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
## the function excludes specific cols: tvz12_id, tvz12_name, district and fid
## if the table diverges from the one created with the script mentioned at top, this vector probably needs to be adjusted
## different usage of the following function    source("indicator\\calcPop_viaKGS44.R") View(getColNames)
##
getAccColNames <- function(
                            con,
                            copyFromTable_schema, copyFromTable_name
                            )
{
  vAccColNamesdf <- dbGetQuery(con, sprintf( 
    "
    SELECT column_name, data_type
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE 	TABLE_SCHEMA = '%s'
		  AND     TABLE_NAME = '%s'
      AND     column_name NOT IN ('tvz12_id', 'tvz12_name', 'district', 'fid', 'gid', 'tvz_id', 'geom', 'the_geom', 'shape') 
    ;"
    ,
    copyFromTable_schema,
    copyFromTable_name
    ))

  return(vAccColNamesdf)
}

#USAGE:
#vAccColNames <- getAccColNames(con, "urmo", "tvz")






############################################################################################## 
# -2-  #  ##  ##    creating the  columns in the copy2tab with the freshly accquired colNames ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
## sadly because of legacy PostGresQL-db (i.e. 8.4.) on ACHILLES the desired syntax DROP COLUMN [col.name] IF EXISTS 
## is not supported, therefore the ALTER TAB DROP COL IF EXISTS clause is currently not working as desired and commented out
## As a workaround once the columns have been created this function should be commented out ### if function 4
## 'updateWithAccData' has to be run a second time on the same table
##
updateTableWithAccColNames <- function( con,
                                        table2update_schema, table2update_name,
                                        vAccColNames
                                        )
{
  newAccColNames <- dbGetQuery(con, sprintf( 
    "
    -- ALTER TABLE %s.%s DROP COLUMN IF EXISTS %s;       
    ALTER TABLE %s.%s ADD COLUMN %s FLOAT
    ;"
    ,
    table2update_schema, table2update_name, vAccColNames,
    table2update_schema, table2update_name, vAccColNames
    ))
}





############################################################################################## 
# -3-  #  ##  ##    Inserting all the data into the copy2Table  ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
insertAcc2table <- function(
                            con,
                            vAccColNames,
                            table2update_schema, table2update_name, table2update_id,
                            copyFromTable_schema, copyFromTable_name, copyFromTable_id
                            )
{
  insertData <- dbGetQuery(con, sprintf( 
    "
    UPDATE %s.%s
      SET %s = a.%s
        FROM %s.%s AS a
    WHERE %s.%s = a.%s
    ;"
    ,
    table2update_schema, table2update_name,                ## UPDATE
    vAccColNames, vAccColNames,                            ## SET 
    copyFromTable_schema, copyFromTable_name,              ## FROM
    table2update_name, table2update_id, copyFromTable_id   ## WHERE
    ))
}





############################################################################################## 
# -4-  #  ##  ##    running all other functions and loop through the vAccColNames vector    ##  ##  ##  ##  ##  ##  ##  ##  ##
##############################################################################################
##
updateWithAccData <- function( con,
                               table2update_schema, table2update_name, table2update_id,
                               copyFromTable_schema, copyFromTable_name, copyFromTable_id
                              )
{
  vAccColNamesdf <- getAccColNames ( con, copyFromTable_schema, copyFromTable_name)
  
  vAccColNames <- vAccColNamesdf [,1]
  
  vAccColTypes <- vAccColNamesdf [,2]

  for (i in vAccColNames) updateTableWithAccColNames( con, table2update_schema, table2update_name, i)
  
  for (i in vAccColNames) insertAcc2table( con, i, table2update_schema, table2update_name, table2update_id,
                                           copyFromTable_schema, copyFromTable_name, copyFromTable_id)
  
} 

##USAGE:
## updateWithAccData( con, "public", "rentbln11", "tvz_id", "spat_char", "accessibilities_tvz12", "tvz12_id")




    

# ###### PLAYGROUND  #####
# copyFromTable_schema <- "spat_char"
# copyFromTable_name <- "accessibilities_tvz12"
# 
# newAccColNames <- dbGetQuery(con, sprintf( 
#   "
#   ALTER TABLE public.rentbln11 DROP test_col;
#   ALTER TABLE public.rentbln11 ADD COLUMN test_col FLOAT
#   ;"))
#   ,
#   table2update_schema, table2update_name, vAccColNames,
#   table2update_schema, table2update_name, vAccColNames
# ))
#str(con)
