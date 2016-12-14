DROP TABLE IF EXISTS public.testImport;
CREATE TABLE public.testImport (
"gid" SERIAL PRIMARY Key,
"nodes_version" FLOAT,
"node_id" VARCHAR (100),
"node_type" VARCHAR (20),
"node_x" FLOAT,
"node_y" FLOAT,
"geom" GEOMETRY (Point, 25833));


COPY public.testImport (nodes_version, node_id, node_type, node_x, node_y)
FROM 'D:\Manuel\vonSimon\Von Matthias\net_plain.nod.csv' WITH CSV HEADER DELIMITER ';'

UPDATE public.testimport
SET geom = ST_Transform(St_GeomFromText('Point ('|| testImport.node_x ||' '|| testImport.node_y || ')', 4326), 25833);