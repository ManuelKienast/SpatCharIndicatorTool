select *
from compiledimport
limit 1

select sum(edge_arrived) as e_arriv, sum(edge_departed) as e_depar, sum(edge_entered) as e_enter, sum(edge_left) as e_left, node_id
from compiledimport
group BY node_id;

----
select distinct interval_begin
from compiledimport
order by interval_begin

--- 135000 - aggregate to node_id in a specific time interval; showing the sums of traffic entering that node
select count(node_id), node_id, sum(edge_entered) ent, sum(edge_left) lef, sum(edge_departed) dep, sum(edge_arrived) arr
from compiledimport
where interval_begin = '135000'
group by node_id
HAVING count(node_id) > 1

--- check for 135000 if edge_ids are occuring multiple times, if yes it shows that traffic is presented as going in both directions btwn two nodes; if no; traffic direction btwn nodes is undetermined
--- edge_ids are unique in each time frame
select count(edge_id)
from compiledimport
where interval_begin in ( '135000', '136800')
group by edge_id
having count(edge_id) > 1

--- check if there are two edge_ids for a connection btwn two nodes
--- NOO, there are not
select *
from test_edg
where edge_from LIKE 'cluster%'
limit 10

select *
from test_edg
where edge_to = 'cluster_60958198_60958201_60958245' OR edge_from = 'cluster_60958198_60958201_60958245'

select *
from compiledimport
where node_id = 'cluster_60958198_60958201_60958245' AND interval_begin = '135000'

-- the same edge_ids are kept through all the time intervalls
select *
from test_aggregated
where edge_id IN ('-53478141','53595044','77171143')

-- check if edge_id + and - present the reverse direction fo the same node connection
-- it is not the case
select *
from test_Aggregated
where edge_id = '-53478141'

-- check how the reverse direction is labeled  --> "cluster_60958198_60958201_60958245" is the endpoint; what is the edge id of its starting point?
select *
from compiledimport
where edge_id = '-53478141'
order by interval_begin

select *
from test_edg
where edge_from = 'cluster_60958198_60958201_60958245' OR edge_to = 'cluster_60958198_60958201_60958245'
-- name of edge starting from that point: ""-53478339""-53595042""-842231370""53478310"" no resemblance to the other edge_id; it is impossible to make predictions based on edge_id

--- how does the information for each direction of the edge look in comparison; same values?? etc
--- such a pair is e.g. edge: THERE ARE NO PAIRS, each edge represents the connection between two nodes as a whole; no back and forth edges.
select * 
from test_edg
where edge_id = '-53478141'

select * 
from test_edg
where edge_to = '60958244' OR edge_from = '60958236' 

select * 
from test_edg
where edge_from = '60958244' OR edge_from = '60958236' OR edge_to = '60958236' OR edge_to = '60958235'


---- Is it problematic to ignore inner cell traffic???  SEEMS so..
select *
from compiledimport
where edge_arrived+edge_departed > 200
order by interval_begin, edge_Arrived desc


---- how do the results from compiledimport look[select * -- 238 s, ~4 min]
select *
from compiledimport

--  688 ms looks shady concerning the 'early' departures start picking up @10:20
select interval_begin, sum(edge_Arrived) arr, sum(edge_departed) dep, sum(edge_entered) ent, sum(edge_left) lef, count(node_id) n_nodes
from compiledimport
group by interval_begin
order by interval_begin

-- totals
select sum(edge_Arrived) arr, sum(edge_departed) dep, sum(edge_entered) ent, sum(edge_left) lef
from compiledimport;

-- larges traffic occuring @144000
select node_id, sum(edge_Arrived) arr, sum(edge_departed) dep, sum(edge_entered) ent, sum(edge_left) lef
from compiledimport
group by node_id
order by ent desc

-- largest delta btwn arrivals and departures, the black hole nodes
select node_id, (sum(edge_Arrived) - sum(edge_departed)) black_holes, sum(edge_Arrived) arr, sum(edge_departed) dep, sum(edge_entered) ent, sum(edge_left) lef
from compiledimport
group by node_id
order by (sum(edge_Arrived) - sum(edge_departed)) desc


---------
--------- Trying to fix the caclulation of traffic per cell
---------
-- total no of trips started = edge departed
select sum(edge_departed)
from test_aggregated;

select sum(edge_departed)
from sumo_Inters_test1000;

select *
from sumo_Inters_test1000
limit 1;

-- testing self intersect
select * 
from sumo_Inters_test1000 a
	JOIN sumo_Inters_test1000 b
		ON a.edge_from = b.edge_to
WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
limit 15

select * 
from sumo_Inters_test1000
where interval_begin = '99000'

--- possibly the correct result:
-- nope or maybe.. 
select sum(b.edge_departed), sum(a.edge_departed)
from sumo_Inters_test1000 a
	JOIN sumo_Inters_test1000 b
		ON a.edge_from = b.edge_to
WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin

-- if this ~ 3.2kk then yes but noooo
select sum(b.edge_departed), sum(a.edge_departed)
from sumo_Inters_test1000 a
	JOIN sumo_Inters_test1000 b
		ON a.edge_from = b.edge_to
WHERE a.gid = b.gid AND a.interval_begin = b.interval_begin

with fromNode as(
	select 
		edge_to,
		gid,
		interval_begin
			from sumo_Inters_test1000)

	select
		sum(edge_departed),
		sum(edge_entered)
			from sumo_Inters_test1000 a
				left JOIN fromNode b
					ON a.edge_from = b.edge_to
		WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin

--- this has to be added to the cars entereing a gridcell, they do when gid != edge_from (gid)

with startingTrips AS(
select sum(edge_departed) trips_d, gid
from sumo_Inters_test1000
group by gid),

enteringTrips AS(
SELECT sum(a.edge_entered) as trips_e,
       a.gid
	FROM sumo_Inters_test1000 a
		left JOIN sumo_Inters_test1000 b
			ON a.edge_from = b.edge_to
		WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
		GROUP BY a.gid)

	SELECT
	a.gid,
	a.trips_d,
	b.trips_e
		
	FROM startingTrips a
		LEFT JOIN enteringTrips b
		ON a.gid = b.gid
	ORDER BY b.trips_e desc



select 