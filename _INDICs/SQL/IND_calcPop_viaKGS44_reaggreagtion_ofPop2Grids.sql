
--------------
---- Query for reaggregation of population from blocks to gridcells
--------------

With hhPerBlk AS (
	SELECT
		p.blk_id,
		sum(hh) AS hhPerBlk
	FROM urmo.kgs44 k
		JOIN urmo.pop_blk p
			ON ST_Within(k.the_geom, p.the_geom)
	GROUP by p.blk_id
	ORDER BY sum(hh) DESC),

popPerHh AS (
	SELECT 
		p.pop_tot / h.hhPerBlk AS popPerHh,
		p.blk_id AS BLK_ID
		FROM urmo.pop_blk AS p
		LEFT JOIN hhPerBlk as h
		ON p.blk_id = h.blk_id
		WHERE h.hhPerBlk >0
		GROUP BY p.blk_id, p.pop_tot, h.hhPerBlk),

res as (SELECT 
	sum(k.hh*popPerHh) as res,
	g.gid
	FROM grids.hex_2000 g
		JOIN urmo.kgs44 k
			ON ST_Within(k.the_geom, g.the_geom)
		LEFT JOIN urmo.pop_blk p 
			ON ST_Within (k.the_geom, p.the_geom)
		LEFT JOIN popPerHh as pop
			ON p.blk_ID = pop.BLK_ID
	GROUP BY g.gid
	ORDER BY sum(k.hh*popPerHh) DESC)

	select sum(res)
	from res
--------------------------------------------------------------------------------------------------------		
--------------------------------------------------------------------------------------------------------

With hhPerBlk AS (
	SELECT
		p.blk_id,
		sum(coalesce(hh, 0)) AS hhPerBlk
	FROM urmo.kgs44 k
		JOIN urmo.pop_blk p
			ON ST_Within(k.the_geom, p.the_geom)
	GROUP by p.blk_id
	ORDER BY sum(coalesce(hh, 0)) DESC),

popPerHh AS (
	SELECT 
		p.pop_tot / h.hhPerBlk AS popPerHh,
		p.blk_id AS BLK_ID
		FROM urmo.pop_blk AS p
		LEFT JOIN hhPerBlk as h
		ON p.blk_id = h.blk_id
		WHERE h.hhPerBlk >0
		GROUP BY p.blk_id, p.pop_tot, h.hhPerBlk)

SELECT 
	count(coalesce(k.hh, 0)),
	g.gid
	FROM grids.hex_2000 g
		JOIN urmo.kgs44 k
			ON ST_Within(k.the_geom, g.the_geom)
		LEFT JOIN urmo.pop_blk p 
			ON ST_Within (k.the_geom, p.the_geom)
		LEFT JOIN popPerHh as pop
			ON p.blk_ID = pop.BLK_ID
	GROUP BY g.gid
	ORDER BY count(k.hh) DESC
	
--------------------------------------------------------------------------------------------------------		
--------------------------------------------------------------------------------------------------------


With hhPerBlk AS (
	SELECT
		p.blk_id,
		sum(coalesce(hh, 0)) AS hhPerBlk
	FROM urmo.kgs44 k
		JOIN urmo.pop_blk p
			ON ST_Within(k.the_geom, p.the_geom)
	GROUP by p.blk_id
	ORDER BY sum(hh) DESC),

popPerHh AS (
	SELECT 
		p.pop_tot / h.hhPerBlk AS popPerHh,
		p.blk_id AS BLK_ID
		FROM urmo.pop_blk AS p
		LEFT JOIN hhPerBlk as h
		ON p.blk_id = h.blk_id
		WHERE h.hhPerBlk >0
		GROUP BY p.blk_id, p.pop_tot, h.hhPerBlk),

res AS (
	SELECT 
	sum(popPerHh) AS res,
	g.gid
	FROM grids.hex_2000 g
		JOIN urmo.kgs44 k
			ON ST_Within(k.the_geom, g.the_geom)
		LEFT JOIN urmo.pop_blk p 
			ON ST_Within (k.the_geom, p.the_geom)
		LEFT JOIN popPerHh as pop
			ON p.blk_ID = pop.BLK_ID
	GROUP BY g.gid
	ORDER BY sum(popPerHh) DESC)

SELECT AVG(res)
FROM res
--------------------------------------------------------------------------------------------------------		
--------------------------------------------------------------------------------------------------------

SElecT 
	ID,
	popPerHh
	FROM popPerHh







WITH pop_hh AS      -- which plr is each household located in?
(
  SELECT 	
	p.blk_id, 
	(p.pop_tot/( SELECT sum(k.hh) 
		FROM urmo.kgs44 AS k JOIN urmo.pop_blk AS p ON ST_Within(k.the_geom, p.the_geom) GROUP BY p.blk_id) ) As PopPerHh,
	k.kgs44_id
	FROM urmo.kgs44 k 
		LEFT JOIN urmo.pop_blk p 
			ON ST_Within(k.the_geom, p.the_geom)
		WHERE k.hh > 0

	GROUP BY p.blk_id, p.pop_tot, k.kgs44_id
	ORDER BY p.blk_id 

)
  SELECT 
	sum(DISTINCT(p.PopPerHh)),
	s.gid
		FROM urmo.kgs44 k 
		JOIN grids.hex_2000 s 
		ON ST_Within(k.the_geom, s.the_geom)
		LEFT JOIN pop_hh as p 
		ON(k.kgs44_id = p.kgs44_id)
	GROUP BY s.gid







)
SELECT 
	hh_G.gid,
	pop.PopPerHh
		FROM grids.hex_2000 s
		pop_hh AS pop
		join hh_Grid AS hh_G
		ON (pop.kgs44_id = hh_G.kgs44_id)
GROUP BY hh_G.gid, pop.PopPerHh
ORDER BY hh_G.gid