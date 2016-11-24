----  Preparing the NEW osm.new_berlin_network for usage with the UrMoAc
---- same steps as below, copying the network to public with geometry as the geom
DROP TABLE IF EXISTS public.Berlin_new_strassen;

SELECT * INTO public.Berlin_new_strassen FROM
    (
      SELECT *
          FROM osm.berlin_new_network
    ) as foo;

ALTER TABLE berlin_new_strassen
	ADD COLUMN gid serial PRIMARY KEY;

ALTER TABLE berlin_new_strassen
	RENAME COLUMN shape TO the_geom;

CREATE INDEX berlin_new_strassen_gix
      ON berlin_new_strassen
      USING GIST (the_geom);

---
ALTER TABLE public.Berlin_new_strassen ADD PRIMARY KEY (id);
ALTER TABLE public.Berlin_new_strassen DROP CONSTRAINT berlin_new_strassen_pkey;

ALTER Table public.Berlin_new_strassen
	ADD COLUMN the_geom geometry (MultiLineString, 4326);

ALTER TABLE public.Berlin_new_strassen
	DROP shape;




----  Preparing the osm.berlin_network for usage with the UrMoAc
---------- Copy the table to another one, maybe urmoac doesnt like computation of the same tables as net and to layer
DROP TABLE IF EXISTS public.Berlin_strassen_test;

SELECT * INTO public.Berlin_strassen_test FROM
    (
      SELECT *
          FROM osm.berlin_network
    ) as foo;

ALTER Table public.Berlin_strassen_test
	ADD COLUMN the_geom geometry (MultiLineString, 4326);

ALTER TABLE berlin_strassen_test
	ADD COLUMN gid SERIAL;

ALTER TABLE berlin_strassen_test
	ADD PRIMARY KEY (gid);

UPDATE berlin_strassen_test
	SET the_geom = ST_Multi(shape);

CREATE INDEX berlin_strassen_test_gix
      ON berlin_strassen_test
      USING GIST (the_geom);

ALTER TABLE public.Berlin_strassen
	DROP the_geom;

ALTER TABLE public.Berlin_strassen
	DROP shape;


-------  Convert the linestring from berlin_network to multoline 

ALTER Table osm.berlin_network
	RENAME shape TO shape_old; 

ALTER Table osm.berlin_network
	ADD COLUMN shape geometry (MultiLineString, 4326);

UPDATE osm.berlin_network
	SET shape = ST_Multi(shape_old);

DROP INDEX IF EXISTS berlin_network_gix;
CREATE INDEX berlin_network_gix
      ON osm.berlin_network
      USING GIST (shape);



ALTER TABLE berlin_strassen_test
	ADD COLUMN gid SERIAL;

ALTER TABLE berlin_strassen_test
	ADD PRIMARY KEY (gid);

UPDATE berlin_strassen_test
	SET the_geom = ST_Multi(shape);

CREATE INDEX berlin_strassen_test_gix
      ON berlin_strassen_test
      USING GIST (the_geom);

ALTER TABLE public.Berlin_strassen
	DROP the_geom;

ALTER TABLE public.Berlin_strassen
	DROP shape;


