### playing with statistics and the rent dataset
### cor and lm and summary(lm)

library(corrgram)

?cor
?lm
?summary


## read the dataframe, aka postgresql rent
df<-dbGetQuery(connection,"SELECT * FROM rent")

df

## quick dirty corr

names(df)
df2 <- df[,c("wohnflaech","green_tvz_surround","mietekalt")]
cor(df2)

df2[,"green_tvz_surround"]

#### there are NA values: one: tvz_id 722 present
## using: use = "complete.obs", shall delete the pairs with missing values

cor(df2, use = "complete.obs")    ## and it does, returns a result


####  warning  'x' muss numerisch sein.. well seems like mietewarm is not a number... ><
df2 <- df[,c("wohnflaech","mietekalt", "mietewarm")]
cor(df2)

str(df2$mietewarm)   ## indeed charsssszzzzzZZZZZZZzzzzzz
cor(is.numeric(df2))


###
##
#Blääh; needed cols are:
# qmmiete - DEPENDANT Var
# rent - mietekalt
# logsum - ls
# single family house - singlefam
# no of acces jobs - co_jobs_pt /100000 --> no_jobs_div100k
# no of sut lines - "no_sut_lines"
# Prop hh incom > 2600€ - inc4
# floor space - wohnflaech
# construction year - bjahr
# number of dwellings - gbgroesse
# number of rooms - zimmeranza
# avg income in tvz - avgincome
# prop of green space - green_tvz_surround
# pop density - pop_dens
# prop w/ migrant background - prop_migr
# general weight tt to other locations  - "gc_car"
# floor space in grocery stores 10 min walking - co_groc_foot
# distance ot highway - highw_avg_tt_pass

### create the dataframe
cols <- c("mietekalt", "singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "wohnflaech", "bjahr", "gbgroesse", "zimmeranza_num",
       "avgincome", "green_tvz_surround", "pop_dens", "prop_migr", "gc_car", "co_groc_foot", "highw_avg_tt_pass")

rentdf <- df[,cols]

## let the cor loose
str(rentdf)   ######  zimmeranzahl is the char-offender; fix incoming, fixed; running again
cor(rentdf)   ######  OH a surprise  invalid x-values....  and lots and lots of NAs..

## checking for the no of NAs in the df
sapply(rentdf, function(x) sum(is.na(x)))    ### with max of 171 cp_groc_foot NAs and the 133 (of 62412) looking to be same values, it seems the dataset is still
                                             ### with the use = "complete.obs", using only values which are complete

rent_corr <- cor(rentdf, use = "complete.obs")
summary(rent_corr)
plot(rent_corr)

### be patient plotting first
scatter <- ggplot(rentdf, aes(wohnflaech, mietekalt))


### plotting w/ corrgrams 

# 1a) with all numeric vars:
corrgram( rent_corr, main= "rent Berlin PC order")

# 1b) with all numeric vars ordered yb principal components :
corrgram( rent_corr, order= TRUE, main= "rent Berlin PC order")

# 2) split in shading and values
corrgram( rent_corr, order= TRUE, upper.panel= panel.cor, main= "mietekalt rent Berlin PC order")

# 3) Eigenvector Plot
?cor
corrgram( rentdf, order= TRUE, upper.panel= panel.cor, main= "mietekalt rent Berlin PC order")
rent_corr_test <- cor(rentdf, use = 'pair')
rent_corr_eigen <- eigen(rent_corr_test)$vectors[,1:2]
e1 <- rent_corr_eigen[,1]
e2 <- rent_corr_eigen[,2]

plot(e1,e2, col='white', xlim=range(e1,e2), ylim=range(e1,e2))
text(e1,e2, rownames(rent_corr_test), cex=1)
title("EigenvectorPlot of Rent_corrr_Test")
arrows(0, 0, e1, e2, cex=0.5, col="red", length=0.1)


#########################################################################################################
#########################################################################################################

## with qmmiete Included
cols_qm <- c("qmmiete", "mietekalt", "singlefam", "ls", "no_jobs_div100k", "no_sut_lines", "inc4", "wohnflaech", "bjahr", "gbgroesse", "zimmeranza_num",
          "avgincome", "green_tvz_surround", "prop_green_tvz", "pop_dens", "prop_migr", "gc_car", "co_groc_foot", "highw_avg_tt_pass")

rentdf_qm <- df[,cols_qm]

## checking for the no of NAs in the df
sapply(rentdf_qm, function(x) sum(is.na(x)))

## corrs
rent_corr_qm <- cor(rentdf_qm, use = "complete.obs")
summary(rent_corr_qm)
plot(rent_corr_qm)



### plotting w/ corrgrams 

# 1a) with all numeric vars:
corrgram( rent_corr_qm, main= "rent Berlin PC order")

# 1b) with all numeric vars ordered yb principal components :
corrgram( rent_corr_qm, order= TRUE, main= "rent Berlin PC order")

# 2) split in shading and values
corrgram( rent_corr_qm, order= TRUE, upper.panel= panel.cor, main= "qmmiete rent Berlin PC order")

# 3) Eigenvector Plot

corrgram( rentdf_qm, order= TRUE, upper.panel= panel.cor, main= "qmmiete rent Berlin PC order")
rent_corr_qm_test <- cor(rentdf_qm, use = 'pair')
rent_corr_qm_eigen <- eigen(rent_corr_qm_test)$vectors[,1:2]
e1_qm <- rent_corr_qm_eigen[,1]
e2_qm <- rent_corr_qm_eigen[,2]

