##
## adaptation of calcTrafficTable (from sumo data) to accomodate timeseries resolution
##

##
calcTrafficTable <- function ( connection,
                               resultTable_schema, resultTable_name, resultTable_name_1
)
{
  traffic_per_grid <- dbGetQuery(connection, sprintf(
    
    "DROP TABLE IF EXISTS %s.%s;
    SELECT * INTO %s.%s FROM(

  WITH startingTrips AS(
    SELECT
      interval_begin AS time,
      sum(COALESCE(edge_departed,0)) AS trips_d,
      gid,
      geom_grid
        FROM %s.%s_intersect
    GROUP BY
      interval_begin,
      gid,
      geom_grid),

  enteringTrips AS(
    SELECT
      a.interval_begin As time,
      sum(COALESCE(a.edge_entered,0)) AS trips_e,
      a.gid
        FROM %s.%s_intersect a
          LEFT JOIN %s.%s_intersect b
            ON a.edge_from = b.edge_to
    WHERE a.gid != b.gid AND a.interval_begin = b.interval_begin
    GROUP BY 
      a.interval_begin,
      a.gid)

  SELECT
    row_number() over (order by 1) as key,
    ((a.time || 'second')::interval)::char(9) AS time,
    COALESCE(a.trips_d,0)+COALESCE(b.trips_e,0) as total,
    a.geom_grid
      FROM startingTrips a
        LEFT JOIN enteringTrips b
          ON CONCAT(a.time,a.gid) = CONCAT(b.time,b.gid)
  ORDER BY a.time
    )as foo
    ;"
    ,
    resultTable_schema, resultTable_name,    ### DROP IF
    resultTable_schema, resultTable_name,    ### CREATE TABLE 
    resultTable_schema, resultTable_name_1,    ### FROM - STARTING trips
    resultTable_schema, resultTable_name_1,    ### FROM - ENTERING trips
    resultTable_schema, resultTable_name_1     ### LEFT JOIN - ENTERING trips
    
    
  ))
  
}


calcTrafficTable(con, "public", "a_time_test", "sumotraffic_fish_4000")
