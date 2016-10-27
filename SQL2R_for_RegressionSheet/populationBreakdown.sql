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
	),

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
	ORDER BY sum(k.hh*popPerHh) DESC