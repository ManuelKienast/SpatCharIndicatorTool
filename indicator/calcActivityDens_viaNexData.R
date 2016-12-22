
############################################################################################### 
#######  Variables for testing  ########################################################################################
###############################################################################################

result_table_id <- "agg_id"
pos_table_id <- "gid"
result_table_geom <- "geom"
pos_table_empCol <- "employee"
wz_table_colAbt <- "wz_abt"
wz_table_colKla <- "wz_kla"
wz_table_colGru <- "wz_gru"
pos_table_schema <- "urmo"
pos_table <- "pos"
result_table_schema <- "public"
result_table_name <- "result_bike_hex_2000"
pos_table_geom <- "the_geom"
wz_table_schema <- "urmo"
wz_table <- "wz"
wz_table_id <- "wz_id"
pos_table_wzid <- "wz_id"

###############################################################################################
###############################################################################################





# Calcs from SQL-Script: "calculate_activity_density_per_plr_from_pos.sql"
# calculate density of various acitivities per PLR from POS data
# including aggregation from POS locations to PLR
# runtime: 9060 ms -> ca. 9 s

  

### create Vektor with ColNames

vectorColNames <- c("shop_dens", "shop_dens_pop", "daily_dens", "daily_dens_pop", "rest_dens", "rest_dens_pop",
               "school_dens", "school_dens_pop", "health_dens", "health_dens_pop", "fun_dens", "fun_dens_pop",
               "employees")

vWhereClauses <- c(sprintf("wz_abt = '47'"),
                   sprintf("wz_abt = '47'"),
                   sprintf("wz_kla IN('47.11','47.81') OR wz_gru ='47.2'"),
                   sprintf("wz_kla IN('47.11','47.81') OR wz_gru ='47.2'"),
                   sprintf("wz_abt = '56'"),
                   sprintf("wz_abt = '56'"),
                   sprintf("wz_gru IN('85.1','85.2','85.3','85.4')"),
                   sprintf("wz_gru IN('85.1','85.2','85.3','85.4')"), 
                   sprintf("wz_abt = '86' OR wz_kla IN('47.73','47.74')"),
                   sprintf("wz_abt = '86' OR wz_kla IN('47.73','47.74')"),
                   sprintf("wz_abt IN ('90','91','92','93')"),
                   sprintf("wz_abt IN ('90','91','92','93')"),
                   sprintf("1=1")
                   )
# # #### TEST CASES
# vectorColNames <- c("shop_dens", "shop_dens_pop")
# vWhereClauses <- c(sprintf("wz_abt = '47'"), sprintf("wz_abt = '47'"))


### Write Temporary Intersec table storing data for computation speed up

createTempISTable <- function (
  con,
  result_table_schema, result_table_name, result_table_id, result_table_geom,
  pos_table_schema, pos_table, pos_table_id, pos_table_empCol, pos_table_wzid, pos_table_geom,
  wz_table_schema, wz_table, wz_table_id, wz_table_colAbt, wz_table_colKla, wz_table_colGru
) 
  
