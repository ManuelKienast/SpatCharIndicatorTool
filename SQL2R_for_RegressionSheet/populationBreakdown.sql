WITH pop_hh AS      -- which plr is each household located in?
(
  SELECT 	p.blk_id, 
  p.pop_tot/sum(k.hh) As PopPerHh,
  k.kgs44_id
  FROM urmo.pop_blk p 
  JOIN urmo.kgs44 k ON ST_Within(k.the_geom, p.the_geom)
  WHERE k.hh > 0
  GROUP BY p.blk_id, p.pop_tot, k.kgs44_id
),

hh_Grid AS             -- which Aggregation cell (GridCell) is each household located in?
(
  SELECT s.gid, k.kgs44_id, k.hh
  FROM urmo.kgs44 k 
  JOIN grids.hex_2000 s ON ST_Within(k.the_geom, s.the_geom)
  GROUP BY s.gid, k.kgs44_id, k.hh
)
SELECT 
hh_G.gid,
sum(pop.PopPerHh)	
FROM pop_hh AS pop
join hh_Grid AS hh_G
ON (pop.kgs44_id = hh_G.kgs44_id)
GROUP BY hh_G.gid
ORDER BY hh_G.gid