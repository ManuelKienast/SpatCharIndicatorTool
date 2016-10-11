Possible generalizations based on the information of the variables of all functions listed below.

A_Area -- aggregation area, will always be the same, if it is fishnet, hexgrid or tvz,plr.
Schema.A_Area --  Schema of the AggreArea - need to rewrite function_categorize and function_entropy to fit the additional schema

ExaminationGeometries -- if its points streets buildings tvz whatever
Schema.Exgeos         -- the schema of the above

outputtable -- if rewritten to automatically include the indicator(if study is Berlin2012) aka density.Berlin2012, area.Berlin2012 ..

A_Id -- Aggregation Area unique ID, e.g. gid
Ex_Id -- ExaminationGeometriy ID, e.g. gid

A_Geom -- geometry column of A_Area  e.g. geom or the_geom
Ex_Geom -- geometry column of Ex_Area  e.g. geom or the_geom








# _Function_CountPointsinPolygon.R
- psqlAvMean()

#' @param connection : A connection to the PostGIS database.
#' @param WriteToTable AS string -- Table to create and write results into
#' @param schema1      AS string -- schema of table 1
#' @param schema2      AS string -- schema of table 2
#' @param table1       AS string -- table cotaining the point features = "mietobjekte", ## Point Feature Table
#' @param Id1          AS string -- unique identifier for table 1
#' @param table2       AS string -- table containig the aggregation geometries
#' @param Id2          AS string -- unique identifier of table 2
#' @param geom1        AS string -- the column containg the geometry, usually "geom"
#' @param geom2        AS string -- the column containg the geometry, usually "geom"
#' 

_____________________________________________________
# _Function_PlaygrounArea.R
- PlayArea()

#' @param connection : A connection to the PostGIS database.
#' @param WriteToTable AS string -- Table to create and write results into
#' @param Agg          AS string -- AggregationTable - containig geometries of Aggregation units, e.g. TVZ or Fishnet
#' @param Agg_sche     AS string -- schema of the AggregationTable
#' @param sourcee      AS string -- SourceInformation - geometries containing the cells with childrens count
#' @param sourc_sche   AS string -- schema of the ScourceInformation table
#' @param Agg_ID       AS string -- unique ID of Aggregation Areas  i.e. TVZ-Identifier number
#' @param Source_ID    AS string -- unique ID of source Areas to facilitate the connection to the children per Planungsraum table
#' @param PlayGrounds  AS string -- table containg the PlayGround geometries
#' @param childNos     AS string -- table cointaing children information
#' @param childNos_ID  AS string -- Identifier to JOIN ON : Source_ID to combine childrens # and their geometries
#' @param childage     AS string -- Column in which the children are stored, see usage examples below
#' 

_____________________________________________________
# _Function_Statistic_Ratios.R
- RatioStats()

#' @param  connection = con,             ## connection to db
#' @param  WriteToTable = "RatioStats",  ## results table, name given by user
#' @param  schema1 = "public",           ## schema of table 1 - numerator
#' @param  schema2 = "public",           ## schema of table 2 - denominator
#' @param  table1 = "mietobjekte",       ## table 1 - containing the numerator
#' @param  table2 = "mietobjekte",       ## table 2 - containing the denominator
#' @param  column1 = "mietekalt",        ## column 1 - the column containing the numerator
#' @param  column2 = "wohnflaech",       ## column 2 - the column containing the denominator
#' @param  gid1 = "gid",                 ## unique ID table 1
#' @param  gid2 = "gid",                 ## unique ID table 2
#' @param  geom1 = "geom",               ## geometry column of table 1 - usually geom
#' @param  geom2 = "geom",               ## geometry column of table 2 - usually geom
#' @param  GeomSchema = "public",        ## the schema of the aggregation area table
#' @param  GeomTable = "TVZ",            ## the table containing the desired aggregation area, e.g. TVZ / PLR / Fishnet
#' @param  GeomTableID = "code",         ## unique ID
#' @param  Geomgeom = "geom"             ## geometry column of the aggregation area table 
#' 

_____________________________________________________
# function_categorize
- categorize()

#' @param connection :       A connection to the PostGIS database. Contained in the variabel 'con'
#' @param tableAggregation:  As string - table, which contains the geometry for aggregation (default is "public" , if varies -> "schema.table" )
#' @param AggrField:         As string - field, which identifies clearly each unit of aggregation 
#' @param tableCategory:     As string - table, which contains the criteria for the reclassification and the associated geometries
#'                                   (default schema is "public", if varies -> "schema.table" instead of "table")
#' @param crit1Field:        As string - field, which specifies criterion 1
#' @param crit2Field:        As string - field, which specifies criterion 2

#' @param crit1LV1:          As int  - lowest value class1 criterion1         
#' @param crit1LV2:          As int  - lowest value class2 criterion1 
#' @param crit1LV3:          As int  - lowest value class3 criterion1 
#' @param crit2Sep:          As int - value that seperates criterion2 into two classes 

