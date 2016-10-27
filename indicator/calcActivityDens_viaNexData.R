# Calcs from SQL-Script: "calculate_activity_density_per_plr_from_pos.sql"
# calculate density of various acitivities per PLR from POS data
# including aggregation from POS locations to PLR
# runtime: 9060 ms -> ca. 9 s

  

### create Vektor with ColNames

vColNames <- c(shop_dens, shop_dens_pop, daily_dens, daily_dens_pop, rest_dens, rest_dens_pop, 
               school_dens, school_dens_pop, health_dens, health_dens_pop, fun_dens, fun_dens_pop)


### Write Cols of resutl table with the names from vColNames

updateResultTable <- function(con, vColNames, result_table_name)

  {
  newColNames <- dbGetQuery(con, sprintf( 
    
    "ALTER TABLE %s DROP COLUMN IF EXISTS %s;
    ALTER TABLE %s ADD COLUMN %s FLOAT;
    "
    ,
    result_table_name, vektorColNames,
    result_table_name, vektorColNames
    
  ))
  return(newColNames)
}

### Insert Function updating the results table with the calculated data
  
insertActivityDens2table <- function(con, vektorColNames,
                            result_table_schema, result_table_name, agg_id, result_table_geom,
                            ex_table1_schema, ex_table1, ex_table1_id, ex_table1_geom,
                            ex_table2_schema, ex_table2, ex_table2_col,ex_table2_geom)

{
  popPerCell <- dbGetQuery(con, sprintf( 
    
    "UPDATE %s 
    SET %s = foo.%s
    FROM (
    
    With hhPerBlk AS (
    SELECT
    p.%s AS blk_id,
    sum(%s) AS hhPerBlk
    FROM %s.%s k
    JOIN %s.%s p
    ON ST_Within(k.%s, p.%s)
    GROUP by p.blk_id),
    
    popPerHh AS (
    SELECT 
    p.%s / h.hhPerBlk AS popPerHh,
    p.%s AS blk_id
    FROM %s.%s AS p
    LEFT JOIN hhPerBlk as h
    ON p.blk_id = h.blk_id
    WHERE h.hhPerBlk >0
    GROUP BY p.blk_id, p.%s, h.hhPerBlk)
    
    SELECT 
    sum(k.%s*popPerHh) as %s,
    g.%s
    FROM %s.%s g
    JOIN %s.%s k
    ON ST_Within(k.%s, g.%s)
    LEFT JOIN %s.%s p 
    ON ST_Within (k.%s, p.%s)
    LEFT JOIN popPerHh as pop
    ON p.%s = pop.blk_id
    GROUP BY g.%s
    ) as foo
    WHERE %s.%s = foo.%s
    
    ;"
    ,
    result_table_name,                 ## UPDATE
    vektorColNames, vektorColNames,    ## SET 
    ex_table1_id,                      ## SELECT 1 p.
    ex_table2_col,                     ## sum - hh
    ex_table2_schema, ex_table2,       ## FROM k  kgs44
    ex_table1_schema, ex_table1,       ## JOIN  p
    ex_table2_geom, ex_table1_geom,    ## ST_Within (points from kgs in area of population cell aka pop_blk)
    vektorColNames,                    ## SELECT 1 division
    ex_table1_id,                      ## SELECT 1 p.
    ex_table1_schema, ex_table1,       ## FROM  p
    vektorColNames,                    ## GROUP BY
    ex_table2_col, vektorColNames,     ## SELECT1 - hh, Colnames
    agg_id,                            ## SELECT2 - g - grid
    result_table_schema,result_table_name,  ## FROM g
    ex_table2_schema, ex_table2,       ## JOIN k  kgs44
    ex_table2_geom, result_table_geom, ## ON ST_Within -1- (points form kgs in area of result geom - grids)
    ex_table1_schema, ex_table1,       ## LEFT JOIN p
    ex_table2_geom, ex_table1_geom,    ## ON ST_Within -2- (points form kgs in area of population cell aka pop_blk)
    ex_table1_id,                      ## ON -3- p.
    agg_id,                            ## GROUP BY
    result_table_name, agg_id, agg_id  ## WHERE
    
  ))

  return(popPerCell)
  
}
  
  WITH shops AS 
