###
### Fresh start to lm regression response mietekalt
###
##  decided upon Vars: (qmmiete), (wohnflaech),
##                    LS, inc4, Gc_car, no_sut_lines, jobs_, pop_dens, green_tvz_, prop_migr

library(corrgram)
?cor
?lm
?summary

## read the dataframe, aka postgresql rent
df<-dbGetQuery(connection,"SELECT * FROM rent")

## with qmmiete Included
cols_qm <- c("qmmiete", "mietekalt", "singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "wohnflaech", "bjahr", "gbgroesse", "zimmeranza_num",
             "avgincome", "green_tvz_surround", "prop_green_tvz", "pop_dens", "prop_migr", "gc_car", "co_groc_foot", "highw_avg_tt_pass")

rentdf_qm <- df[,cols_qm]

rdf <- rentdf_qm[c(-60034, -59187, -56568, -56567, -56566, -56563, -56538, -55417, -55421),]   ### WHY? see below


## so create new rdf w/ those values from above removed
rdf <- rdf[!rdf$ls<13 & !rdf$mietekalt>3600,]
plot <- plot(rdf$ls, rdf$mietekalt)

## remove all na entries from rdf:
str(rdf1)
rdf1 <- rdf[complete.cases(rdf),]



## take the response var form this df
miete <- rdf1$mietekalt
str(miete)
qmmiete <- rdf1$qmmiete



## list of all chosen predictors
pred_a <- c("qmmiete", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "wohnflaech", "green_tvz_surround", "pop_dens", "prop_migr", "gc_car")
preddf_a <- rdf1[,pred]

## list of predictors without wohnflaech
pred_w <- c("qmmiete", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "green_tvz_surround", "pop_dens", "prop_migr", "gc_car")
preddf_w <- rdf1[,pred_w]

## list of predictors without qmmiete
pred_q <- c("ls", "no_jobs_div100k", "no_sut_lines", "inc4", "wohnflaech", "green_tvz_surround", "pop_dens", "prop_migr", "gc_car")
preddf_q <- rdf1[,pred_q]

## list of predictors without qmmiete and wohnflaech
pred_wq <- c("ls", "no_jobs_div100k", "no_sut_lines", "inc4", "green_tvz_surround", "pop_dens", "prop_migr", "gc_car")
preddf_wq <- rdf1[,pred_wq]

## list of all predictors
pred_com <- c("qmmiete", "singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "wohnflaech", "bjahr", "gbgroesse", "zimmeranza_num",
              "avgincome", "green_tvz_surround", "prop_green_tvz", "pop_dens", "prop_migr", "gc_car", "co_groc_foot", "highw_avg_tt_pass")
preddf_com <- rdf1[,pred_com]

## list of all predictors without qmmiete and wohnflaech and repeating ones liek avg_inc & grenn_prop
pred_com_wq <- c("singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "bjahr", "gbgroesse", "zimmeranza_num",
              "green_tvz_surround", "pop_dens", "prop_migr", "gc_car", "co_groc_foot", "highw_avg_tt_pass")
preddf_com_wq <- rdf1[,pred_com_wq]

## list of ideal?? predictors:
pred_id <- c("singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "gbgroesse", "zimmeranza_num", "green_tvz_surround", "prop_migr" )
preddf_id <- rdf1[,pred_id]


####
#### MODELLING miete
####
## basic reduce model _wq
lm_wq <- lm(miete ~ ., preddf_wq)
summary(lm_wq)

## model _w
lm_w <- lm(miete ~ ., preddf_w)
summary(lm_w)

## model _q
lm_q <- lm(miete ~ ., preddf_q)
summary(lm_q)

## model with all selected incl qmmiete & wohnflaech
lm_a <- lm(miete ~ ., preddf)
summary(lm_a)

## model containing all vars
lm_com <- lm(miete ~ ., preddf_com)
summary(lm_com)

## model containing only qmmiet and wohnflaeche
lm_idiot <- lm(miete~ qmmiete+wohnflaech, preddf_com)
summary(lm_idiot)

## model containing all vars excluding qmmiete & wohnflaech
lm_com_wq <- lm(miete ~ ., preddf_com_wq)
summary(lm_com_wq)

lm_qm_com_wq <- lm(qmmiete ~., preddf_com_wq)
summary(lm_qm_com_wq)



##excluding bjahr/highway b/c of low confidence also co_groc/pop_dens/gc_car b/c of low impact yields:
## c("singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "gbgroesse", "zimmeranza_num", "green_tvz_surround", "prop_migr" )

## --> yields ideal model???  ## doesnt look too shabby single fam yould be elim
lm_id <- lm(miete ~ ., preddf_id)
summary(lm_id)

## testing the ideal version on qmmiete
lm_qm_id <- lm(qmmiete ~., preddf_id)
summary(lm_qm_id)
