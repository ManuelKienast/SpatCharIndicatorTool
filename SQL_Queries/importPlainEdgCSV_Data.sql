DROP TABLE IF EXISTS public.testImportEdge;
CREATE TABLE public.testImportEdge (
gid SERIAL PRIMARY Key,
edges_version FLOAT,
edge_from VARCHAR (100),
edge_id VARCHAR (100),
edge_name VARCHAR (100),
edge_numLanes INTEGER,
edge_priority INTEGER,
edge_shape VARCHAR (2500),
edge_speed FLOAT,
edge_spreadType VARCHAR (20),
edge_to VARCHAR (100),
roundabout_edges VARCHAR (250),
roundabout_nodes VARCHAR (250),
geom GEOMETRY (MultiLineString, 25833));


COPY public.testImportEdge (edges_version, edge_from, edge_id, edge_name, edge_numLanes, edge_priority, edge_shape, edge_speed,
			edge_spreadType, edge_to, roundabout_edges, roundabout_nodes)
FROM 'D:\Manuel\vonSimon\Von Matthias\net_plain.edg.csv' WITH CSV HEADER DELIMITER ';'

UPDATE public.testImportEdge
SET edge_shape = REPLACE(edge_shape, ' ', '#')
SET edge_shape = REPLACE(edge_shape, ',', ' ');
SET edge_shape = REPLACE(edge_shape, '#', ', ');

UPDATE public.testImportEdge
SET geom = ST_Transform(St_GeomFromText('MultiLineString ((' || testImportEdge.edge_shape || '))', 4326), 25833);