(
SELECT p.plr_id, COUNT(s.*) shops 
FROM urmo.pos s 
JOIN urmo.plr p ON ST_Within(s.the_geom, p.the_geom) 
JOIN urmo.wz w ON w.wz_id = s.wz_id 
WHERE w.wz_abt = '47' 
GROUP BY p.plr_id 
ORDER BY p.plr_id
), daily AS 
(
SELECT p.plr_id, COUNT(s.*) daily 
FROM urmo.pos s 
JOIN urmo.plr p ON ST_Within(s.the_geom, p.the_geom) 
JOIN urmo.wz w ON w.wz_id = s.wz_id 
WHERE w.wz_kla IN ('47.11', '47.81') OR w.wz_gru = '47.2' 
GROUP BY p.plr_id 
ORDER BY p.plr_id
), restaurants AS 
(
SELECT p.plr_id, COUNT(s.*) restaurants 
FROM urmo.pos s 
JOIN urmo.plr p ON ST_Within(s.the_geom, p.the_geom) 
JOIN urmo.wz w ON w.wz_id = s.wz_id 
WHERE w.wz_abt = '56' 
GROUP BY p.plr_id 
ORDER BY p.plr_id
), schools AS 
(
SELECT p.plr_id, COUNT(s.*) schools 
FROM urmo.pos s 
JOIN urmo.plr p ON ST_Within(s.the_geom, p.the_geom) 
JOIN urmo.wz w ON w.wz_id = s.wz_id 
WHERE w.wz_gru IN ('85.1' , '85.2', '85.3', '85.4') 
GROUP BY p.plr_id 
ORDER BY p.plr_id
), health AS 
(
SELECT p.plr_id, COUNT(s.*) health 
FROM urmo.pos s 
JOIN urmo.plr p ON ST_Within(s.the_geom, p.the_geom) 
JOIN urmo.wz w ON w.wz_id = s.wz_id 
WHERE w.wz_abt = '86' OR w.wz_kla IN ('47.73', '47.74') 
GROUP BY p.plr_id 
ORDER BY p.plr_id
), fun AS 
(
SELECT p.plr_id, COUNT(s.*) fun 
FROM urmo.pos s 
JOIN urmo.plr p ON ST_Within(s.the_geom, p.the_geom) 
JOIN urmo.wz w ON w.wz_id = s.wz_id 
WHERE w.wz_abt IN ('90', '91', '92', '93') 
GROUP BY p.plr_id 
ORDER BY p.plr_id
) 
SELECT p.plr_id, 
--s.shops, 
s.shops / (ST_Area(p.the_geom) / 1000000) shop_dens, 
s.shops / (o.pop_tot / 1000) shop_dens_pop, 
--d.daily, 
d.daily / (ST_Area(p.the_geom) / 1000000) daily_dens, 
d.daily / (o.pop_tot / 1000) daily_dens_pop, 
--r.restaurants rest, 
r.restaurants / (ST_Area(p.the_geom) / 1000000) rest_dens, 
r.restaurants / (o.pop_tot / 1000) rest_dens_pop, 
--c.schools, 
c.schools / (ST_Area(p.the_geom) / 1000000) school_dens, 
c.schools / (o.pop_tot / 1000) school_dens_pop, 
--h.health, 
h.health / (ST_Area(p.the_geom) / 1000000) health_dens, 
h.health / (o.pop_tot / 1000) health_dens_pop, 
--f.fun, 
f.fun / (ST_Area(p.the_geom) / 1000000) fun_dens, 
f.fun / (o.pop_tot / 1000) fun_dens_pop 
FROM urmo.plr p 
LEFT JOIN urmo.pop_plr o ON o.plr_id = p.plr_id 
LEFT JOIN shops s ON s.plr_id = p.plr_id 
LEFT JOIN daily d ON d.plr_id = p.plr_id 
LEFT JOIN restaurants r on r.plr_id = p.plr_id 
LEFT JOIN schools c on c.plr_id = p.plr_id 
LEFT JOIN health h on h.plr_id = p.plr_id 
LEFT JOIN fun f on f.plr_id = p.plr_id 