##
## Script for adding/copying a single column of data to an existing table

## Also it is possible to copy multiple colums, see USAGE -2 & -3 below.
## That would involve looping through preconstructed vectors.

## with those vectors it is also possible to perform the usual db-operations aka (col1+col2::integer)/col3
## before inserting those into an new col

## IMPORTANT NOTICE: each column used as old_ColName has to start with "a.", i.e. "a.col2"
##                   see USAGE -2/3/4 (bottom)

## Error messages 1) "RS-DBI driver: (could not Retrieve the result : ERROR:  column "xyz" of relation "abc" does not exist" -- comment the first line -- ALTER TABLE %s.%s DROP ...
##

copyCol <- function ( con,
                      table2update_schema, table2update_name, table2update_id,
                      old_ColName, new_colName, ColType,
                      copyFromTable_schema, copyFromTable_name, copyFromTable_id
                      )
{
  newCol <- dbGetQuery(con, sprintf( 
      "
      -- ALTER TABLE %s.%s DROP COLUMN %s;       --- if error 1 is thrown this needs to be commented
      
      ALTER TABLE %s.%s ADD COLUMN %s %s;
      
      UPDATE %s.%s
        SET %s = %s
          FROM %s.%s AS a
      WHERE %s.%s = a.%s
      ;"
      ,
      table2update_schema, table2update_name, new_colName,           ## ALTER DROP IF EXISTS
      table2update_schema, table2update_name, new_colName, ColType,  ## ALTER ADD
      table2update_schema, table2update_name,                        ## UPDATE
      new_colName, old_ColName,                                      ## SET 
      copyFromTable_schema, copyFromTable_name,                      ## FROM
      table2update_name, table2update_id, copyFromTable_id           ## WHERE
      ))
}

##  
#### USAGE -1 :
##

# copyCol( con, table2update_schema, table2update_name, table2update_id, old_ColName, new_colName, ColType,
#               copyFromTable_schema, copyFromTable_name, copyFromTable_id)

# copyCol (con, "public", "rentbln11", "a.tvz_id", "tvz_id", "id_test", "text", "urmo", "tvz", "tvz_id" )

## for iteration through more then one column a list of col names (both old and new) is needed,
## for simplicities sake, only cols with the same data-type should be used;
## it is possible to construct the loop to iterate through an additional vector [1) old_name 2)new_name 3)data type] though

##
#### USAGE -2 looping function:
##

# vector_newColNames <- c("test_id", "test_idx2")
# vector_oldColNames <- c("a.tvz_id::numeric", "a.tvz_id::numeric+a.tvz_id::numeric")
# 
# for (i in seq_along(vector_oldColNames))  copyCol(  con, "public", "rentbln11", "tvz_id",
#                                                 vector_oldColNames[i], vector_newColNames[i], "text",
#                                                 "urmo", "tvz", "tvz_id")

##
#### USAGE -3  looping to solve problem 2
##

# vector_newColNames <- c("inc1", "inc2", "inc3", "inc4", "fun_dens")
# vector_oldColNames <- c("hh_ek1", "hh_ek2", "hh_ek3", "a.hh_ek4+a.hh_ek5+a.hh_ek6", "fun_dens")
# 
# for (i in seq_along(vector_oldColNames))  copyCol(  con, "public", "rentbln11", "tvz_id",
#                                                     vector_oldColNames[i], vector_newColNames[i], "FLOAT",
#                                                     "spat_char", "tvz_data_num", "tvz_id::integer")

##
#### USAGE -4  average of different cols AvgIncome
##
# 
  # copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
  #           "a.hh_ek1*450+a.hh_ek2*1200+a.hh_ek3*2050+a.hh_ek4*3100+a.hh_ek5*4300+a.hh_ek6*7500", "avgIncome", "FLOAT",
  #           "spat_char", "tvz_data_num", "tvz_id::integer")

##
#### USAGE -5  adding the ratio of migrant per tvz
##
# 
# copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
#           "a.pop_ausl/a.pop_tot", "prop_migr", "FLOAT",
#           "public", "rent_asl_tvz", "agg_id::int")