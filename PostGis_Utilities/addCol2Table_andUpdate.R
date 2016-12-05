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

## USAGE -11  demonstrates the application of CASE WHEN THEN END statment to add a col in the same table
##            and filling it with 1 if a condition is met.

###
### Theoretically even inserting whole subselects aka temporary tables into the from clause part should be possible
###     see experimental USAGE examples -9 & 10 below.


###### PARAMETERS #################################

#' @param connection             -A connection to the PostGIS database.
#' @param table2update_schema    -String- the name of the schema the table, in which data is to be inserted, is located in
#' @param table2update_name      -String- the name of the table to insert data into
#' @param table2update_id        -String- the unique id linking the values to be inserted into with the table where it originates, e.g. tvz_id = tvz_id; can be ::typecast.
#' @param old_ColName            -String- STARTING with "a." the name of the colum to take the data from
#'                                            OR the expression calculating the data, e.g. (a.col1+a.col2)/a.col3
#' @param new_colName            -String- the name which will be given to the new col holding the inserted data in the table2update
#' @param ColType                -String- the type the new_colName column shall have, no casting is allowed here, so make sure what you choose
#' @param copyFromTable_name     -STRING- name of the table to get data from; if not in public write is so: "schema.copyFromTable_name"
#'                                            OR a whole subselect like this "(select * from ~)" can be used. SEE Usage -9 below
#' @param copyFromTable_id       -String- the name of the colum with the unique_id of copyFromTable_name to connect to table2update_id, e.g. Tvz_id = tvz_id; can be ::typecast.


copyCol <- function ( con,
                      table2update_schema, table2update_name, table2update_id,
                      old_ColName, new_colName, ColType,
                      copyFromTable_name, copyFromTable_id
                      )
{
  newCol <- dbGetQuery(con, sprintf( 
      "
      -- ALTER TABLE %s.%s DROP COLUMN %s;       --- if error 1 is thrown this needs to be commented
      
      ALTER TABLE %s.%s ADD COLUMN %s %s;
      
      UPDATE %s.%s
        SET %s = %s
          FROM %s AS a
      WHERE %s.%s = a.%s
      ;"
      ,
      table2update_schema, table2update_name, new_colName,           ## ALTER DROP IF EXISTS
      table2update_schema, table2update_name, new_colName, ColType,  ## ALTER ADD
      table2update_schema, table2update_name,                        ## UPDATE
      new_colName, old_ColName,                                      ## SET 
      copyFromTable_name,                                            ## FROM
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
#                                                     "spat_cahr.tvz_data_num", "tvz_id::integer")

##
#### USAGE -4  average of different cols AvgIncome
##
# 
  # copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
  #           "a.hh_ek1*450+a.hh_ek2*1200+a.hh_ek3*2050+a.hh_ek4*3100+a.hh_ek5*4300+a.hh_ek6*7500", "avgIncome", "FLOAT",
  #           "spat_cahr.tvz_data_num", "tvz_id::integer")

##
#### USAGE -5  adding the ratio of migrant per tvz
##
# 
# copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
#           "a.pop_ausl/a.pop_tot", "prop_migr", "FLOAT",
#           "public.rent_asl_tvz", "agg_id::int")

##
#### USAGE -6  adding UrMoAC output file to aggregate table
##
# # a) paste the tvz gid, the foreign key for the UrMoAc output
# copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
#           "a.gid", "tvz_gid", "Int",
#           "urmo.tvz12", "code::int")
# # b) copy the UrMoac result 
# copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_gid",
#           "a.avg_tt", "highw_avg_tt_pass", "FLOAT",
#           "public.urmo_highway_tt_pass", "fid")

##
#### USAGE -7  adding # of SUT lines to rentTbl
##
# copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
#           "a.numlines_t+a.numlines_u+a.numlines_s", "no_SUT_lines", "Int",
#           "spat_cahr.tvz_data_num", "tvz_id::int")

##
#### USAGE -8  adding green area per TVZ
##
# copyCol(  con, "public", "rent", "tvz_id",
#           "a.green_tvz_surround", "green_tvz_surround", "numeric",
#           "rent_asl_tvz", "agg_id::integer")

####
## Experimental be warned:
####

##
#### USAGE -9   inserting whole subselects into the from clause:  YES it works!
##              in this case the avg of the tvz_ids
##              which are ST_touching aka surrounding each tvz-cell are queried for.
##
 # copyCol(  con, "public", "tvz_test", "tvz_id",
 #           "a.bid", "avg_adj_tvz_id", "Int",
 #           "(select  a.tvz_id as aid, avg(b.tvz_id::int) as bid 
 #                    from urmo.tvz as a JOIN urmo.tvz as b
 #                    ON ST_touches((a.the_geom), b.the_geom)
 #                    group by a.tvz_id
 #                    order by a.tvz_id)",
 #           "aid")


##
#### USAGE -10  updating rent table
##              with the averaged green proportion between itself and all surrounding cells
##              
##
# copyCol(  con, "public", "rentbln_18m_dl_da_rc", "tvz_id",
#           "a.avg", "prop_green_sourround", "numeric",
#           "(select  a.tvz_id as aid, avg(b.prop_green_tvz) as avg
#                    from rentbln_18m_dl_da_rc as a JOIN rentbln_18m_dl_da_rc as b
#                    ON ST_intersects((a.geom), b.geom)
#                    group by a.tvz_id
#                    order by a.tvz_id)",
#           "aid")

##
#### USAGE -11  updating rent table
##  WORKING     classification attempt with CASE WHEN END
##              to set all cols 1 where gbgroesse = 1 and all others = 0
##              using the same table.
## 

# copyCol(  con, "public", "rent", "id",
#           "(select case
#             WHEN a.gbgroesse = 1 THEN 1
#             ELSE 0 END)",
#           "singleFam", "numeric",
#           "rent", "id")

