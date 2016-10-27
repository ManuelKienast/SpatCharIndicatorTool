## Population BreakDown
## From block_pop to GridCell 
## following calculate_various_rates_per_plr_from_srv.sql - script; adapted
## disaggregating the Block-population onto the no of households, and then summing those households to Grid cell (ORDER BY gid [unique cell identifier])



  
## 
## Helper Function, reading all column names which are LIKE pop% and emp% 
## to provide a vector of Values to later iterate through and copy those relevant columns to the data table
##

    
getColNames <- function (con, ex_table1_schema, ex_table1)
{
  vektorColNamesdf <- dbGetQuery(con, sprintf( 
    
    "SELECT column_name
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE 	TABLE_SCHEMA = '%s'
		  AND     TABLE_NAME = '%s'
      AND     (column_name LIKE 'pop%s'
              OR column_name LIKE 'emp%s')
    ;"
    ,
    ex_table1_schema,
    ex_table1,
    "%",
    "%"
    ))
  
  vektorColNames <- vektorColNamesdf [,1]
  
  return(vektorColNames) 
  
}

##
## UPDATE TABLE (created with qntfyLines() Function) and ADD COLUMNS  with the populations for each Cell of the chosen Aggregation Area
##

updateTableWithColNames <- function (con, result_table_name, vektorColNames)

  {
  newColNames <- dbGetQuery(con, sprintf( 
    
    "ALTER TABLE %s DROP COLUMN IF EXISTS %s;
    ALTER TABLE %s ADD COLUMN %s FLOAT;
    "
    ,
    result_table_name, vektorColNames,
    result_table_name, vektorColNames
    
  ))
  return(newColNames)
}

##
## WRITE the population Informatino into the Table updated with the new Col names
## Variables are: ex_table1 -> the pop_blk, ex_table2 -> the householdData from KGS44 and
## agg_table -> the reaggreagtion to the results (aka-Grid) table
## Calc is 
## pop2hh: division of the total population in each ex_table1 Cell by the sum of all households from ex_table2in each Cell of ex_table1
## hhPerGrid: A selection of all hh present per each cell of the agg_table
## SELECT: SUM() of the population ordered by the agg_ID
##

insertPop2table <- function(con, vektorColNames,
                            result_table_schema, result_table_name, agg_id, result_table_geom,
                            ex_table1_schema, ex_table1, ex_table1_id, ex_table1_geom,
                            ex_table2_schema, ex_table2, ex_table2_col,ex_table2_geom)
{
  popPerCell <- dbGetQuery(con, sprintf( 
    
    "UPDATE %s 
      SET %s = foo.%s
        FROM (

With hhPerBlk AS (
	    SELECT
        p.%s AS blk_id,
        sum(%s) AS hhPerBlk
          FROM %s.%s k
            JOIN %s.%s p
              ON ST_Within(k.%s, p.%s)
    GROUP by p.blk_id),
    
  popPerHh AS (
    SELECT 
      p.%s / h.hhPerBlk AS popPerHh,
      p.%s AS blk_id
        FROM %s.%s AS p
          LEFT JOIN hhPerBlk as h
            ON p.blk_id = h.blk_id
          WHERE h.hhPerBlk >0
    GROUP BY p.blk_id, p.%s, h.hhPerBlk)
    
  SELECT 
    sum(k.%s*popPerHh) as %s,
    g.%s
      FROM %s.%s g
        JOIN %s.%s k
          ON ST_Within(k.%s, g.%s)
        LEFT JOIN %s.%s p 
          ON ST_Within (k.%s, p.%s)
        LEFT JOIN popPerHh as pop
          ON p.%s = pop.blk_id
    GROUP BY g.%s
  ) as foo
  WHERE %s.%s = foo.%s

    ;"
    ,
    result_table_name,                 ## UPDATE
    vektorColNames, vektorColNames,    ## SET 
    ex_table1_id,                      ## SELECT 1 p.
    ex_table2_col,                     ## sum - hh
    ex_table2_schema, ex_table2,       ## FROM k  kgs44
    ex_table1_schema, ex_table1,       ## JOIN  p
    ex_table2_geom, ex_table1_geom,    ## ST_Within (points from kgs in area of population cell aka pop_blk)
    vektorColNames,                    ## SELECT 1 division
    ex_table1_id,                      ## SELECT 1 p.
    ex_table1_schema, ex_table1,       ## FROM  p
    vektorColNames,                    ## GROUP BY
    ex_table2_col, vektorColNames,     ## SELECT1 - hh, Colnames
    agg_id,                            ## SELECT2 - g - grid
    result_table_schema,result_table_name,  ## FROM g
    ex_table2_schema, ex_table2,       ## JOIN k  kgs44
    ex_table2_geom, result_table_geom, ## ON ST_Within -1- (points form kgs in area of result geom - grids)
    ex_table1_schema, ex_table1,       ## LEFT JOIN p
    ex_table2_geom, ex_table1_geom,    ## ON ST_Within -2- (points form kgs in area of population cell aka pop_blk)
    ex_table1_id,                      ## ON -3- p.
    agg_id,                            ## GROUP BY
    result_table_name, agg_id, agg_id  ## WHERE
    
  ))

  return(popPerCell)
  
}

##
## FINAL Function, calling everything and looping where appropriate
##

calcPop2Cell <- function(con,
                         result_table_schema, result_table_name, agg_id, result_table_geom,
                         ex_table1_schema, ex_table1, ex_table1_id, ex_table1_geom,
                         ex_table2_schema, ex_table2, ex_table2_col,ex_table2_geom
                         )
{
  vektorColNames <- getColNames (con, ex_table1_schema, ex_table1)

  for (i in vektorColNames) updateTableWithColNames(con, "result_bike_hex_2000", i)

  for (i in vektorColNames) insertPop2table(con, i,
                                  result_table_schema, result_table_name, agg_id, result_table_geom,
                                  ex_table1_schema, ex_table1, ex_table1_id, ex_table1_geom,
                                  ex_table2_schema, ex_table2, ex_table2_col, ex_table2_geom)
  }

# USAGE:
# resutltable <- calcPop2Cell(con, 
#                             "public", "result_bike_hex_2000", "agg_id", "geom",
#                             "urmo", "pop_blk", "blk_id", "the_geom",
#                             "urmo", "kgs44", "hh", "the_geom")

#######################################################################################################
####  Test Cases  ###################################################################################################
#######################################################################################################

# vektorColNames <- getColNames (con, "urmo", "pop_blk")
# str(vektorColNames)
# 
# updatedTable <- updateTableWithColNames (con, "result_bike_hex_2000", "test21")
# 
# VARIABLES:
#   
# pop_blk <- "pop_blk"
# ex_table1 <- "pop_blk"
# ex_table1_schema <- "urmo"
# ex_table2_schema <- "urmo"
# result_table_name <- "result_bike_hex_2000"
# result_table_schema <- "public"
# ex_table1_id <- "blk_id"
# blk_id <- "blk_id"
# ex_table2_id <- "kgs44_id"
# kgs44_id <- "kgs44_id"
# ex_table2 <- "kgs44"
# kgs44 <- "kgs44"
# ex_table2_col <- "hh"
# ex_table1_geom <- "the_geom"
# ex_table2_geom <- "the_geom"
# result_table_id <- "agg_id"
# agg_id  <- "agg_id"
# result_table_geom <- "geom"
# vektorColNames <- "pop_tot"