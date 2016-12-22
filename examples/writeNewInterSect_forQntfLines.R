createInterSecTable(con, "bz_network_bike_ind_III", "urmo.bz", "bz_id" , "the_geom", "osm.berlin_network_old", "bikeusage", "id", "shape")


createInterSecTable <- function (
  connection,
  resultTable_name,
  grid_name, grid_id, grid_geom,
  edge_table_name, edge_type_col, edge_id, edge_geom
) 
{
  intersectTable <- dbGetQuery(connection, sprintf(
    "
    DROP TABLE IF EXISTS public.%s_interSect;
 
  WITH Inters AS (
     SELECT 
      row_number() over (order by 1) as key,
      grid.%s AS gridId,
      Ex_Area.%s AS LineType,
      Ex_Area.%s AS edgeId
    FROM %s AS grid
      LEFT JOIN %s AS Ex_Area
        ON (ST_INTERSECTS(grid.%s, ST_Transform(Ex_Area.%s, 25833)))
    -- WHERE Ex_Area.%s LIKE '%s'
  )
  SELECT * INTO public.%s_interSect
    FROM Inters
    ;
    
  --  ALTER TABLE %s_interSect ADD PRIMARY KEY (key);"
    ,
    resultTable_name,           ## DROP TABLE IF
    grid_id,                    ## grid        -- column with the unique Agg_Area_ID e.g. PLR-id
    edge_type_col,              ## EX_Area  - 1 - edge_type_col.    -- column with linetype specification
    edge_id,                    ## EX_Area  - 2 - 
    grid_name,                  ## FROM       -- table containing the Aggreation Area geometries 
    edge_table_name,            ## LEFT JOIN  -- table containing the Examination Object  geometries and information here: lineTypes
    grid_geom, edge_geom,       ## ON         -- geometrie columns of both Agg and Ex objects
    edge_type_col, "highway%",  ## WHERE      -- type of Line and query for highway in its description --> its an OSM-special
    resultTable_name,           ## SELECT * INTO
    resultTable_name            ## ALTER TABLE
    
  ))
  
  return(intersectTable)
}


