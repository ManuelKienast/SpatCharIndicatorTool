#source("indicator\\countPointsinPolygon.R")
source("indicator\\density.R")
con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "129.247.28.69",
                 port = 5432,
                 user = "urmo",
                 password = "urmo",
                 dbname = "urmo")

dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_until49 from public.kgs44 where public.kgs44.bj_class=2 or public.kgs44.bj_class=1")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_1950_2000 from public.kgs44 where public.kgs44.bj_class=3 or public.kgs44.bj_class=4 or public.kgs44.bj_class=5 or public.kgs44.bj_class=6 or public.kgs44.bj_class=7 or public.kgs44.bj_class=8")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_after2000 from public.kgs44 where public.kgs44.bj_class>8")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_after2000_2 from public.kgs44 where public.kgs44.bj_class>8")

dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "public.kgs44", "veu_survey.berlin_num_kgs44" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_until49", "veu_survey.berlin_num_geb_until49" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_1950_2000", "veu_survey.berlin_num_geb_1950_2000" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_after2000", "veu_survey.berlin_num_geb_after2000" )


dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_after2000 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_after2000 s set percentage = ((s.totale::double precision/p.totale::double precision)*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_1950_2000 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_1950_2000 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")
           
dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_until49 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_until49 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_until49 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_until49 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "DROP Table if exists veu_survey.berlin_num_kgs44")

#dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_facilities_health", "veu_survey.berlin_num_health_1km" )

