## Population BreakDown
## From block_pop to GridCell 
## following calculate_various_rates_per_plr_from_srv.sql - script; adapted
## disaggregating the Block-population onto the no of households, and then summing those households to Grid cell (ORDER BY gid [unique cell identifier])


VARIABLES:
  pop_blk <- "pop_blk"
  ex_table1_schema <- "urmo"
  ex_table2_schema <- "urmo"
  result_table_name <- "result_bike_hex_2000"
  blk_id <- "blk_id"
  kgs44_id <- "kgs44_id"
  kgs44 <- "kgs44"
  ex_table2_col <- "hh"
  ex_table1_geom <- "the_geom"
  ex_table2_geom <- "the_geom"
  agg_id  <- "agg_id"
  agg_table1_geom <- "geom"
  
## 
## Helper Function, reading all column names which are LIKE pop% and emp% 
## to provide a vector of Values to later iterate through and copy those relevant columns to the data table
##

    
getColNames <- function (con,  urmo, pop_blk)
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
    urmo,
    pop_blk,
    "%",
    "%"
    ))
  
  vektorColNames <- vektorColNamesdf [,1]
  
  return(vektorColNames) 
  
}


vektorColNames <- getColumnNames (con, urmo, pop_blk)


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
}

updatedTable <- updateTableWithColNames (con, result_table_name, vektorColNames)


##
## WRITE the population Informatino into the Table updated with the new Col names
## Variables are: ex_table1 -> the pop_blk, ex_table2 -> the householdData from KGS44 and
## agg_table -> the reaggreagtion to the results (aka-Grid) table
## Calc is 
## pop2hh: division of the total population in each ex_table1 Cell by the sum of all households from ex_table2in each Cell of ex_table1
## hhPerGrid: A selection of all hh present per each cell of the agg_table
## SELECT: SUM() of the population ordered by the agg_ID
##


calcPop2Cell <- function(con, result_table_name, vektorColNames, blk_id, ex_table2_col, kgs44_id, ex_table1_schema, pop_blk,
                         ex_table2_schema, kgs44, ex_table2_geom, ex_table1_geom, agg_id, agg_table1_geom)
  
{
  popPerCell <- dbGetQuery(con, sprintf( 
    
    "UPDATE %s 
      SET %s = foo.%s
    FROM (
      WITH pop2hh AS                                 -- which Berlin_block_pop is each household located in?
    (
      SELECT 	
        p.%s, 
        p.%s/sum(k.%s) As PopPerHh,
        k.%s
          FROM %s.%s p 
            JOIN %s.%s k 
            ON ST_Within(k.%s, p.%s)
            WHERE k.%s > 0
        GROUP BY p.%s, p.%s, k.%s
     ),
    
    hhPerGrid AS                                     -- which Aggregation cell (GridCell) is each household located in?
  (
    SELECT 
      s.%s,
      k.%s,
      k.%s
        FROM %s.%s k 
        JOIN %s s 
          ON ST_Within(k.%s, s.%s)
    GROUP BY s.%s, k.%s, k.%s
    )

    SELECT 
      hh.%s,
      sum(pop.PopPerHh)	AS %s
        FROM pop2hh AS pop
        JOIN hhPerGrid AS hh
          ON (pop.%s = hh.%s)
    GROUP BY hh.%s
    ORDER BY hh.%s
    ) as foo
    WHERE %s.%s = foo.%s
    ;"
    
    ,
    result_table_name,                 ## UPDATE
    vektorColNames, vektorColNames,    ## SET 
    blk_id,                            ## SELECT 1 p.
    vektorColNames, ex_table2_col,     ## SELECT 2 p.    vektor - hh
    kgs44_id,                          ## SELECT 3 k.
    ex_table1_schema, pop_blk,         ## FROM p
    ex_table2_schema, kgs44,           ## JOIN k
    ex_table2_geom, ex_table1_geom,    ## ST_Within (points form kgs in area of population cell aka pop_blk)
    ex_table2_col,                     ## WHERE -- hh
    blk_id, vektorColNames, kgs44_id,  ## GROUP BY
    agg_id,                            ## SELECT1  -- agg_id (grid)
    kgs44_id,                          ## SELECT2  -- kgs44_id
    ex_table2_col,                     ## SELECT3  -- hh - household count
    ex_table2_schema, kgs44,           ## FROM k
    result_table_name,                 ## JOIN s
    ex_table2_geom, agg_table1_geom,   ## ST_Within (points form kgs in area of aggregation cell aka grid cell)
    agg_id, kgs44_id, ex_table2_col,   ## GROUP BY   -- Grid_ID, kgs44(extable2)_id, hh (extable2col)
    agg_id,                            ## SELECT1  -- agg_id (grid)
    vektorColNames,                    ## SELECT1 AS ---
    kgs44_id, kgs44_id,                ## ON  -- kgs44_id
    agg_id,                            ## GROUP BY  -- agg_id (grid)
    agg_id,                            ## ORDER BY  -- agg_id (grid)
    result_table_name, agg_id, agg_id  ## WHERE 
    
  ))
}

insertPop2table <- calcPop2Cell(con, result_table_name, vektorColNames, blk_id, ex_table2_col, kgs44_id, ex_table1_schema, pop_blk,
                                ex_table2_schema, kgs44, ex_table2_geom, ex_table1_geom, agg_id, agg_table1_geom)


##
## FINAL Function, calling everything and writing the table
##

