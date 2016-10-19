
--  ___________________________
--  Calculates the ratio of line types based on their length inside a polygon, NOW all in one
--  ___________________________


DROP TABLE IF EXISTS public.tempStreet2;
SELECT * INTO public.tempStreet2 FROM (
WITH PLR AS (
	SELECT plr.plr_id, the_geom
	FROM urmo.plr),
temp_G AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_residential_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.residential' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID),
temp_F AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_track_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.track' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID),
temp_B AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_footway_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.footway' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID),
temp_X AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_path_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.path' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID),
temp_N AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_service_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.service' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID),
temp_P AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_secondary_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.secondary' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID),
temp_A AS (
	SELECT  
		Agg_Area.plr_id AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_tertiary_km
			FROM urmo.plr AS  Agg_Area LEFT JOIN osm.berlin_network As Ex_Obj
			ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833))
			WHERE Ex_Obj.osm_type = 'highway.tertiary' AND ST_isValid(Ex_Obj.shape) = TRUE AND ST_isValid(Agg_Area.the_geom) = TRUE
			GROUP BY Agg_ID)
			
SELECT 
	plr.plr_id,
	plr.the_geom,
	G.sum_residential_km, F.sum_track_km, B.sum_footway_km, X.sum_path_km, N.sum_service_km, P.sum_secondary_km, A.sum_tertiary_km,
	sum.sum_length_km AS total_length_km,

	G.sum_residential_km/sum.sum_length_km as residential_ratio,
	F.sum_track_km/sum.sum_length_km as track_ratio,
	B.sum_footway_km/sum.sum_length_km as footway_ratio,
	X.sum_path_km/sum.sum_length_km as path_ratio,
	N.sum_service_km/sum.sum_length_km as service_ratio,
	P.sum_secondary_km/sum.sum_length_km as secondary_ratio,
	A.sum_tertiary_km/sum.sum_length_km as tertiary_ratio,
	
	GREATEST(G.sum_residential_km/sum.sum_length_km,
		F.sum_track_km/sum.sum_length_km,
		B.sum_footway_km/sum.sum_length_km,
		X.sum_path_km/sum.sum_length_km,
		N.sum_service_km/sum.sum_length_km,
		P.sum_secondary_km/sum.sum_length_km,
		A.sum_tertiary_km/sum.sum_length_km) AS dominantType
	
	FROM PLR As plr LEFT JOIN temp_G AS G 
		ON plr.plr_id = G.Agg_ID
	LEFT JOIN temp_F AS F 
		ON plr.plr_id = F.Agg_ID
	LEFT JOIN temp_B AS B 
		ON plr.plr_id = B.Agg_ID
	LEFT JOIN temp_X AS X 
		ON plr.plr_id = X.Agg_ID
	LEFT JOIN temp_N AS N 
		ON plr.plr_id = N.Agg_ID
	LEFT JOIN temp_P AS P 
		ON plr.plr_id = P.Agg_ID
	LEFT JOIN temp_A AS A 
		ON plr.plr_id = A.Agg_ID
	LEFT JOIN (
		SELECT (coalesce(G.sum_residential_km,0) + coalesce(F.sum_track_km,0) + coalesce(B.sum_footway_km,0) + coalesce(X.sum_path_km,0)+ 
			coalesce(N.sum_service_km,0)+ coalesce(P.sum_secondary_km,0)+ coalesce(A.sum_tertiary_km,0)) as sum_length_km,
			plr.plr_id AS sum_ID		
		FROM PLR As plr LEFT JOIN temp_G AS G 
			ON plr.plr_id = G.Agg_ID
		LEFT JOIN temp_F AS F 
			ON plr.plr_id = F.Agg_ID
		LEFT JOIN temp_B AS B 
			ON plr.plr_id = B.Agg_ID
		LEFT JOIN temp_X AS X 
			ON plr.plr_id = X.Agg_ID
		LEFT JOIN temp_N AS N 
			ON plr.plr_id = N.Agg_ID
		LEFT JOIN temp_P AS P 
			ON plr.plr_id = P.Agg_ID
		LEFT JOIN temp_A AS A 
			ON plr.plr_id = A.Agg_ID			
		
		ORDER BY plr.plr_id) as sum	
			ON plr.plr_id = sum.sum_ID		

ORDER BY plr.plr_id ) as Foo;

ALTER TABLE public.tempStreet2 ADD PRIMARY KEY (plr_id);

SELECT * FROM public.tempStreet2;



--  ___________________________
--  Following are older test cases, before everything was AllInOne
--  ___________________________

--  ___________________________
--  INSERT INTO
--  ___________________________


SELECT 
	
	Agg_Area.plr_id AS Agg_ID,
	tS.sum_g_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS g_ratio,
	tS.sum_f_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS f_ratio,
	tS.sum_b_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS b_ratio,
	tS.sum_x_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS x_ratio,
	tS.sum_n_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS n_ratio,
	tS.sum_p_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS p_ratio,
	tS.sum_a_km/(SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000) AS a_ratio,
	SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, ST_Transform(Ex_Obj.shape, 25833))))/1000 AS sum_total_km
		FROM urmo.plr AS  Agg_Area 
			LEFT JOIN osm.network_berlin As Ex_Obj
				ON ST_INTERSECTS(Agg_Area.the_geom, ST_Transform(Ex_Obj.shape, 25833)) 
			LEFT JOIN public.tempStreet AS tS
				ON Agg_Area.plr_id = tS.plr_id
    GROUP BY Agg_ID, Agg_Area.geom, tS.sum_g_km, tS.sum_f_km, tS.sum_b_km, tS.sum_x_km, tS.sum_n_km, tS.sum_p_km, tS.sum_a_km
    ORDER BY Agg_ID ) 
