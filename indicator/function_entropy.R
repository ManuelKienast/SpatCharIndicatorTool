
# built on the (re)classification  indicator, this indicator calculates the SHANNON_ENTROPY_INDEX
# user specifies in the function call by the use of the parameters the criteria for the combination and number of classes built which 
# are then used for the calculation of the index itself
#so the creation of the outputtables of the categorize Index is obligatory, they will be afterwards deleted though
#the function returns a table containing the SHANNON_ENTROPY_INDEX per unit of aggregation



# library(RPostgreSQL)
# library(rgdal)
# 
# 
# #creates connection to the database 
# con <- dbConnect(dbDriver(  "PostgreSQL"),
#                  dbname =   "dlr",
#                  host =     "localhost",
#                  user =     "postgres", 
#                  password = "postgres")
# 
# #lists all tables of chosen database
# dbListTables(con)

#----------------------------PARAMETERS-------------------------------------------------------------------------------------------

#' @param connection : A connection to the PostGIS database. Contained in the variabel 'con'

#' @param tableAggregation: As string - table, which contains the geometry for aggregation 
#'                                      (default schema is "public" , if varies -> "schema.table" )
#' @param AggrField: As string - field, which identifies clearly each unit of aggregation 

#' @param tableCategory: As string - table, which contains the criteria for the reclassification and the associated geometries
#'                                   (default schema is "public", if varies -> "schema.table" instead of "table")

#' @param crit1Field: As string - field, which specifies criterion 1
#' @param crit2Field: As string - field, which specifies criterion 2

#' @param crit1LV1: As int  - lowest value class1 criterion1         
#' @param crit1LV2: As int  - lowest value class2 criterion1 
#' @param crit1LV3: As int  - lowest value class3 criterion1 
#' @param crit2Sep: As int - value that seperates criterion2 into two classes 

#' @param Ncat: As int - number of categories to be formed 


#' @param output1: As string - name of the output table containing the categories 
#'                            (default schema is "public", if varies -> "schema.table" instead of "table")

#' @param output2: As string - name of ouptut table containing a count of the formed categories per unit of aggregation 
#'                            (default schema is "public", if varies -> "schema.table" instead of "table")

#----------------------------SCRIPT------------------------------------------------------------------------------------------

