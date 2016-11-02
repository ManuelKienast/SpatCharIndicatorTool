select *
from compiledimport
limit 1

select sum(edge_arrived) as e_arriv, sum(edge_departed) as e_depar, sum(edge_entered) as e_enter, sum(edge_left) as e_left, node_id
from compiledimport
group BY node_id;