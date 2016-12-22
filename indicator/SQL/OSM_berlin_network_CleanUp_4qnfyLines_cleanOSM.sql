-----------------------------------------
--- ADDing the missing PRIMARY KEY    -check
ALTER TABLE osm.berlin_network
ADD PRIMARY KEY (id);

-----------------------------------------
--- ADDing the missing spacial Index   - check
CREATE INDEX berlin_network_gix
ON osm.berlin_network
USING GIST (shape);

-----------------------------------------
--- replace the dot in osm_type of type highway. & railway.  -check
UPDATE osm.berlin_network
SET osm_type = replace (osm_type, 'highway.', 'hw_')
;

-- SELECT osm_type 
-- FROM osm.berlin_network
-- WHERE osm_type LIKE '%.%';

UPDATE osm.berlin_network
SET osm_type = replace (osm_type, 'railway.', 'rw_')
;

---------------------------------
--- repalce all instances of none in cycleway with n1 to avoid the also present None conflict
--- -check
UPDATE osm.berlin_network
SET cycleway = replace (cycleway, 'none', 'n1')
;

-- SELECT 
-- 	count(cycleway) AS none_lower, 
-- 	(SELECT count(cycleway) AS none_firstCap 
-- 	FROM osm.berlin_network
-- 	WHERE cycleway = 'None' ) as none_firstCap, 
-- 	(SELECT count(cycleway) AS n1
-- 	FROM osm.berlin_network
-- 	WHERE cycleway = 'n1' ) as n1
-- FROM osm.berlin_network 
-- WHERE cycleway = 'none';

---------------------------------
--- build column where cycleway = yes is either IN (hw_cycleway, track ..) OR 
--- other hw_% where cycleway NOT IN (None, n1, no)
--- with select of hw_% to relevant streets
--- -check

ALTER TABLE osm.berlin_network
ADD COLUMN bikeUsage VARCHAR (10);
--
UPDATE osm.berlin_network
SET bikeUsage = 
	CASE 
	WHEN osm_type IN ('hw_cycleway', 'hw_track', 'hw_path') 
	OR cycleway NOT IN ('no', 'None', 'n1') 
	THEN 'yes'
	ELSE 'no'
	END
;

-- --
-- SELECT id, osm_type, cycleway, bikeusage
-- FROM osm.berlin_network
-- WHERE bikeusage = 'yes'
-- ORDER BY id
-- LIMIT 5000
-- ;
-- 
-- 
-- SELECT osm_type, sum(ST_Length(ST_Transform(shape, 25833)))/1000
-- FROM osm.berlin_network
-- WHERE osm_type LIKE 'hw%'
-- GROUP BY osm_type
-- ORDER BY sum(ST_Length(ST_Transform(shape, 25833)))/1000 DESC
-- ;
-- SELECT DISTINCT cycleway
-- FROM osm.berlin_network
-- ;


---------------------------------
--- repalce all instances of ; from cycleway  
-- SADLY doesnt work yet, needs correction via R, where it works
-- UPDATE osm.berlin_network
-- SET cycleway = replace (cycleway, 'track;%', '1')
-- ;
-- 
-- SELECT cycleway 
-- FROM osm.berlin_network
-- WHERE cycleway LIKE '%;%';
-- 
-- SELECT DISTINCT cycleway
-- FROM osm.berlin_network;


-- ---------------------------------
-- --- CHECK FOR invalid Geometries
-- -
-- SELECT *
-- FROM osm.berlin_network
-- WHERE St_IsValid(shape) = FALSE
-- -
-- SELECT *
-- FROM osm.berlin_network
-- WHERE St_IsSimple(shape) = FALSE
-- -
-- SELECT *
-- FROM osm.berlin_network
-- WHERE GeometryType(shape) != 'LINESTRING';
-- 
-- SELECT DISTINCT GeometryType(shape)
-- FROM osm.berlin_network
-- ;
-- 
-- 
-- --- TRY to repair them
-- UPDATE osm.berlin_network
-- SET shape = st_makeValid(shape)
-- WHERE St_isValid(shape) = FALSE;
-- ------------------------------------
