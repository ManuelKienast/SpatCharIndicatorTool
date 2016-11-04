##
##calc Intersect table of compiledimport and write it to new table
##

### 

createTempISTable <- function (connection, grid_schema, grid_name) 
  
{
  tempISTable <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS public.sumo_Inters;
    
    SELECT * INTO public.sumo_Inters FROM
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
    r.the_geom as geom_grid,
    r.gid
    FROM public.compiledimport AS ci 
    JOIN %s.%s AS r 
    ON ST_Within(ci.geom, r.the_geom) 
    
    GROUP BY 
    ci.interval_begin,
    ci.edge_arrived,
    ci.edge_departed,
    ci.edge_entered,
    ci.edge_left,
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.geom,
    r.the_geom,
    r.gid
    
    ) as foo;
    
    ALTER TABLE sumo_Inters ADD PRIMARY KEY (key);
    
    CREATE INDEX sumo_Inters_gix 
        ON public.sumo_Inters
        USING GIST (geom_point);
    "
    ,
    grid_schema, grid_name     ###  JOIN
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
  SELECT * INTO public.%s FROM (
  
  With Groupie AS (

  SELECT 
    sum(ci.edge_arrived) as arr,
    sum(ci.edge_departed) as dep,
    sum(ci.edge_entered) as entr,
    sum(ci.edge_left) lef,
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.interval_begin,
    ci.geom_grid,
    ci.gid
    FROM public.sumo_Inters as ci
        
    GROUP BY 
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    interval_begin,
    ci.geom_grid,
    ci.gid
    )
  SELECT 
    row_number() over (order by 1) as key,
    a.gid,
    sum(a.entr) ent,
    sum(a.dep) dep,
    sum(a.entr)+sum(a.dep) total,
    a.geom_grid
      FROM groupie as a 
	      LEFT JOIN sumo_inters_groupgeom as b
		      ON (a.edge_from = b.edge_to)
    WHERE a.gid != b.gid
    GROUP BY a.gid, a.geom_grid
    ORDER BY a.gid
    ) as foo
    ;
    
    ALTER TABLE public.%s ADD PRIMARY KEY (key);
    ",
    resultTable_name,
    resultTable_name
  ))
    
  }

############################################################################################## 
#  ##  ##  combination for interation through grids  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  #
##############################################################################################


calcTraffic <- function (connection, grid_schema, grid_name, resultTable_name
                          
                         )

  {createTempISTable(connection, grid_schema, grid_name) 
  
   calcTrafficTable(connection, resultTable_name)
                                
  }                            

 

calcTraffic(con, "grids", "hex_1000", "SumoTraffic_hex1000")


# vgrid <- c(1000, 2000)
# 
#   for(grid_size in vgrid){
#     calcTraffic(con, "grids", sprintf("hex_", grid_size), sprintf("sumo_traffic_hex_%s",grid_size))
#   }
#   
