select a.gid, sum(a.entr) ent, sum(a.dep) dep, sum(a.entr)+sum(a.dep) total
from sumo_inters_groupgeom as a 
	LEFT JOIN sumo_inters_groupgeom as b
		ON (a.edge_from = b.edge_to)
where a.gid != b.gid
group by a.gid
order by a.gid




select *
from sumo_inters_groupgeom
limit 1
