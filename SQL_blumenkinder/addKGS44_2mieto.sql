
-- SQL script containing the solution to updating the rentbln11 table
-- 1) adding KGS44 houshold data by spatial (nearest neighbour) joining to the rent table
-- 2) inserting different income data form tvz_data_num to the table (this operation is also solved in R)

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

-- ALl in One

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


--- Same as above but split in two parts: 1) creation of a values table 2) copying from that into the rent-table.
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




------------ PLAYGROUND   --------------------------------------------
---- test for distance between the nearest neighbours
drop table rentbln_dist_test;
SELECT * INTO rentbln_dist_test FROM (
WITH IDTABLE AS (        ---- idtable creates the relation btwn the id of rentobject and its spatially closest kgs44 counter-part, basically the link btwn both tables
		SELECT
			r.id,
			(SELECT  ---- this select returns the k.gid of the point (k.the_geom) in closest proximity (limit1) to the point defined by r.geom
				k.gid
			FROM urmo.kgs44 AS k
			ORDER BY r.geom <#> k.the_geom
			LIMIT 1)
		FROM rentbln11 r)
	SELECT 
		r.id, k.gid, st_distance(r.geom, k.the_geom) as dist, r.geom
		FROM rentbln11 as r
			LEFT JOIN idtable AS id
				ON (r.id = id.id)
			LEFT JOIN urmo.kgs44 as k
				ON (id.gid = k.gid)
						)as foo;


---- write the table containing only values where distance btwn geoms is <18m
drop table rentbln_18m;
SELECT * INTO rentbln_18m FROM (
WITH IDTABLE AS (        ---- idtable creates the relation btwn the id of rentobject and its spatially closest kgs44 counter-part, basically the link btwn both tables
		SELECT
			r.id,
			(SELECT  ---- this select returns the k.gid of the point (k.the_geom) in closest proximity (limit1) to the point defined by r.geom
				k.gid
			FROM urmo.kgs44 AS k
			ORDER BY r.geom <#> k.the_geom
			LIMIT 1)
		FROM rentbln11 r)
	SELECT 
		st_distance(r.geom, k.the_geom) as dist, r.*
		FROM rentbln11 as r
			LEFT JOIN idtable AS id
				ON (r.id = id.id)
			LEFT JOIN urmo.kgs44 as k
				ON (id.gid = k.gid)
		WHERE st_distance(r.geom, k.the_geom) < 18
				)as foo;


select *
from rentbln_18m
where dist > 18
order by dist desc;


select * from rentbln_18m limit 1
---------------------
--------------
---- Test for returning/consecutive postings identified by laufzeitta and einstellda and the same qmmiete and etage
-- query for einstellda and sameness
select qmmiete, einstellda, laufzeitta, einstellda + laufzeitta::integer as expectedNewEinst
from rentbln11
where qmmiete::text LIKE ('16.9014%')
ORDER BY einstellda


-- transfer this to a self join where dates are same, i.e. a.einstellda = b.einstellda+laufzeit AND qmmiete AND etage; select gid, resutl should list all the consecutively listed objects
-- 22633 rows returned.
select a.id, b.id, a.strasse, b.strasse, a.qmmiete, b.qmmiete, a.etage, b.etage, a.mietekalt, b.mietekalt, a.einstellda, b.einstellda+b.laufzeitta::integer, a.laufzeitta
FROM rentbln_18m as a
	JOIN rentbln_18m as b
		ON a.einstellda = (b.einstellda + b.laufzeitta::integer)
		WHERE a.qmmiete = b.qmmiete AND a.etage = b.etage AND a.strasse = b.strasse AND a.mietekalt = b.mietekalt
ORDER by a.id

* INTO rentbln_18m_dl
-- select only those values into the new table WHERE id IS NOT = b.id, i.e. with "double listings" (_dl) removed
SELECT * FROM (
WITH IDdoubleListing AS (        
		select 
			a.id as aid, b.id as bid, a.strasse, b.strasse, a.qmmiete, b.qmmiete, a.etage, b.etage, a.mietekalt, b.mietekalt, a.einstellda, b.einstellda+b.laufzeitta::integer, a.laufzeitta
		FROM rentbln_18m as a
			JOIN rentbln_18m as b
				ON a.einstellda = (b.einstellda + b.laufzeitta::integer)
		WHERE a.qmmiete = b.qmmiete AND a.etage = b.etage AND a.strasse = b.strasse AND a.mietekalt = b.mietekalt)
	SELECT 
		r.*
		FROM rentbln_18m as r
			LEFT JOIN iddoublelisting AS id
				ON (r.id = id.aid)

		order by r.id
				)as foo;

WHERE id.bid IS NULL

-- --- test
-- ----- check the same as above BUT inside a date range of +2 -2 of einstell date and connect on strasse
-- -- no idea how to get it to run
-- select a.id, b.id, a.strasse, b.strasse, a.qmmiete, b.qmmiete, a.etage, b.etage, a.mietekalt, b.mietekalt, a.einstellda, b.einstellda+b.laufzeitta::integer
-- FROM rentbln11 as a
-- 	JOIN rentbln11 as b
-- 		ON a.strasse = b.strasse 
-- 		WHERE a.qmmiete = b.qmmiete 
-- 		AND a.etage = b.etage 
-- 		AND a.mietekalt = b.mietekalt 
-- 		AND a.einstellda::timestamp <@ '[((b.einstellda+(b.laufzeitta-2))::timestamp), ((b.einstellda+(b.laufzeitta+2))::timestamp)]'::tsrange
-- ORDER by a.id



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



