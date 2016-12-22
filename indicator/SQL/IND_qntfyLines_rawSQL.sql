--- write super reduced berlin_netwotk table
SELECT * INTO _qntfyLine_lines_test
FROM osm.berlin_network
WHERE osm_type IN ('highway.motorway','highway.trunk')

--- run intersection query from 'qntfyLines_forCleanOSM_Bike'

 SELECT * INTO public._qntf_lines_InterSec_test FROM
      (SELECT 
        row_number() over (order by 1) as key,
        Agg_Area.bz_id AS Agg_ID,
        Ex_Area.osm_type AS LineType,
        ST_Multi(ST_Intersection(Agg_Area.the_geom, ST_Transform(Ex_Area.shape, 25833)))::geometry(multiLineString, 25833) as geom
          FROM
            urmo.bz AS Agg_Area
              LEFT JOIN public._qntfyLine_lines_test AS Ex_Area
                ON (ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Area.shape, 25833)))
          -- WHERE 
          -- Ex_Area.%s LIKE '%s' AND 
          -- ST_isValid(Agg_Area.%s) = TRUE AND ST_isValid(ST_Transform(Ex_Area.%s, 25833)) = TRUE 
      ) as foo;


      
    id_column,                    ## Agg_Area         -- column with the unique Agg_Area_ID e.g. PLR-id
    label_column,                 ## label_column.    -- column with linetype specification
    
    Agg_geom, Ex_geom,            ## ST_Multi         -- geometry columns of both Agg and Ex objects
    Agg_Area,                     ## FROM             -- table containing the Aggreation Area geometries 
    Ex_Area,                      ## LEFT JOIN        -- table containing the Examination Object  geometries and information here: lineTypes
    Agg_geom, Ex_geom,            ## ON               -- geometrie columns of both Agg and Ex objects
    ## label_column, "highway%",  ## WHERE            -- type of Line and query for highway in its description --> its an OSM-special
    Agg_geom, Ex_geom,            ## WHERE            -- geometrie columns of both Agg and Ex objects
    Agg_geom, Ex_geom             ## WHERE            -- geometrie columns of both Agg and Ex objects