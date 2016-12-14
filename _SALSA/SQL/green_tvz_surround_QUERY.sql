
--
-- Query for adding and calculating the Col green_tvz_surround to the rent table
-- followed by general experimentation and build up of the query
-- 
--- writing the query to update existing table sppachr_green_tvz
ALTER TABLE spchar_green_tvz ADD COLUMN green_tvz_surround NUMERIC;
WITH green_tvz AS (
select  a.tvz_id as aid, avg(b.green) as bid
from spchar_green_tvz as a
JOIN spchar_green_tvz as b
ON ST_intersects((a.geom), b.geom)
GROUP bY a.tvz_id
ORDER BY a.tvz_id)
UPDATE spchar_green_tvz set green_tvz_surround = bid FROM green_tvz AS g WHERE tvz_id = g.aid;



-- testing for difference in touches and intersects
select  a.tvz_id as aid, avg(b.tvz_id::int) as bid, foo.cid
from urmo.tvz as a
JOIN urmo.tvz as b
ON ST_touches((a.the_geom), b.the_geom)
join (
	select a.tvz_id as aid, avg(b.tvz_id::int) as cid
		from urmo.tvz as a
			JOIN urmo.tvz as b
				ON ST_intersects((a.the_geom), b.the_geom)
			group by a.tvz_id
			order by a.tvz_id) as foo
	ON (a.tvz_id = foo.aid)
group by a.tvz_id, foo.cid
order by a.tvz_id



select  a.tvz_id as aid, avg(b.tvz_id::int) as bid
from urmo.tvz as a
JOIN urmo.tvz as b
ON ST_intersects((a.the_geom), b.the_geom)
GROUP BY a.tvz_id
ORDER BY a.tvz_id;

ALTER TABLE spchar_green_tvz ALTER COLUMN geom TYPE geometry(MultiPolygon, 25833) USING ST_SetSRID(geom, 25833);

select  a.tvz_id as aid, b.tvz_id::int as bid
from spchar_green_tvz as a
JOIN spchar_green_tvz as b
ON ST_intersects((a.geom), b.geom)
ORDER BY a.tvz_id;

select  a.tvz_id as aid, avg(b.green) as bid
from spchar_green_tvz as a
JOIN spchar_green_tvz as b
ON ST_intersects((a.geom), b.geom)
GROUP bY a.tvz_id
ORDER BY a.tvz_id;



--- same for rent_blaaa writing the query to update existing table sppachr_green_tvz
ALTER TABLE spchar_green_tvz ADD COLUMN green_tvz_surround NUMERIC;
WITH green_tvz AS (
select  a.tvz_id as aid, avg(b.green) as bid
from spchar_green_tvz as a
JOIN spchar_green_tvz as b
ON ST_intersects((a.geom), b.geom)
GROUP bY a.tvz_id
ORDER BY a.tvz_id)
UPDATE spchar_green_tvz set green_tvz_surround = bid FROM green_tvz AS g WHERE tvz_id = g.aid;

SELECT * INTO public.tvz_test FROM urmo.tvz;