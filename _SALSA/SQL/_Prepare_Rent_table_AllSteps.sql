---
--- Cleaning the rentbln dataset, i.e. distance btwn kgs44 and rentobjects too high, relisting of objects in the IS-dataset, implausibilities in the IS-data, e.g. flatsize 0.1 sqm, rent 1*10^9 € etc
--- documentation of changes to the dataset is in the comments
---

-- check for duplicate ids in the rentbln11 dataset
-- none present:
select id, count(id)
from rentbln_18m
group by id 
having count(*) > 1
order by count(id)

-------------------------------------
---------------------------------------------------------
--------
---------  Step 1 - rentbln_18m
--------
---------------------------------------------------------
-------------------------------------
----  write the table containing only values where distance btwn geoms(kgs44 and rent-objects) is <18m
--    writing of new table rentbln_18m
--    drop table rentbln_18m;
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


-- -- yes indeed, no values with dist > 18 m remain
-- select *
-- from rentbln_18m
-- where dist > 18
-- order by dist desc;



-------------------------------------
---------------------------------------------------------
--------
---------  Step 2 - rentbln_18m_dl
--------
---------------------------------------------------------
-------------------------------------
----   INSERT INTO new table only values not considered as immediate relistings.
--     objects are considered a relisting if: an objects listing-date is equal to anothers (listing-date + einstelldauer) AND the qmmiete, etage, strasse & kaltmiete are also equal.
--     the end resultl will als considere an object to be relisted if the einstellda is within +1/-1 days of einstelldauer, eliminating another 5989 rows

----   Test for returning/consecutive postings identified by laufzeitta and einstellda and the same qmmiete and etage
--     query for einstellda and sameness
select qmmiete, einstellda, laufzeitta, einstellda + laufzeitta::integer as expectedNewEinst
	FROM rentbln11
	WHERE qmmiete::text LIKE ('16.9014%')
	ORDER BY einstellda


-- transfer this to a self join where dates are same, i.e. a.einstellda = b.einstellda+laufzeit AND qmmiete AND etage; select gid, resutl should list all the consecutively listed objects
-- 22633 rows returned.
SELECT a.id as aid, b.id as bid, a.strasse, b.strasse, a.qmmiete, b.qmmiete, a.etage, b.etage, a.mietekalt, b.mietekalt, a.einstellda, b.einstellda+b.laufzeitta::integer, a.laufzeitta
FROM rentbln_18m as a
	JOIN rentbln_18m as b
		ON a.einstellda = (b.einstellda + b.laufzeitta::integer)
	WHERE a.qmmiete = b.qmmiete AND a.etage = b.etage AND a.strasse = b.strasse AND a.mietekalt = b.mietekalt
ORDER by a.id


--test this for ranges in btwn +1 -1 day of einstellda
SELECT a.id as aid, b.id as bid, a.strasse, b.strasse, a.qmmiete, b.qmmiete, a.etage, b.etage, a.mietekalt, b.mietekalt, a.einstellda, b.einstellda+b.laufzeitta::integer, a.laufzeitta
FROM rentbln_18m_dl_da as a
	JOIN rentbln_18m as b
		ON a.qmmiete = b.qmmiete
	WHERE  a.einstellda between (b.einstellda + b.laufzeitta::integer-1) AND (b.einstellda + b.laufzeitta::integer+1)
		AND a.etage = b.etage 	
		AND a.strasse = b.strasse 
		AND a.mietekalt = b.mietekalt
ORDER by a.id



-- check for duplicate ids in the subquery above:
-- jep indroduction of 612 duplicates with multiples, those are: 4*6, 44*5, 27*4, 83*3, 454*2 == 897 (the excess after removing one instance of its occurance, i.e. x*(n-1))
WITH idtable as(
SELECT a.id as aid, b.id as bid, a.strasse, b.strasse, a.qmmiete, b.qmmiete, a.etage, b.etage, a.mietekalt, b.mietekalt, a.einstellda, b.einstellda+b.laufzeitta::integer, a.laufzeitta
FROM rentbln_18m as a
	JOIN rentbln_18m as b
		ON a.qmmiete = b.qmmiete
	WHERE  a.einstellda between (b.einstellda + b.laufzeitta::integer-1) AND (b.einstellda + b.laufzeitta::integer+1)
		AND a.etage = b.etage 	
		AND a.strasse = b.strasse 
		AND a.mietekalt = b.mietekalt
ORDER by a.id)
SELECT aid, count(aid)
	FROM idtable
	GROUP BY aid 
	HAVING count(*) > 1
	ORDER BY count(aid) desc

-- this should lead to an easy fix, removing the supicious excess from the dataset, i.e. Subselect aka:
-- and indeed it does:
WITH idtable as(
	SELECT DISTINCT a.id as aid
		FROM rentbln_18m as a
			JOIN rentbln_18m as b
				ON a.qmmiete = b.qmmiete
	WHERE  a.einstellda between (b.einstellda + b.laufzeitta::integer-1) AND (b.einstellda + b.laufzeitta::integer+1)
		AND a.etage = b.etage 	
		AND a.strasse = b.strasse 
		AND a.mietekalt = b.mietekalt
	ORDER by a.id)
