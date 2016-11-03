  
    SELECT * INTO public.sumo_Inters_groupGeom FROM
    (
    SELECT 
    
    sum(ci.edge_arrived) as arr,
    sum(ci.edge_departed) as dep,
    sum(ci.edge_entered) as entr,
    sum(ci.edge_left) lef,
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.geom,
    ci.gid
    FROM public.sumo_Inters as ci
        
    GROUP BY 
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.geom,
    ci.gid) as foo;