query builder:

old_ColName: a.bid

copyFromTable_name aka from:  the subselect below:

copy from table id: .aid





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


select  a.tvz_id as aid, b.tvz_id::int as bid
from urmo.tvz as a
JOIN urmo.tvz as b
ON ST_intersects((a.the_geom), b.the_geom)
ORDER BY a.tvz_id;



SELECT * INTO public.tvz_test FROM urmo.tvz;