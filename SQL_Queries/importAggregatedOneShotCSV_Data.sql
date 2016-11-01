DROP TABLE IF EXISTS public.testImportaggregated;
CREATE TABLE public.testImportaggregated (
gid SERIAL PRIMARY Key,
interval_begin FLOAT,
interval_end FLOAT,
interval_id VARCHAR (20),
edge_arrived INTEGER,
edge_density FLOAT,
edge_departed INTEGER,
edge_entered INTEGER,
edge_id VARCHAR (75),
edge_laneChangedFrom INTEGER,
edge_laneChangedTo INTEGER,
edge_left INTEGER,
edge_occupancy FLOAT,
edge_sampledseconds FLOAT,
edge_speed FLOAT,
edge_travelTime FLOAT,
edge_waitingTime FLOAT);


COPY public.testImportaggregated 	(interval_begin, interval_end, interval_id, edge_arrived, edge_density, edge_departed, edge_entered, edge_id, edge_laneChangedFrom,
					edge_laneChangedTo, edge_left, edge_occupancy, edge_sampledseconds, edge_speed, edge_travelTime, edge_waitingTime)
FROM 'D:\Manuel\vonSimon\Von Matthias\aggregated_oneshot_meso.csv' WITH CSV HEADER DELIMITER ';';
