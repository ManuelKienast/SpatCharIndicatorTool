---- the whole co-co-co-combo
WITH startingTrips AS(
        SELECT
          interval_begin AS time,
          sum(COALESCE(edge_departed,0)) AS trips_d,
          gid,
          geom_grid
            FROM sumotraffic_fish_4000_intersect
        GROUP BY  interval_begin,
                  gid,
                  geom_grid),
    
      enteringTrips AS(
        SELECT
          a.interval_begin As time,
          sum(COALESCE(a.edge_entered,0)) AS trips_e,
          a.gid
            FROM sumotraffic_fish_4000_intersect a
              LEFT JOIN sumotraffic_fish_4000_intersect b
                ON a.edge_from = b.edge_to
            WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
        GROUP BY 
                a.interval_begin,
                a.gid)
    
    SELECT
      (a.time || 'second')::interval AS time,
      a.gid,
      a.trips_d,
      b.trips_e,
      COALESCE(a.trips_d,0)+COALESCE(b.trips_e,0) as total,
      a.geom_grid
        FROM startingTrips a
          LEFT JOIN enteringTrips b
            ON CONCAT(a.time,a.gid) = CONCAT(b.time,b.gid)
      ORDER BY a.time
    



--- On JOIN clause test
select CONCAT(interval_begin, key)
FROM sumotraffic_fish_4000_intersect;

-- EnteringTrips : also seems to compute fine
SELECT
          a.interval_begin As time,
          sum(a.edge_entered) AS trips_e,
          a.gid
            FROM sumotraffic_fish_4000_intersect a
              LEFT JOIN sumotraffic_fish_4000_intersect b
                ON a.edge_from = b.edge_to
            WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
        GROUP BY 
                a.interval_begin,
                a.gid
        ORDER BY a.interval_begin,
                a.gid



--- STarting Trips : computes fine
SELECT
          interval_begin AS time,
          sum(edge_departed) AS trips_d,
          gid,
          geom_grid
            FROM sumotraffic_fish_4000_intersect
        GROUP BY  interval_begin,
                  gid,
                  geom_grid