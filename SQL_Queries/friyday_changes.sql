

    DROP TABLE IF EXISTS public.sumo_Inters_test1000;
    
    SELECT * INTO public.sumo_Inters_test1000 FROM
    (
    SELECT 
    row_number() over (order by 1) as key,
    ci.interval_begin,
    ci.edge_arrived,
    ci.edge_departed,
    ci.edge_entered,
    ci.edge_left,
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.geom as geom_point,
    r.the_geom as geom_grid,
    r.gid
    FROM public.compiledimport AS ci 
    JOIN %s.%s AS r 
    ON ST_Within(ci.geom, r.the_geom) 
    
    GROUP BY 
    ci.interval_begin,
    ci.edge_arrived,
    ci.edge_departed,
    ci.edge_entered,
    ci.edge_left,
    ci.edge_id,
    ci.edge_to,
    ci.edge_from,
    ci.geom,
    r.the_geom,
    r.gid
    
    ) as foo;
    

    DROP INDEX IF EXISTS sumo_Inters_gix;
    CREATE INDEX sumo_Inters_gix 
        ON public.sumo_Inters
        USING GIST (geom_point);



  DROP TABLE IF EXISTS public.sumo_test;
  SELECT * INTO public.sumo_test FROM (
  
  With Groupie AS (

  SELECT 
    sum(edge_arrived) as arr,
    sum(edge_departed) as dep,
    sum(edge_entered) as entr,
    sum(edge_left) lef,
    edge_from,
    gid
	FROM public.sumo_Inters_test1000
    GROUP BY 
    gid,
    edge_from
    )


    
  SELECT 
    row_number() over (order by 1) as key,
    a.gid,
    sum(a.edge_entered) ent,
    sum(a.edge_departed) dep,
    sum(a.edge_entered)+sum(a.edge_departed) total
    
      FROM public.sumo_Inters_test1000 as a 
	      LEFT JOIN public.sumo_Inters_test1000 as b
		      ON (a.edge_from = b.edge_to)
    WHERE a.gid != b.gid
    GROUP BY a.gid
    ORDER BY total desc
    ) as foo
    ;
    
    ALTER TABLE public.%s ADD PRIMARY KEY (key);


select total 
from sumo_test
order by total desc