; 


------------------------
-- tests
------------------------
SELECT * 
FROM osm.berlin_network 
WHERE ST_isvalid(shape) = FALSE

SELECT * 
FROM urmo.plr
WHERE ST_isvalid(the_geom) = FALSE


--  ___________________________
--  ___________________________

SELECT  
		Agg_Area.schluessel AS Agg_ID,
		SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000 AS sum_G_km
		
      ((SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000)/(st_area(Agg_Area.geom)/1000000)) as density
        

	FROM planungsraum_mitte AS  Agg_Area LEFT JOIN strassennetzb_rbs_od_blk_2015_mitte As Ex_Obj
            ON ST_INTERSECTS(Agg_Area.geom, Ex_Obj.geom)
            
    GROUP BY Agg_ID, Agg_Area.geom
    ORDER BY Agg_ID, density DESC; 
		

SELECT 
      row_number() over (order by 1) as GID,
      Agg_Area.schluessel AS Agg_ID,
      count(Ex_Obj.geom) AS totale,
      st_area(Agg_Area.geom)/1000000 AS AggregationArea_km2,
      SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000 as length_total_km2,
      SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom))) AS Frac_,
	

      ((SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000)/(st_area(Agg_Area.geom)/1000000)) as density
        

	FROM planungsraum_mitte AS  Agg_Area LEFT JOIN strassennetzb_rbs_od_blk_2015_mitte As Ex_Obj
            ON ST_INTERSECTS(Agg_Area.geom, Ex_Obj.geom)
            
    GROUP BY Agg_ID, Agg_Area.geom
    ORDER BY Agg_ID, density DESC; 
    



  "DROP TABLE IF EXISTS streetLines;
  SELECT * INTO streetLines FROM(
    SELECT 
      row_number() over (order by 1) as GID,
      Agg_Area.schluessel AS Agg_ID,
      count(Ex_Obj.geom) AS totale,
      st_area(Agg_Area.geom)/1000000 AS AggregationArea_km2,
      SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000 as length_total_km2,
      SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom))) AS Frac_,
	

      ((SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000)/(st_area(Agg_Area.geom)/1000000)) as density
        

	FROM planungsraum_mitte AS  Agg_Area LEFT JOIN strassennetzb_rbs_od_blk_2015_mitte As Ex_Obj
            ON ST_INTERSECTS(Agg_Area.geom, Ex_Obj.geom)
            
    GROUP BY Agg_ID, Agg_Area.geom
    ORDER BY Agg_ID, density DESC; 
    
    ) as foo;
    
  ALTER TABLE streetLines ADD PRIMARY KEY(GID);
  
  SELECT * FROM streetLines"


-----------
SELECT *
FROM strassennetzb_rbs_od_blk_2015_mitte
LIMIT 20;

SELECT *
FROM planungsraum_mitte
ORDER BY schluessel
LIMIT 20;

SELECT DISTINCT strklasse
FROM strassennetzb_rbs_od_blk_2015_mitte
;



--- testing the subselect table 'temp_calc'  - WORKING as intended -- here summary of G over the first 5 PLRs = 29,9, same as summation of G form the above table :)
SELECT sum(ST_Length(ST_INTERSECTION(Agg_Area.geom, Ex_Obj.geom)))/1000, strklasse
FROM strassennetzb_rbs_od_blk_2015_mitte As Ex_Obj LEFT JOIN planungsraum_mitte AS  Agg_Area
            ON ST_INTERSECTS(Ex_Obj.geom, Agg_Area.geom)
WHERE schluessel IN ('01011101', '01011102', '01011103', '01011104', '01011105')
GROUP BY strklasse

-- ---------------------------------------------------------------------------------------------------------------------
--   "DROP TABLE IF EXISTS %s;
--   SELECT * INTO %s FROM(
--     SELECT 
--       row_number() over (order by 1) as GID,
--       Agg_Area.%s AS Agg_ID,
--       %s AS Klasse,
--       st_area(Agg_Area.geom)/1000000 AS AggregationArea_km2,
--       count(Lines.geom) AS totale,
--       SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Lines.geom)))/1000 as sum_length,
--       ((SUM(ST_Length(ST_INTERSECTION(Agg_Area.geom, Lines.geom)))/1000)/(st_area(Agg_Area.geom)/1000000)) as density
--         FROM %s AS  Agg_Area LEFT JOIN %s As Lines
--             ON ST_INTERSECTS(Agg_Area.geom, Lines.geom)
--     GROUP BY Agg_ID, Klasse, Agg_Area.geom
--     ORDER BY Agg_ID, density DESC) as foo;
--     
--   ALTER TABLE %s ADD PRIMARY KEY(GID);
--   
--   SELECT * FROM %s;",

show all;