{
  tempISTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS public.tempIS;
    
    SELECT * INTO public.tempIS FROM
    (
      SELECT 
        row_number() over (order by 1) as key,
        p.%s AS pos_id,
        r.%s AS agg_id,
        St_Area(r.%s)/1000000 AS area_km2,
        p.%s AS employees,
        w.%s AS wz_abt,
        w.%s AS wz_kla,
        w.%s AS wz_gru
          FROM %s.%s AS p 
            JOIN %s.%s AS r 
              ON ST_Within(p.%s, r.%s) 
            JOIN %s.%s AS w
              ON w.%s = p.%s 
      GROUP BY pos_id, r.%s , r.geom, p.employee, w.wz_abt, w.wz_kla, w.wz_gru
      ORDER BY r.%s
    ) as foo;
    
    ALTER TABLE public.tempIS ADD PRIMARY KEY (key);"
    ,
    
    pos_table_id,                      ## SELECT -0-  gid [primary-key]
    result_table_id,                   ## SELECT -1-  agg_id
    result_table_geom,                 ## SELECT -2-  area
    pos_table_empCol,                  ## SELECT -2b- employees
    wz_table_colAbt,                   ## SELECT -3-  wz-abteilung key column (WZ 2008)
    wz_table_colKla,                   ## SELECT -3-  wz-klassen key column (WZ 2008)
    wz_table_colGru,                   ## SELECT -3-  wz-gruppen key column (WZ 2008)
    pos_table_schema, pos_table,       ## FROM AS p; "Point of Sale" table- containg addresses and point data
    result_table_schema, result_table_name,  ## JOIN r
    pos_table_geom, result_table_geom,    ## ON ST_Within (points from POS-table in area of result table geoms) 
    wz_table_schema, wz_table,         ## JOIN AS w; "Wirtschaftszwiege" table- containg short form handles
    wz_table_id, pos_table_wzid,       ## ON - wz_id = wz_id the join btwn the wz ids form wz and pos table
    result_table_id,                   ## GRROUP BY agg_id
    result_table_id                    ## GRROUP BY agg_id
    
  ))
  
  return(tempISTable)
}



##
### Write Cols into result table with the names from vColNames
##
updateResultTable <- function(con, vectorColNames, result_table_name)

  {
  newColNames <- dbGetQuery(con, sprintf( 
    
    "ALTER TABLE %s DROP COLUMN IF EXISTS %s;
    ALTER TABLE %s ADD COLUMN %s FLOAT;
    "
    ,
    result_table_name, vectorColNames,
    result_table_name, vectorColNames
    ))
  return(newColNames)
}




##
### Insert Function updating the results table with the calculated data
##

updateTable <- function (connection,
                         vectorColNames, vWhereClauses,
                         result_table_schema, result_table_name, result_table_id, result_table_popTotCol
                         ) 
{
  updatedResultTable <- dbGetQuery(connection, sprintf( 
  
  "UPDATE %s 
    SET %s = foo.%s
    FROM (
      With %s AS(
    
  SELECT 
      isT.%s AS agg_id,
        CASE 
          WHEN '%s' != 'employees'
            THEN COUNT(isT.pos_id) 
          ELSE 
            SUM(isT.employees)
        END AS %s
          FROM public.tempIS AS isT
          
          WHERE %s 
    GROUP BY agg_id
    ORDER BY agg_id)
  
  SELECT 
    r.%s AS agg_id,  
    CASE
        WHEN '%s' LIKE '%s'
          THEN t.%s / (r.%s / 1000) 
        WHEN '%s' = 'employees'
          THEN t.%s
        ELSE
          t.%s/tis.area_km2
        END AS %s
    FROM %s.%s AS r
      LEFT JOIN %s AS t
        ON r.agg_id = t.agg_id
      LEFT JOIN public.tempis AS tis
        ON r.agg_id = tis.agg_id
     WHERE t.%s > 0
  )as foo
   WHERE %s.%s = foo.agg_id
  ;"
  ,
  result_table_name,                 ## UPDATE  
  vectorColNames, vectorColNames,    ## SET
  vectorColNames,                    ## with table name
  
  result_table_id,                   ## SELECT isT.%
  vectorColNames,                    ## CASE WHEN
  vectorColNames,                    ## END
  vWhereClauses,                     ## WHERE
  
  result_table_id,                   ## SELECT r.%
  vectorColNames, "%_pop",           ## CASE WHEN -1-
  vectorColNames, result_table_popTotCol,     ## t.%s, pop_tot, vcolNames
  vectorColNames,                    ## CASE WHEN -2-
  vectorColNames,                    ## t% As %
  vectorColNames,                    ## CASE ELSE -3-
  vectorColNames,                    ## END                    
  result_table_schema, result_table_name,  ## FROM r
  vectorColNames,                    ## LEFT JOIN -1-
  vectorColNames,                    ## WHERE > 0
  result_table_name, result_table_id ## WHERE
  ))

  return(updatedResultTable)
  
}
  
