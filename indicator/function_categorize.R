
# (re)classification by variing combination of two different criteria and forming new categories
#user specifies in the function call by the use of the parameters the criteria for the combination
#returns a table containing the new formed crieteria as well as a table containing the count per category per unit of aggregation



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


#' @param output1: As string - name of the output table containing the categories 
#'                            (default schema is "public", if varies -> "schema.table" instead of "table")
                           
#' @param output2: As string - name of ouptut table containing a count of the formed categories per unit of aggregation 
#'                            (default schema is "public", if varies -> "schema.table" instead of "table")

#----------------------------SCRIPT------------------------------------------------------------------------------------------

categorize <- function(connection, tableAggregation, AggrField, tableCategory, crit1Field, 
                       crit2Field, crit1LV1, crit1LV2, crit1LV3, crit2Sep, output1,output2) {
       
            clear1 <- dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;",output1))
            clear2 <- dbGetQuery(con, sprintf("DROP TABLE IF EXISTS %s;",output2))
           
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
                                           WHEN (criterion1 >= %s AND criterion1 < %s)  AND criterion2 < %s THEN 'AV' 
                                           WHEN (criterion1 >= %s AND criterion1 < %s)   AND criterion2 < %s THEN 'BV' 
                                           WHEN (criterion1 >= %s)                       AND criterion2 < %s THEN 'CV' 
                                           WHEN (criterion1 >= %s AND criterion1 < %s)  AND criterion2 > %s THEN 'AN' 
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
                                      ORDER BY S.%s;"
       
                                      ,output1,output1,output1,crit1Field,crit2Field,tableCategory,output1
                                      ,output1,output1,output1,output1,output1,crit1LV1,crit1LV2,crit2Sep,crit1LV2,crit1LV3
                                      ,crit2Sep,crit1LV3,crit2Sep,crit1LV1,crit1LV2,crit2Sep,crit1LV2,crit1LV3,
                                      crit2Sep,crit1LV3,crit2Sep
                                      
                                      ,AggrField,output2,tableAggregation,output1,AggrField,AggrField
                                      ))
            clear1
            clear2
            cat
}


#----------------------------------- USAGE --------------------------------------------------------------------------------------------------

#if a fishnet or a hexgrid shall be used as aggregationlevel, User should use fishnet() or hexgrid() prior to create the geometries

#function(connection, tableAggregation, AggrField, tableCategory, crit1Field, crit2Field, crit1LV1, crit1LV2, crit1LV3, crit2Sep, output1, output2)

# categorize(con, "tvz","vbz_no", "mietobjekte", "anzahletag", "baujahr", 1, 2, 6, 1948, "categories_tvz", "cat_tvz_count") 
# 
# categorize(con, "hex_mietobjekte","gid", "mietobjekte", "anzahletag", "baujahr", 1, 2, 6, 1948, "categories_tvz", "cat_tvz_count")
# 
# 
# #---------------------------------------------------------------------------------------------------------------------------------------------
# 
# 
# #disconnect DB Connection
# dbDisconnect(con)




#----------------------------------- SQL CODE--------------------------------------------------------------------------------------------------
# --classification into categories
# DROP TABLE IF EXISTS categories; 
# CREATE TABLE categories(
#   gid serial PRIMARY KEY,
#   anzahletag  varchar,
#   Baujahr varchar,
#   __gidMiet numeric);
# 
# ALTER TABLE categories ADD COLUMN geom geometry (POINT, 25833);
# 
# INSERT INTO categories (SELECT mietobjekte.gid AS gid,
#                         mietobjekte.anzahletag AS anzahletag,
#                         mietobjekte.baujahr AS Baujahr,
#                         mietobjekte.__gid AS __gidMiet,
#                         mietobjekte.geom AS geom
#                         FROM mietobjekte);
# 
# 
# ALTER TABLE categories ADD COLUMN category varchar;
# 
# --change type of category columns for following classification
# UPDATE categories  SET anzahletag = NULL WHERE anzahletag = 'NULL';
# UPDATE categories SET Baujahr = NULL WHERE Baujahr = 'NULL';
# ALTER TABLE categories ALTER COLUMN anzahletag type numeric using anzahletag::numeric;
# ALTER TABLE categories ALTER COLUMN Baujahr type numeric using Baujahr::numeric;
# 
# UPDATE categories
# SET category =(CASE 
#                --Nullcases, not needed here
#                --WHEN (anzahletag = NULL OR baujahr = NULL) THEN NULL
#                -- 6 categories
#                WHEN (anzahletag = 1)                       AND baujahr < 1948 THEN 'AV' 
#                WHEN (anzahletag >= 2 AND anzahletag < 6)   AND baujahr < 1948 THEN 'BV' 
#                WHEN (anzahletag >= 6)                      AND baujahr < 1948 THEN 'CV' 
#                WHEN (anzahletag = 1)                       AND baujahr > 1948 THEN 'AN' 
#                WHEN (anzahletag >= 2 AND anzahletag < 6)   AND baujahr > 1948 THEN 'BN' 
#                WHEN (anzahletag >= 6)                      AND baujahr > 1948 THEN 'CN' 
#                
#                END);
# 
# 
# 
# DROP TABLE IF EXISTS contains;
# SELECT hex_mietobjekte.gid AS Aggr_id,
# categories.category AS category,
# COUNT(categories.category)AS count 
# INTO contains          
# FROM hex_mietobjekte JOIN categories
# ON ST_CONTAINS(hex_mietobjekte.geom, categories.geom)
# WHERE category IS NOT NULL 
# GROUP BY hex_mietobjekte.gid,categories.category
# ORDER BY hex_mietobjekte.gid;








