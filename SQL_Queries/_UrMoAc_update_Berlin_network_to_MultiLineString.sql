----  Preparing the osm.berlin_network for usage with the UrMoAc
Alter Table osm.berlin_network
	DROP the_geom;

ALTER Table osm.berlin_network
	ADD COLUMN the_geom geometry (MultiLineString, 4326);

INSERT INTO osm.berlin_network (the_geom)
	SELECT st_multi(shape)
	FROM osm.berlin_network;

ALTER TABLE osm.berlin_network
    RENAME shape TO shapeLinestring;

ALTER Table osm.berlin_network ADD COLUMN shape geometry (MultiLineString, 4326);

INSERT INTO osm.berlin_network (shape)
	SELECT st_multi(shapeLinestring)
	FROM osm.berlin_network;

ALTER TABLE osm.berlin_network
	DROP shapeLinestring;

CREATE INDEX berlin_network_gix
      ON osm.berlin_network
      USING GIST (shape);


---------- Copy the table to another one, maybe urmoac doesnt like computation of the same tables as net and to layer
SELECT * INTO public.Berlin_strassen FROM
    (
      SELECT *
          FROM osm.berlin_network
    ) as foo;

ALTER TABLE berlin_strassen
	ADD PRIMARY KEY (id);

 CREATE INDEX berlin_strassen_gix
      ON berlin_strassen
      USING GIST (the_geom);

