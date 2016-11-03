##
##calc Intersect table of compiledimport and write it to new table
##

### Write Temporary Intersec table storing data for computation speed up

createTempISTable <- function (connection) 
  
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
    ci.geom,
    r.gid
    FROM public.compiledimport AS ci 
    JOIN grids.hex_4000 AS r 
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
    r.gid
    
    ) as foo;
    
    ALTER TABLE sumo_Inters ADD PRIMARY KEY (key);
    
    CREATE INDEX sumo_Inters_gix 
        ON public.sumo_Inters
        USING GIST (geom);
    "
  ))
  
  return(tempISTable)
}

sumo_inter <- createTempISTable(con)


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
