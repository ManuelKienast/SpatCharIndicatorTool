##
##calc Intersect table of compiledimport and write it to new table
##

### 

createTempISTable <- function (connection, resultTable_name, grid_schema, grid_name, grid_geom) 
  
{
  tempISTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS public.%s_intersect;
    
    SELECT * INTO public.%s_intersect FROM
    (
    SELECT 
    row_number() over (order by 1) as key,
    ci.interval_begin,
    ci.edge_arrived,
    ci.edge_departed,
    ci.edge_entered,
    ci.edge_left,
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.geom as geom_point,
    r.%s as geom_grid,
    r.gid
    FROM public.compiledimport AS ci 
    JOIN %s.%s AS r 
    ON ST_Within(ci.geom, r.%s) 
     ) as foo;
    

    DROP INDEX IF EXISTS %s_intersect_gix;
    CREATE INDEX %s_intersect_gix 
        ON public.%s_intersect
        USING GIST (geom_point);
    "
    ,
    resultTable_name, resultTable_name,   ###  DROP TABLE ...
    grid_geom,                            ###
    grid_schema, grid_name,               ###  JOIN
    grid_geom,                            ###  St_within
    resultTable_name,resultTable_name,    ###  DROP INDEX
    resultTable_name                      ###  ON
  ))
  
  return(tempISTable)
}




############################################################################################### 
##  ##  ##  compute IntersTable      ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  
###############################################################################################
    

calcTrafficTable <- function (connection, resultTable_name
  
          )
{
  traffic_per_grid <- dbGetQuery(connection, sprintf(
    
    "
  DROP TABLE IF EXISTS public.%s;
  SELECT * INTO public.%s FROM (
  
  WITH startingTrips AS(
   
    SELECT
      sum(edge_departed) AS trips_d,
      gid,
      geom_grid
        FROM public.%s_intersect
        group by gid, geom_grid),
    
  EnteringTrips AS(
    SELECT
      sum(a.edge_entered) AS trips_e,
      a.gid
        FROM public.%s_intersect a
          LEFT JOIN public.%s_intersect b
            ON a.edge_from = b.edge_to
        WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
    GROUP BY a.gid)
    
  SELECT
    a.gid,
    a.trips_d,
    b.trips_e,
    a.trips_d+b.trips_e as total,
    a.geom_grid
      FROM startingTrips a
        LEFT JOIN enteringTrips b
          ON a.gid = b.gid
    )as foo
    ;
    
  
    ",
    resultTable_name,
    resultTable_name,
    resultTable_name,
    resultTable_name,
    resultTable_name
  ))
    
  }



############################################################################################## 
#  ##  ##  combination for interation through grids  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################


calcTraffic <- function (connection, grid_schema, grid_name, resultTable_name, grid_geom
                          
                         )

  {createTempISTable(connection, resultTable_name, grid_schema, grid_name, grid_geom) 
  
   calcTrafficTable(connection, resultTable_name)
                                
  }                            

 
gridsize <- c("500", "1000", "2000", "4000")

for (i in gridsize){
  calcTraffic(con, "grids", sprintf("fish_%s",i), sprintf("SumoTraffic_fish_%s",i), "geom")
  }
  



#calcTrafficTable(connection, "SumoTraffic_hex4000")
#
# vgrid <- c(1000, 2000)
# 
#   for(grid_size in vgrid){
#     calcTraffic(con, "grids", sprintf("hex_", grid_size), sprintf("sumo_traffic_hex_%s",grid_size))
#   }
#   
