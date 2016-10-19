
--- Create InterSec table holding Linestrings cut to Agg_Area-size tagged with Agg_area_ID
DROP TABLE IF EXISTS InterSec;
SELECT * INTO InterSec FROM (
SELECT 
	Agg_Area.schluessel AS Agg_ID,
	Ex_Obj.strklasse AS LineType,
	--Ex_Obj.vmax AS speed,	
	ST_Multi(ST_Intersection(Agg_Area.geom, Ex_Obj.geom))::geometry(multiLineString, 25833) as geom
	FROM
		planungsraum_mitte AS Agg_Area LEFT JOIN 
		strassennetzb_rbs_od_blk_2015_mitte AS Ex_Obj
		ON (ST_INTERSECTS(Agg_Area.geom, ST_Transform(Ex_Obj.geom, 25833)))
) as foo;

--- Adds a pKey to the table as SERIAL
ALTER TABLE InterSec ADD COLUMN key_column SERIAL PRIMARY KEY;
SELECT * FROM InterSec;

-- Select for creation of the R-vector to loop through for distance calcs
SELECT DISTINCT linetype 
FROM Intersec
WHERE linetype LIKE 'highway%'
;

-- create result table with Agg_Area_Id and its geom to select othe results into
DROP TABLE IF EXISTS result;
SELECT schluessel AS Agg_Id, geom 
INTO result 
FROM planungsraum_mitte AS Agg_Area;
SELECT * FROM RESULT;

-- loop through this using the V(Distinct); calc total length of items listed in vector(Dist) and write to table

ALTER TABLE result ADD COLUMN sum_G FLOAT;

UPDATE result 
SET sum_G = foo.sum_G
FROM (SELECT 
		Agg_ID,
		SUM(ST_Length(geom))/1000 AS sum_G
		FROM InterSec
		WHERE lineType = 'G'
		GROUP BY Agg_ID
		ORDER BY Agg_ID
	) as foo
WHERE result.Agg_ID = foo.Agg_ID
;

-- calc the total length of selected line types

ALTER TABLE result ADD COLUMN sum_length FLOAT;
UPDATE result 
SET sum_length = sum_g  -- summation of all values listed in the V(Dist)
;

--- loop adding the columns for the ratios and then filling them with value(dist)/sum_length


SELECT * FROM result


ORDER BY Agg_ID;