#source("indicator\\countPointsinPolygon.R")
source("indicator\\density.R")
con <- dbConnect(dbDriver("PostgreSQL"),
                 host = "129.247.28.69",
                 port = 5432,
                 user = "urmo",
                 password = "urmo",
                 dbname = "urmo")

dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_hh_1 from public.kgs44 where public.kgs44.hh=1")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_hh_2_6 from public.kgs44 where public.kgs44.hh>1 and public.kgs44.hh<7;")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_hh_7_20 from public.kgs44 where public.kgs44.hh>6 and public.kgs44.hh<20;")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_hh_21_40 from public.kgs44 where public.kgs44.hh>19 and public.kgs44.hh<41;")
dbGetQuery(con, "SELECT * INTO veu_survey.berlin_kgs44_hh_gr_40 from public.kgs44 where public.kgs44.hh>40;")


dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "public.kgs44", "veu_survey.berlin_num_kgs44" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_hh_1", "veu_survey.berlin_num_geb_hh_1" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_hh_2_6", "veu_survey.berlin_num_geb_hh_2_6" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_hh_7_20", "veu_survey.berlin_num_geb_hh_7_20" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_hh_21_40", "veu_survey.berlin_num_geb_hh_21_40" )
dsty_poi(con,"veu_survey.berlin_adressen_2016_survey_buffer1km", "veu_survey.berlin_kgs44_hh_gr_40", "veu_survey.berlin_num_geb_hh_gr_40" )


dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_hh_1 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_hh_1 s set percentage = ((s.totale::double precision/p.totale::double precision)*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_hh_2_6 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_hh_2_6 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_hh_7_20 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_hh_7_20 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_hh_21_40 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_hh_21_40 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")

dbGetQuery(con, "ALTER TABLE veu_survey.berlin_num_geb_hh_gr_40 ADD COLUMN percentage double precision;")
dbGetQuery(con, "update veu_survey.berlin_num_geb_hh_gr_40 s set percentage = (s.totale::double precision/p.totale::double precision*100) FROM veu_survey.berlin_num_kgs44 p WHERE p.gid=s.gid;")


dbGetQuery(con, "DROP Table if exists veu_survey.berlin_kgs44_hh_1")
dbGetQuery(con, "DROP Table if exists veu_survey.berlin_kgs44_hh_2_6")
dbGetQuery(con, "DROP Table if exists veu_survey.berlin_kgs44_hh_7_20")
dbGetQuery(con, "DROP Table if exists veu_survey.berlin_kgs44_hh_20_40")
dbGetQuery(con, "DROP Table if exists veu_survey.berlin_kgs44_hh_gr_40")


dbGetQuery(con, "DROP Table if exists veu_survey.berlin_num_kgs44")