SELECT DISTINCT aid, count(aid)
	FROM idtable
	GROUP BY aid 
	HAVING count(*) > 1
	ORDER BY count(aid) desc
	
--
-- remove the values returned in the above query form the dataset and write it as rentbln_18m_dl
-- only those values are inserted into the new table WHERE bid IS NULL, i.e. only values whcih do not have an id suppliled by the IDdoublelisting table
-- returns 86093 rows (fishy) --> implementing the above fix, solved the issue
-- no of rows returned the same, BUT there is no bug present, since the expected value of rows returned as duplicates was estimated too high, see > 1 double listings
-- DROP TABLE IF EXISTS rentbln_18m_dl
SELECT * INTO rentbln_18m_dl FROM (
	WITH IDdoubleListing AS (        
		SELECT DISTINCT
			a.id as aid
		FROM rentbln_18m as a
			JOIN rentbln_18m as b
				ON a.qmmiete = b.qmmiete
	WHERE  a.einstellda between (b.einstellda + b.laufzeitta::integer-1) AND (b.einstellda + b.laufzeitta::integer+1)
		AND COALESCE(a.etage,0) = COALESCE(b.etage, 0) 	
		AND a.strasse = b.strasse 
		AND a.mietekalt = b.mietekalt
ORDER by a.id)
	SELECT 
		r.*
		FROM rentbln_18m as r
			LEFT JOIN iddoublelisting AS id
				ON (r.id = id.aid)
	WHERE r.id NOT IN (SELECT aid FROM IDdoublelisting)
		ORDER BY r.id
		)as foo;

ALTER TABLE rentbln_18m_dl ADD PRIMARY KEY (id);



-------------------------------------
---------------------------------------------------------
--------
---------  Step 3 - rentbln_18m_dl_da
--------
---------------------------------------------------------
-------------------------------------
--   Write the Table containing only rows with laufzeit < 90 and einstellda between 2011-01-01 AND 2011-12-31
--   filter for implausible high/low rents and only consider offers with laufzeitta < 90 days UND 2011 enden!! 
select qmmiete, mietekalt, mietewarm, wohnflaech, einstellda, laufzeitta, einstellda+laufzeitta::int  from rentbln_18m_dl order by qmmiete desc;

--- querying for laufzeit < 90 and einstellda between 2011-01-01 AND 2011-12-31
select einstellda, einstellda+laufzeitta::int, laufzeitta from rentbln_18m_dl 
WHERE laufzeitta < 90 AND einstellda+laufzeitta::int between '2011-01-01'::timestamp AND '2011-12-31'::timestamp
order by einstellda;

--
-- Writing the new rentTable without the 90 days and not 2011 rows AS rentbln_18m_dl_da (da - date corrected)
-- DROP TABLE IF EXISTS rentbln_18m_dl_da;
SELECT * INTO rentbln_18m_dl_da 
	FROM 
		rentbln_18m_dl as r
	WHERE laufzeitta < 90 AND einstellda+laufzeitta::int between '2011-01-01'::timestamp AND '2011-12-31'::timestamp
		;

ALTER TABLE rentbln_18m_dl_da ADD PRIMARY KEY (id);


-------------------------------------
---------------------------------------------------------
--------
---------  Step 4 - rentbln_18m_dl_da_rc
--------
---------------------------------------------------------
-------------------------------------
--  Write the table with corrections for implausible rents and sqm (aka rc - rent corrected)
--  looking at the data  
--  testing: things to filter: wohnflae 10<>1111, qmmiete 0.5<>30, zimmeranzahl/wohnflaech > 2
--  eliminating 59 rows 
--  with 62412 rows remaining
select qmmiete, mietekalt, mietewarm, wohnflaech, etage, strasse, einstellda, laufzeitta, einstellda+laufzeitta::int  
	from rentbln_18m_dl_da 
	WHERE wohnflaech between 10 AND 1111 
		AND qmmiete between 0.5 AND 30
		AND zimmeranza_num/wohnflaech > 2
	order by qmmiete desc, mietekalt, wohnflaech desc, einstellda
	;

--   writing the table rentbln_18m_dl_da_rc
SELECT * INTO rentbln_18m_dl_da_rc 
	FROM 
		rentbln_18m_dl_da as r
	WHERE wohnflaech between 10 AND 1111 
		AND qmmiete between 0.5 AND 30
		AND zimmeranza_num/wohnflaech > 2
		;
ALTER TABLE rentbln_18m_dl_da_rc ADD PRIMARY KEY (id);

--- testing previous iterations
-- looking good, most grievous offenders were filtered during rentbln_18m
SELECT qmmiete, mietekalt, mietewarm, wohnflaech, etage, strasse, einstellda, laufzeitta, einstellda+laufzeitta::int  
	FROM 
	rentbln_18m
	WHERE qmmiete > 30;
SELECT * FROM rentbln_18m_dl_da_rc;
