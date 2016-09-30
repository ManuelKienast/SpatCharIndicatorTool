# Christina Kuhlmann, 16.09.2016
# This script implements an interactive map with leaflet for R and colors the added Polygons according to an analised field.

library(RPostgreSQL)
# requires(DBI)
library(sp)
library(rangeMapper)
# requires(RSQLite, ggplot2, gtable, munsell, colorspace, plyr, classInt, e1071, data.table, chron, foreach, iterators, 
#gridExtra, maptools)
library(leaflet)
# requires(digest, jsonlite, yaml, Rccp) 

#-------------------------------------------------------------

# Daten abfragen

## Erstellen der DB-Verbindung
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "dlr", host = "localhost", user = "postgres", password = "postgres") 
dbListTables(con)


## getting data for leaflet
getData <- function(con, schema, data_table,id_column, data_column){
  dbGetQuery(con, sprintf(
    "SELECT %s as unit, %s as Data FROM %s.%s", id_column, data_column, schema, data_table
  ))
}

## getting geometry in WKT
getGeometry <- function(con, schema, geom_table, geom_id){ 
  dbGetQuery(con, sprintf(
  "SELECT %s as unit, ST_AsText(geom) as geom
  FROM %s.%s
  GROUP BY %s, geom
  ORDER BY %s", geom_id, schema, geom_table, geom_id, geom_id))
}



counter <- countPolis(con, "public", "mietobjekte", "obid", "public", "rbs_od_blk_2015_mitte", "blk")
spatial_counter <- getGeometry(con, "public", "rbs_od_blk_2015_mitte", "blk")


counter <- countPolis(con, "public", "buildings_mitte_20160825", "building", "public", "rbs_od_blk_2015_mitte", "blk")
spatial_counter <- getGeometry(con, "public", "rbs_od_blk_2015_mitte", "blk")

counter <- countPolis(con, "public", "spielplaetze", "kennzeich", "public", "planungsraum_mitte", "schluessel")
spatial_counter <- getGeometry(con, "public","planungsraum_mitte", "schluessel")



# transforming WKT to SpatialPolygonsDataFrame
spatial_counter <- WKT2SpatialPolygonsDataFrame(spatial_counter, 'geom', 'unit')

# transforming to SpatialPolygonsDataFrame costs the data, so merge data and geometry together
class(spatial_counter)
spatial_counter <- sp::merge(spatial_counter, counter, all.x = FALSE)
class(spatial_counter)


# define coordinate system, transform to WGS84
proj4string(spatial_counter) <- CRS("+init=epsg:25833")
spatial_counter <- spTransform(spatial_counter, CRS("+init=epsg:4326"))
spatial_counter@proj4string


#---------------------------------------------------------
# leaflet

## make a map
(m <- leaflet())
## add osm-Tiles
(m  %>% addTiles())
#all together with the magittr Pipe-Operator %>% (Str+Shift+M)
(m <- leaflet() %>% addTiles())
## zoom to Berlin
m %>% setView(lng = 13.4, lat = 52.5, zoom = 10) 



# addPolygons
(m <- leaflet() %>% addTiles(m))
(m <- m %>% addPolygons(m, data = spatial_counter))

#add color
(m2 <- m %>%  
  addPolygons( data = spatial_counter, color = "red", weight = 3))

(m <- m %>% 
  addPolygons(data = spatial_counter))

(m2 <- m %>%  
  addPolygons( data = spatial_counter, fill = TRUE, fillColor = "blue", fillOpacity = 0.5, weight = 3, stroke = TRUE, color = "black"))



# set color acording to the count
## Create a continuous palette function
pal <- colorNumeric(palette = "Greens", domain = spatial_counter@data$count, na.color = "#FFFFFF")
## Apply the function to provide RGB colors to addPolygons
(m <- addPolygons(m, data = spatial_counter, 
                  color = ~pal(count), 
                  stroke = FALSE, 
                  smoothFactor = 0.2, 
                  fillOpacity = 1))
  

# with other palettes: Continuous Input, Discrete Colors
binpal <- colorBin(palette = "Greens", domain = spatial_counter@data$count, bins = 6, pretty = FALSE, na.color = "#FFFFFF" )
(m <- addPolygons(m, data = spatial_counter, stroke = FALSE, smoothFactor = 0.2, fillOpacity = 1,color = ~binpal(count)))

# Quantile
qpal <- colorQuantile(palette = "Greens", domain = spatial_counter@data$count, n = 6, na.color = "#FFFFFF")
(m <- addPolygons(m, data = spatial_counter, stroke = FALSE, smoothFactor = 0.2, fillOpacity = 1,color = ~qpal(count)))

# addPolygons(map, lng = NULL, lat = NULL, layerId = NULL, group = NULL, stroke = TRUE,
#            color = "#03F", weight = 5, opacity = 0.5, fill = TRUE, fillColor = color,
#            fillOpacity = 0.2, dashArray = NULL, smoothFactor = 1, noClip = FALSE,
#            popup = NULL, options = pathOptions(), data = getMapData(map))



#add Legend
(m <- addPolygons(m, data = spatial_counter, 
                  color = ~pal(count), 
                  stroke = FALSE, 
                  smoothFactor = 0.2, 
                  fillOpacity = 1) %>% 
  addLegend( position = "bottomright", 
             pal = pal, 
             values = spatial_counter@data$count, 
             title = "mietojekte", 
             opacity = 1))

# with other palettes: Continuous Input, Discrete Colors
binpal <- colorBin(palette = "Greens", domain = spatial_counter@data$count, bins = 6, pretty = FALSE, na.color = "#FFFFFF" )
(m <- addPolygons(m, data = spatial_counter, stroke = FALSE, smoothFactor = 0.2, fillOpacity = 1,color = ~binpal(count)) %>% 
  addLegend( position = "bottomright", pal = binpal, values = spatial_counter@data$count, title = "mietojekte", opacity = 1))

# Quantile
qpal <- colorQuantile(palette = "Greens", domain = spatial_counter@data$count, n = 6, na.color = "#FFFFFF")
(m <- addPolygons(m, data = spatial_counter, stroke = FALSE, smoothFactor = 0.2, fillOpacity = 1,color = ~qpal(count)) %>% 
  addLegend( position = "bottomright", pal = qpal, values = spatial_counter@data$count, title = "mietojekte", opacity = 1))


#addLegend(map, position = c("topright", "bottomright", "bottomleft", "topleft"), 
#          pal, values, na.label = "NA", bins = 7, colors, opacity = 0.5, labels, 
#          labFormat = labelFormat(), title = NULL, className = "info legend", layerId = NULL)