categorize <- function(connection, tableAggregation, AggrField, tableCategory, crit1Field, 
                       crit2Field, crit1LV1, crit1LV2, crit1LV3, crit2Sep, Ncat, output1, output2, output3) {
  
  clear1 <- dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;",output1))
  clear2 <- dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;",output2))
  clear3 <- dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;",output3))
  
  cat <- dbGetQuery(con, sprintf("CREATE TABLE %s(                       
                                 gid serial PRIMARY KEY,
                                 criterion1  varchar,
                                 criterion2 varchar);
                                 
                                 ALTER TABLE %s ADD COLUMN geom geometry (POINT, 25833);        
                                 
                                 INSERT INTO %s (SELECT K.gid AS gid,           
                                 K.%s AS criterion1,                             
                                 K.%s AS criterion2,				                         
                                 K.geom AS geom
                                 FROM %s AS K);                                
                                 
                                 
                                 ALTER TABLE %s ADD COLUMN category varchar;
                                 
                                 UPDATE %s  SET criterion1 = NULL WHERE criterion1 = 'NULL'; 
                                 UPDATE %s SET criterion2 = NULL WHERE criterion2 = 'NULL';    
                                 
                                 ALTER TABLE %s ALTER COLUMN criterion1 type numeric using criterion1::numeric; 
                                 ALTER TABLE %s ALTER COLUMN criterion2 type numeric using criterion2::numeric;
                                 
                                 UPDATE %s                      
                                 SET category =(CASE 
                                 
                                 WHEN (criterion1 IS NULL OR criterion2 IS NULL) THEN NULL             
                                 WHEN (criterion1 >= %s AND criterion1 < %s)   AND criterion2 < %s THEN 'AV' 
                                 WHEN (criterion1 >= %s AND criterion1 < %s)   AND criterion2 < %s THEN 'BV' 
                                 WHEN (criterion1 >= %s)                       AND criterion2 < %s THEN 'CV' 
                                 WHEN (criterion1 >= %s AND criterion1 < %s)   AND criterion2 > %s THEN 'AN' 
                                 WHEN (criterion1 >= %s AND criterion1 < %s)   AND criterion2 > %s THEN 'BN' 
                                 WHEN (criterion1 >= %s)                       AND criterion2 > %s THEN 'CN'
                                 END);
                                 
                                 SELECT S.%s AS Aggr_id,                    
                                 C.category AS category,
                                 COUNT(C.category)AS count 
                                 INTO %s                                        
                                 FROM %s AS S JOIN %s AS C   
                                 ON ST_CONTAINS(S.geom, C.geom)
                                 WHERE category IS NOT NULL 
                                 GROUP BY S.%s, C.category 
                                 ORDER BY S.%s;
                                 
                                 DROP TABLE IF EXISTS sum_help;
                                 SELECT Aggr_id AS Aggr_id,  sum (count) AS sum 
                                 INTO sum_help 
                                 FROM %s  
                                 GROUP by Aggr_id;
                                 
                                 DROP TABLE IF EXISTS help2;
                                 SELECT u.Aggr_id, u.category, u.count, sh.sum
                                 INTO help2
                                 FROM %s AS u LEFT JOIN sum_help AS sh 
                                 ON u.Aggr_id = sh.Aggr_id;

                                 ALTER TABLE help2 ADD COLUMN Ratio float;
                                 ALTER TABLE help2 aDD COLUMN Ratio_log float;
                                 UPDATE help2 SET Ratio = count/sum; 
                                 UPDATE help2 SET Ratio_log = -(Ratio *log(Ratio));

                                 
                                 SELECT Aggr_id AS Aggr_id,  abs(sum (Ratio_log)/log(%s)) AS Entropie 
                                 INTO %s 
                                 FROM help2
                                 GROUP by Aggr_id;

                                 ALTER TABLE %s ADD PRIMARY KEY (Aggr_id);
                                
                                 
                                 
                                 DROP TABLE %s;
                                 DROP TABLE %s; 
                                 DROP TABLE sum_help;
                                 DROP TABLE help2;

                                 " 
                                 
                                 ,output1,output1,output1,crit1Field,crit2Field,tableCategory,output1
                                 ,output1,output1,output1,output1,output1,crit1LV1,crit1LV2,crit2Sep,crit1LV2,crit1LV3
                                 ,crit2Sep,crit1LV3,crit2Sep,crit1LV1,crit1LV2,crit2Sep,crit1LV2,crit1LV3,
                                 crit2Sep,crit1LV3,crit2Sep
                                 
                                 ,AggrField,output2,tableAggregation,output1,AggrField,AggrField,
                                 
                                 output2,output2,Ncat,output3,output3, output1, output2
                                 ))
  clear1
  clear2
  cat
}



#----------------------------------- USAGE --------------------------------------------------------------------------------------------------

#if a fishnet or a hexgrid shall be used as aggregationlevel, User should use fishnet() or hexgrid() prior to create the geometries

#function(connection, tableAggregation, AggrField, tableCategory, crit1Field, crit2Field, crit1LV1, crit1LV2, crit1LV3, crit2Sep, Ncat, output1, output2,output3)

# categorize(con, "tvz","vbz_no", "mietobjekte", "anzahletag", "baujahr", 1, 2, 6, 1948, 6, "categories_tvz", "cat_tvz_count", "Entropie_tvz") 
# 
# categorize(con, "hex_mietobjekte","gid", "mietobjekte", "anzahletag", "baujahr", 1, 2, 6, 1948, 6, "categories_hex", "cat_hex_count","Entropie_hex")
# 
# 
# #---------------------------------------------------------------------------------------------------------------------------------------------
# 
# 
# #disconnect DB Connection
# dbDisconnect(con)