#' @param output1:           As string - name of the output table containing the categories (default schema is "public", if varies -> "schema.table" instead of "table")
#' @param output2:           As string - name of ouptut table containing a count of the formed categories per unit of aggregation 
#'                            (default schema is "public", if varies -> "schema.table" instead of "table")
#'                            

_____________________________________________________
#function_count.R
- countPolis2()

#' @param con                 A connection to the PostGIS database.
#' @param schema              A string: the name of the scheme in the database, in which the tables are included.
#' @param table               A string: the name of the table in the PostGIS database containing the geometry you want to count.
#' @param to_count            A string: the name of the column of the geometrie's identifier.
#' @param aggr_schema         A string: the name of the scheme in the database, containing the aggregation table.
#' @param aggregation         A string: the name of the table in the PostGIS database containing the aggregation units.
#' @param aggr_id             A string: the name of the identifier of the aggregation units.
#' @param out_schema          A string: the name of the scheme in the database, that should contain the output table.
#' @param output              A string: the name of the table, that should contain the output.
#' 
_____________________________________________________
# function_density
- dsty()

#' @param con:                A connection to the PostGIS database.
#' @param schema1:            As string - Name of the Schema that contains ex_area
#' @param ex_area             As string: the name of the table in the PostGIS database containing the geometry 
#'                               that represents your area of examination (Grid, etc.) must have Polygon or Multipolygon Geometry
#' @param schema2:            As string - Name of the Schema that contains obj
#' @param obj:                As string - the feature which density shall be calculated. Can be Point, Polygon or Line.
#' @param output:             As string - Name of the Output-Table that will be created in the Database (in schema1)
#' 
_____________________________________________________
# function_entropy
- categorize()

#' @param connection :       A connection to the PostGIS database. Contained in the variabel 'con'
#' @param tableAggregation:  As string - table, which contains the geometry for aggregation (default is "public" , if varies -> "schema.table" )
#' @param AggrField:         As string - field, which identifies clearly each unit of aggregation 
#' @param tableCategory:     As string - table, which contains the criteria for the reclassification and the associated geometries
#'                                   (default schema is "public", if varies -> "schema.table" instead of "table")
#' @param crit1Field:        As string - field, which specifies criterion 1
#' @param crit2Field:        As string - field, which specifies criterion 2
#' @param crit1LV1:          As int  - lowest value class1 criterion1         
#' @param crit1LV2:          As int  - lowest value class2 criterion1 
#' @param crit1LV3:          As int  - lowest value class3 criterion1 
#' @param crit2Sep:          As int - value that seperates criterion2 into two classes 
#' @param Ncat:              As int - number of categories to be formed 
#' @param output1:           As string - name of the output table containing the categories (default schema is "public", if varies -> "schema.table" instead of "table")
#' @param output2:           As string - name of ouptut table containing a count of the formed categories per unit of aggregation 
#'                            (default schema is "public", if varies -> "schema.table" instead of "table")
#'             
                                           
_____________________________________________________
# function_fishnet.R
- fishnet()

#' @param con:              A connection to the PostGIS database.
#' @param x_cell:           As numeric - width of grid cells
#' @param y_cell:           As numeric - height of grid cells
#' @param schema1:          As string - Name of the Schema in which the reference layer(table) is located
#' @param table:            As string - reference layer over which the grid shall be cast
#' @param schema2:          As string - Name of the Schema in where the fishnet shall be created
#' @param name:             As string - name of the fishnet to be created

_____________________________________________________
# function_hex_grid.R
- hexgrid()

#' @param con :             A connection to the PostGIS database.
#' @param hex_width:        As numeric - Width of grid cells
#' @param schema1:          As string - Name of the Schema in which the reference layer(table) is located
#' @param table:            As string - reference layer over which the grid shall be cast
#' @param schema2:          As string - Name of the Schema in where the fishnet shall be created
#' @param name:             As string - name of the fishnet to be created
#' 

_____________________________________________________
# function_landuse.R
- areaRatio()

#' @param con               A connection to the PostGIS database.
#' @param schema            A string: the name of the scheme in the database, in which the tables are included.
#' @param table             A string: the name of the table in the PostGIS database containing the geometry you want to know the ratio.
#' @param category          A string: the name of the column of the categories.
#' @param aggr_schema       A string: the name of the scheme in the database, in which the aggregation table is stored.  
#' @param aggregation       A string: the name of the table in the PostGIS database containing the aggregation units.
#' @param aggr_id           A string: the name of the identifier of the aggregation units.
#' @param out_schema        A string: the name of the schema the new table is written into.
#' @param output            A string: the name of the results table to be written into the db.
#' @param intersection      A string: the name of the new table containing the intersected areas.
#' 