plot(e1_qm, e2_qm, col='white', xlim=range(e1_qm,e2_qm), ylim=range(e1_qm,e2_qm))
text(e1_qm, e2_qm, rownames(rent_corr_qm_test), cex=1)
title("EigenvectorPlot of Rent_corrr_qm_Test")
arrows(0, 0, e1_qm, e2_qm, cex=0.5, col="red", length=0.1)



################
#####  CORRELATIONs are fine, now to the multiple linear regression aka lm()
###########

## from above, data to work with is rentdf_qm; containing all cols listed above incl. qmmiete
## first lm steps mietekalt ~ wohnflaech
MK_1 <- lm(mietekalt~wohnflaech, rentdf_qm)
summary(MK_1)
plot(MK_1)

#### check for id: 56568 & 60034 aka bigFat Outliers
rentdf_qm[56568, ]
rentdf_qm[60034, ]

### see how it looks if both are removed
rdf <- rentdf_qm[c(-60034, -56568),]
rdf[60034,]
rdf[56569,]  ## removal succeful

## now checking
MK_1_b <- lm(mietekalt~wohnflaech, rdf)
summary(MK_1_b)
plot(MK_1_b)

## checking the last offender 56563
rdf[56563,]   ## the same as 60034 removed earlier....
rdf <- rdf[-56563,]  ## removing & running seq from above again

### the Residual vs leverage plot looks much better after removing the three (2 distinct entries)
## the model itself says its valid, though it makes no sense
## it says that kaltmiete for 15sqm is -50 o.0  but also only 71% are explainable with this model carry on

#### Running all the same for qmmiete vs wohnflache
QM_1 <- lm(qmmiete~wohnflaech, rentdf_qm)
summary(QM_1)
plot(QM_1)

## R² 0,043 what a surprise that area cant explain €/area, though res/lev plot
## again shows a couple of outliers incl the above removes 60034
## the same model w/ the rdf df - removed outliers

QM_1_b <- lm(qmmiete~wohnflaech, rdf)
summary(QM_1_b)
plot(QM_1_b)             ## res/Lev plot looking better overall model quality didnt change

########
######## Now doing both for the ls terms, working with the rdf (3 values removed)
########

KM_2 <- lm(mietekalt ~ ls, rdf)    #### definetly not enough R² 0,248  but model is signif. and doesnt present 
summary(KM_2)                      #### any outrageouse data-problems
plot(KM_2)

### hm, do 56567 and 56566 make sense at all?
rdf[56567,]
rdf[56565,]  ### probably "faulty" data since 46566 and 56567 are identical 
             ##  and qmmiete of 18 seems excessive, but could be a plausible offering

### running ls vs qmmiete
QM_2 <- lm(qmmiete ~ ls, rdf)
summary(QM_2)                    ### data seems fine, though model doesnt say anyyyyything with ls
plot(QM_2)                       ### what was already indicated by the correlaltion matrice  ls <> qmmiete  -0,01

###### Overall not a good-day for the logsums :(

#####################
##########
##########  Building the KM-model steps by step without much commenting based on rdf dataset
#####################

KM_3 <- lm(mietekalt ~ ls + wohnflaech , rdf)
summary(KM_3)
plot(KM_3)
##
KM_4 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines , rdf)
summary(KM_4)
plot(KM_4)
##
KM_5 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k , rdf)
summary(KM_5)
plot(KM_5)
##
KM_6 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 , rdf)
summary(KM_6)
plot(KM_6)
##
KM_7 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car , rdf)
summary(KM_7)
plot(KM_7)
##
KM_8 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr , rdf)
summary(KM_8)
plot(KM_8)
##
KM_9 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround , rdf)
summary(KM_9)
plot(KM_9)
##
KM_10 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse , rdf)
summary(KM_10)
plot(KM_10)
## 
KM_all <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse 
                   + singlefam + bjahr + zimmeranza_num + pop_dens + co_groc_foot + highw_avg_tt_pass, rdf)
summary(KM_all)
plot(KM_all)

### testing MK_10 without the wohnflaech, as it has clearly the most influence R² before 0.772
KM_11 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse , rdf)
summary(KM_11)
plot(KM_11)

### --> R² no down to 0.462 and ls the most important factor, but it still includes dwelling size



#### Overall worse than KM_10  R² stops at ~ 0,77

#####################
##########
##########  Building the QM-model steps by step without much commenting based on rdf dataset
#####################

QM_3 <- lm(qmmiete ~ ls + wohnflaech , rdf)
summary(QM_3)
plot(QM_3)
##
QM_4 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines , rdf)
summary(QM_4)
plot(QM_4)
##
QM_5 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k , rdf)
summary(QM_5)
plot(QM_5)
##
QM_6 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 , rdf)
summary(QM_6)
plot(QM_6)
##
QM_7 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car , rdf)
summary(QM_7)
plot(QM_7)
##
QM_8 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr , rdf)
summary(QM_8)
plot(QM_8)
##
QM_9 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround , rdf)
summary(QM_9)
plot(QM_9)
##
QM_10 <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse , rdf)
summary(QM_10)
plot(QM_10)
## 
QM_all <- lm(qmmiete ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse 
             + singlefam + bjahr + zimmeranza_num + pop_dens + co_groc_foot + highw_avg_tt_pass, rdf)
summary(QM_all)
plot(QM_all)

#### removing the insignificant ls & wohnflaech
QM_11 <- lm(qmmiete ~ no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse , rdf)
summary(QM_11)
plot(QM_11)