##
### Collecting all helper functions into one function
##


calcActivityDens2ResultTable <- function (con, vectorColNames, vWhereClauses,
                                          result_table_schema, result_table_name, result_table_id, result_table_popTotCol, result_table_geom,
                                          pos_table_schema, pos_table, pos_table_id, pos_table_empCol, pos_table_wzid, pos_table_geom,
                                          wz_table_schema, wz_table, wz_table_id, wz_table_colAbt, wz_table_colKla, wz_table_colGru)
{
  
tempISTable <- createTempISTable (
                                    con,
                                    result_table_schema, result_table_name, result_table_id, result_table_geom,
                                    pos_table_schema, pos_table, pos_table_id, pos_table_empCol, pos_table_wzid, pos_table_geom,
                                    wz_table_schema, wz_table, wz_table_id, wz_table_colAbt, wz_table_colKla, wz_table_colGru) 
  
  
for (i in vectorColNames){ updateResultTable (con, i, result_table_name)}
    


for ( i in seq_along(vectorColNames)) {updateTable(
                                                    con, vectorColNames[i], vWhereClauses[i],
                                                    result_table_schema, result_table_name, result_table_id, result_table_popTotCol)}

#mapply(updateTable(con, vectorColNames, vWhereClauses, result_table_schema, result_table_name, result_table_id, result_table_popTotCol), vectorColNames, vWhereClauses )
    
# for (i in vectorColNames){ 
#   for (j in vWhereClauses){  
#     updateTable ( con, i, j, 
#                   result_table_schema, result_table_name, result_table_id, result_table_popTotCol)
#    }
#   }
}


calcActivityDens2ResultTable (con, vectorColNames, vWhereClauses,
                              "public", "result_bike_hex_2000", "agg_id", "pop_tot", "geom",
                              "urmo", "pos", "gid", "employee", "wz_id", "the_geom",
                              "urmo", "wz", "wz_id", "wz_abt", "wz_kla", "wz_gru")



#str(length(vectorColNames))
#test <- seq_along(vectorColNames)
############################################################################################### 
#######  Variables for testing  ########################################################################################
###############################################################################################
### INPUT ORDER USAGE:
# con, vectorColNames, vWhereClauses,
# result_table_schema, result_table_name, result_table_id, result_table_popTotCol, result_table_geom,
# pos_table_schema, pos_table, pos_table_id, pos_table_empCol, pos_table_wzid, pos_table_geom,
# wz_table_schema, wz_table, wz_table_id, wz_table_colAbt, wz_table_colKla, wz_table_colGru)
##
### VARIABLES ORDER USAGE:
##
# con, vectorColNames, vWhereClauses,
# result_table_schema <- "public", result_table_name <- "result_bike_hex_2000", result_table_id <- "agg_id", result_table_popTotCol <- "pop_tot", result_table_geom <- "geom",
# pos_table_schema <- "urmo", pos_table <- "pos", pos_table_id <- "gid", pos_table_empCol <- "employee" pos_table_wzid <- "wz_id", pos_table_geom <- "the_geom",
# wz_table_schema <- "urmo", wz_table <- "wz", wz_table_id <- "wz_id", wz_table_colAbt <- "wz_abt", wz_table_colKla <- "wz_kla", wz_table_colGru <- "wz_gru"
##
##USAGE:
##
# con, vectorColNames, vWhereClauses,
# "public", "result_bike_hex_2000", "agg_id", "pop_tot" "geom",
# "urmo", "pos", "gid", "employee" "wz_id", "the_geom",
# "urmo", "wz", "wz_id", "wz_abt", "wz_kla", "wz_gru"






