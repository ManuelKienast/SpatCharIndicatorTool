﻿----
---- Third PROBLEM
----
----  Attach all the accessibilites from the corresponding table to the rentTable
-- i.e.	spat_char.accessibilities_tvz12

ALTER TABLE public.rentbln11 DROP COLUMN test_col;
ALTER TABLE public.rentbln11 ADD COLUMN test_col FLOAT;

----
---- SECOND PROBLEM  -- solved & working
----
----  Attach the TVZ based cols: 
-- i.	hh_ek1               inc1
-- ii.	hh_ek2               inc2
-- iii.	hh_ek3               inc3
-- iv.	hh_ek4 + hh_ek5 + hh_ek6      inc4
-- v.	fun_dens
-- 
-- to the rentbln11 table
-- spatial join st_within the mieto points to the tvz layer and attach the above cols via the tvz_id

-- updates the table and adds the necessary columns
ALTER TABLE rentbln11
 ADD COLUMN TVZ_id integer,
 ADD COLUMN inc1 FLOAT,
 ADD COLUMN inc2 FLOAT,
 ADD COLUMN inc3 FLOAT,
 ADD COLUMN inc4 FLOAT,
 ADD COLUMN fun_dens FLOAT;

-- adds the needed pkey to the table
--ALTER TABLE rentbln11 ADD PRIMARY KEY (id);
--ALTER TABLE rentbln11 DROP COLUMN tvz_id;

-- correctly joins the tvz_id to the rentbln11, based on the location of each rentobject inside the tvz12 geometries
UPDATE rentbln11
SET tvz_id = t.no
FROM urmo.tvz12 AS t
where ST_WIthin (rentbln11.geom, t.geom);

-- now inserts the income cols to rentbln11, doing it for each col type:
UPDATE rentbln11
SET inc1 = t.hh_ek1,
	inc2 = t.hh_ek2,
	inc3 = t.hh_ek3,
	inc4 = COALESCE(t.hh_ek4,0)+COALESCE(t.hh_ek5,0)+COALESCE(t.hh_ek6,0),
	fun_dens = t.fun_dens
FROM spat_char.tvz_data_num AS t
where rentbln11.tvz_id = t.tvz_id::integer;




----
---- FIRST PROBLEM -- SOLVED
----
----  The nearest neighbour problem
-- insert KGS44. hh | gc_class | bj_class  into mietobjekte (rentbln11)
--- update mietobjekte mit den drei Objekte s.o.

ALTER TABLE rentbln11
 ADD COLUMN Gbgröße FLOAT,
 ADD COLUMN Gbchar INTEGER,
 ADD COLUMN Bjahr INTEGER,
 ADD PRIMARY KEY (id);

--ALTER  TABLE rentbln11 DROP CONSTRAINT rentbln11_pkey;
--ALTER  TABLE rentbln11 DROP COLUMN baujahr_kgs44;


--- Create table with the mietobject id and the kgs44 values necessary if these values are supposed to be added via the big "building rentTable"-script

CREATE TABLE rentbln11_1 AS
	WITH IDTABLE AS (
		SELECT
			r.id,
			(SELECT
				k.gid
			FROM urmo.kgs44 AS k
			ORDER BY r.geom <#> k.the_geom
			LIMIT 1)
		FROM rentbln11 r)
	SELECT 
		r.id,	
		k.hh AS hh,
		k.gc_class AS gc_class,
		k.bj_class AS bj_class
	FROM rentbln11 AS r
		LEFT JOIN IDTABLE AS i
			ON r.id = i.id
		LEFT JOIN urmo.KGS44 AS k
			ON i.gid = k.gid

ALTER TABLE rentbln11_1	ADD PRIMARY KEY (id);
	
--- Insert the values from temp table into the rentbln11 table
UPDATE rentbln11
	SET 	Gbgröße = t.hh,
		Gbchar = t.gc_class,
		BJahr = t.bj_class
	FROM rntbln11_1 as t
	WHERE rentbln11.id = t.id;
-- done, or all in one below

----
---- Or without writing the additional table:
UPDATE rentbln11
SET Gbgröße = foo.hh,
    Gbchar = foo.gc_class,
    BJahr = foo.bj_class
FROM (
	WITH IDTABLE AS (        ---- idtable creates the relation btwn the id of rentobject and its spatially closest kgs44 counter-part, basically the link btwn both tables
		SELECT
			r.id,
			(SELECT  ---- this select returns the k.gid of the point (k.the_geom) in closest proximity (limit1) to the point defined by r.geom
				k.gid
			FROM urmo.kgs44 AS k
			ORDER BY r.geom <#> k.the_geom
			LIMIT 1)
		FROM rentbln11 r)
	SELECT                   ---- selection of the information to update the cols with and the id to control the update set with
		r.id,	
		k.hh AS hh,
		k.gc_class AS gc_class,
		k.bj_class AS bj_class
	FROM rentbln11 AS r
		LEFT JOIN IDTABLE AS i
			ON r.id = i.id
		LEFT JOIN urmo.KGS44 AS k
			ON i.gid = k.gid) as foo
	WHERE rentbln11.id = foo.id
	;






------------ PLAYGROUND   --------------------------------------------
---- matches the mietobjekte to its closest kgs44 point  -- http://geeohspatial.blogspot.de/2013/05/k-nearest-neighbor-search-in-postgis.html
-- SELECT
-- 	r.id,
-- 	(SELECT
-- 		k.gid
-- 	FROM urmo.kgs44 AS k
-- 	ORDER BY r.geom <#> k.the_geom
-- 	LIMIT 1)
-- FROM rentbln11 r;
-- 
-- -- combining the mietobjects with the KGS44 data from its nearest neigbour
-- 
-- WITH IDTABLE AS (
-- 	SELECT
-- 	r.id,
-- 	(SELECT
-- 		k.gid
-- 	FROM urmo.kgs44 AS k
-- 	ORDER BY r.geom <#> k.the_geom
-- 	LIMIT 1)
-- 	FROM rentbln11 r)
-- 
--   SELECT 
-- 	r.id,
-- 	k.gid,
-- 	k.hh,
-- 	k.gc_class,
-- 	k.bj_class
--     FROM rentbln11 AS r
--       JOIN IDTABLE AS i
-- 	ON r.id = i.id
--       JOIN urmo.KGS44 AS k
--         ON i.gid = k.gid;
-- 
--       urmo.kgs44 AS k
-- 	ON r.id = (SELECT gid
-- 			FROM IDTABLE
-- 			WHERE id = gid)



