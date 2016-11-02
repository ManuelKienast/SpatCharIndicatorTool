SELECT *
FROM test_aggregated
limit 100;

--- presentation of trip travel time intervals
SELECT DISTINCT interval_begin, AVG(interval_end), (AVG(interval_end)-interval_begin) As delta_t
FROM test_aggregated
GROUP BY interval_begin
Order BY interval_begin;

--- count of trips per interval, following an expected daily distribution, plateu from 11:30 to 16:00 peak near 14:00
SELECT DISTINCT interval_begin, COUNT(gid)
FROM test_aggregated
GROUP BY interval_begin
Order BY interval_begin;

--- test for uniqueness of edge_id: definetly NOT, but could be a measuere of the intensity of travel per edge_id
SELECT edge_id, COUNT(*)
FROM test_aggregated
GROUP BY edge_id
HAVING COUNT(*) > 1

--- but testing for its uniqueness order by time intervals reveals uniquness!
SELECT interval_begin, edge_id, COUNT(*)
FROM test_aggregated
GROUP BY interval_begin, edge_id
HAVING COUNT(*) > 1

--- checking for differences btwn edge_sampleseconds and edge_travel_time --> whatever, nothing conclusive, just generally they are not equal; 350k rows are; -> random
SELECT edge_sampledseconds, edge_traveltime
FROM test_aggregated
WHERE edge_sampledseconds = edge_traveltime

--- check edge_density
SELECT DISTINCT edge_density, edge_occupancy
FROM test_aggregated
Order BY edge_density desc;

--- cross check with test_Edge (geom) data with no geom column, ie.e edge_id -53424914
select *
FROM test_edg
LIMIT 1

select *
FROM test_edg
where edge_shape IS NULL
LIMIT 10

select *
FROM test_aggregated
where edge_id IN (
'-53499553',
'-53499554',
'-53499555',
'-53499562',
'-53499563',
'-53499567',
'-53499568',
'-53499570',
'-53499572',
'-53499573',
'-53424914')

--- check the nodes, there are conflicts in the node_id col
select *
from test_nod
limit 1

select *
from test_nod
where node_id LIKE '%e' OR node_id LIKE '%.%'

select DISTINCT node_Type
from test_nod

--- Join the whole thing ..
SELECT a.interval_begin, a.edge_arrived, a.edge_departed, a.edge_entered, a.edge_left, e.edge_id, n.node_id, n.geom
FROM test_Aggregated AS a
LEFT JOIN test_edg AS e
	ON (a.edge_id = e.edge_id)
LEFT JOIN test_nod As n
	ON(e.edge_to = n.node_id)