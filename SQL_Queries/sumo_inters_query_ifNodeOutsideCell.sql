select gid, sum(edge_entred) ent, sum(edge_departed) dep, sum(edge_entred)+sum(edge_departed) total
from sumo_inters_groupgeom
where gid != SELECT ()
group by gid
order by gid

select *
from sumo_inters_groupgeom
limit 1
