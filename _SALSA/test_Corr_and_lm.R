### playing with statistics and the rent dataset
### cor and lm and summary(lm)

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
arrows(0, 0, e1, e2, cex=0.5, col="blue", length=0.1)


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
rdf[56569,]  ## removal successful

## now re-checking
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
rdf[56566,]  ### probably "faulty" data since 46566 and 56567 are identical 
             ##  and qmmiete of 18 seems excessive, but could be a plausible offering
## removing them anyways...
rdf <- rdf[-56567,]
rdf <- rdf[-56566,]


### running ls vs qmmiete
QM_2 <- lm(qmmiete ~ ls, rdf)
summary(QM_2)                    ### data seems fine, though model doesnt say anyyyyything with ls
plot(QM_2)                       ### which was already indicated by the correlation matrice  ls <> qmmiete  -0,01


###### Overall not a good-day for the logsums :(

#####################
##########
##########  Building the KM-model steps by step without much commenting based on rdf dataset
#####################

KM_1 <- lm(mietekalt~wohnflaech, rdf)
summary(KM_1)
plot(KM_1)

KM_2 <- lm(mietekalt ~ ls, rdf)    #### definetly not enough R² 0,248  but model is signif. and doesnt present 
summary(KM_2)                      #### any outrageouse data-problems
plot(KM_2)

KM_3 <- lm(mietekalt ~ ls + wohnflaech , rdf)
summary(KM_3)
plot(KM_3)
##
KM_4 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines , rdf)
summary(KM_4)
plot(KM_4)
##
KM_4_b <- lm(mietekalt ~ ls + no_sut_lines , rdf)
summary(KM_4_b)
plot(KM_4_b)
##
KM_5 <- lm(mietekalt ~ ls + wohnflaech + no_sut_lines + no_jobs_div100k , rdf)
summary(KM_5)
plot(KM_5)           #### remove: 56538, 55417, 59187, 55411, 55421
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

### IF the wohnflaech is removed form teh equation the logsum starts making sense, so wohn
### will be disregarded, it is still however included in the logsum-term

KM_2 <- lm(mietekalt ~ ls, rdf)    #### definetly not enough R² 0,248  but model is signif. and doesnt present 
summary(KM_2)                      #### any outrageouse data-problems
plot(KM_2)
##
KM_4 <- lm(mietekalt ~ ls + no_sut_lines , rdf)
summary(KM_4)
plot(KM_4)
##
KM_5 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k , rdf)
summary(KM_5)
plot(KM_5) 
##
KM_5_b <- lm(mietekalt ~ ls + no_sut_lines + inc4 , rdf)
summary(KM_6)
plot(KM_6) 
##
KM_5_c <- lm(mietekalt ~ ls + no_sut_lines + gc_car , rdf)
summary(KM_5_c)
plot(KM_5_c) 
##
KM_5_d <- lm(mietekalt ~ ls + green_tvz_surround + gc_car , rdf)
summary(KM_5_d)
plot(KM_5_d) 
##
### this is interesting, either 5 or 5_b increases R by ~0.1 though adding both doesnt
### increase R at all
##
KM_6 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 , rdf)
summary(KM_6)
plot(KM_6)
##
KM_7 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 + gc_car , rdf)
summary(KM_7)
plot(KM_7)
##
KM_8 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr , rdf)
summary(KM_8)
plot(KM_8)
##
KM_9 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround, rdf)
summary(KM_9)
plot(KM_9)
##
KM_10 <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse , rdf)
summary(KM_10)
plot(KM_10)
## 
KM_all <- lm(mietekalt ~ ls + no_sut_lines + no_jobs_div100k + inc4 + gc_car + prop_migr + green_tvz_surround + gbgroesse 
             + singlefam + bjahr + zimmeranza_num + pop_dens + co_groc_foot + highw_avg_tt_pass, rdf)
## or KM_all <- lm(mietekalt ~ ., rdf)
summary(KM_all)
plot(KM_all)

KM_all <- lm(mietekalt ~ .-1, rdf)

anova(KM_all)


summary(rdf$co_groc_foot)

##### rough estimate of the influence of each Value on the eq median (in brackets)
## ls(14)*180 = 2500
## no_sut(11) *6,2 = 68,8
## no_job(2.6) *100 = 260
## inc4(0.24) *320 = 77
## gc - no confidence
## prop_mig(0.15) *-276 = -41
## green(0.07) *-219 = -15
## gbgroe(12) *-6,5 = -78
## singlefam - no confid
## bjahr(3) *6,9 = 20,7
## zimmer#(2) *3,2 = 6,4
## popdens - low confi & low inpact
## co_groc_foot(3663) *0,0045 = 16,5
## highw - low confid
## 
?lm

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


###############
#####
####  script updates from Benj w/ problematic-unpredictable rents
##########
plot(rdf$ls,rdf$mietekalt)

### ls cannot predict some of high income
### zoom in values at lower end
plot(rdf$ls[rdf$ls<13],rdf$mietekalt[rdf$ls<13])
plot(rdf$ls[rdf$ls<13 & rdf$mietekalt>2000],rdf$mietekalt[rdf$ls<13 & rdf$mietekalt>2000])
strange <- rdf[rdf$ls<13 & rdf$mietekalt>3600,]  ##was mietekalt>3600
strange
plot(strange$ls, strange$mietekalt)

testrdf <- rdf[!rdf$ls<13 & !rdf$mietekalt>3600,]  ##was mietekalt>3600 and removes entries
plot(rdf$ls, rdf$mietekalt)
plot(testrdf$ls, testrdf$mietekalt)

## so create new rdf w/ those values from above removed
rdf <- rdf[!rdf$ls<13 & !rdf$mietekalt>3600,]
plot <- plot(rdf$ls, rdf$mietekalt)
  

###############
#####
####  testing pca (principle component analysis | pcr- ~regression)
###   based upon chap.5 D.B.Wright & K.London Modern Regression techniquers Using R
##########
## prepping
install.packages("pls")
library(pls)
??pls

## remove all na entries from rdf:
str(rdf)
rdf1 <- rdf[complete.cases(rdf),]
str(rdf1)


km <- rdf$mietekalt
preds <- subset(rdf, select=-mietekalt)
str(preds)
str(km)     ### excellent still both contain 59496 obs.

## subsetting reducing the dataframe
predT <- subset(preds, select=-wohnflaech)
names(predT)

predTls <- subset(predT, select=-ls)
names(predTls)

predTlsq <- subset(predTls, select=-qmmiete)
names(predTlsq)

predTlsqs <- subset(predTlsq, select= -singlefam)
names(predTlsqs)

## running code to eval and plot
pcr1 <- pcr(km ~ ., ncomp = 10, data = preds)
pcr12 <- pcr(mietekalt ~ ., ncomp = 18, data = rdf)



## score plot & the call for its vars
plot(pcr1, plottype = "scores", comps = 1:3)
explvar(pcr1)
compnames(pcr1, explvar = TRUE)
compnames(pcr1)

## testing with wohnflaech @pos7 removed 
pcrT <- pcr(km ~ ., ncomp = 16, data = predT)
compnames(pcrT, explvar = TRUE)
explvar(pcrT)

## testing with als removing ls 
pcrTls <- pcr(km ~ ., data = predTls)
compnames(pcrTls, explvar = TRUE)
explvar(pcrTls)

## testing with qmmiete also removed
pcrTlsq <- pcr(km ~ ., data = predTlsq)
compnames(pcrTlsq, explvar = TRUE)
explvar(pcrTlsq)

## testing with singlefam also removed
pcrTlsqs <- pcr(km ~ ., data = predTlsqs)
compnames(pcrTlsqs, explvar = TRUE)
explvar(pcrTlsqs)

?pcr
?prcomp
## Loading plot
plot(pcr1, "loadings", comps = 1:3, legendpos = "topleft", xlab = "nm")
abline(h = 0)
??pls


# str(pcr1)
# str(pcr12)
# plot(1:18, summary(pcr1) [3,], ylab = "Cumulative variance accounted for", xlab="No of comp",
# ylim=c(0,18), pch = 19, cex.lab=1.3)
# lines(1:18, summary(pcr1)[3,], lwd=1.5)
# points(1:18, summary(pcr1)[2,], pch=19)
# lines(1:18, summary(pcr1)[2,], lwd=1.5)
# summary(pcr1)
# str(summary(pcr12))
# 
# sumpcr12 <- summary(pcr12)
# sumpcr12[1,]

print(pcr1$projection, digits=3)
print(pcr1$scores[,1], digits=3)

# plot(1:18, sumpcr12[2,], ylab = "Cumulative variance accounted for", xlab="No of comp",
#      ylim=c(0,100), pch = 19, cex.lab=1.3)
# lines(1:18, sumpcr12[2,], lwd=1.5)
# points(1:18, summary(pcr12)[2,], pch=19)
# lines(1:18, summary(pcr12)[2,], lwd=1.5)   #### sadly no serious plot can be produced


###
### trying plsr analysis now
plsr1 <- plsr(km ~ ., ncomp = 10, data = preds)

plot(1:18, summary(plsr1)[1,], ylab = "Cumulative variance accounted for", xlab="No of comp",
     ylim=c(0,100), pch = 19, cex.lab=1.3)
lines(1:18, summary(pcr1)[1,], lwd=1.5)
points(1:18, summary(pcr1)[2,], pch=19)
lines(1:18, summary(pcr1)[2,], lwd=1.5)

str(plsr1$scores)
str(km)

plot(plsr1)
plot(pcr1)
plot(summary(pcr1),ylim=c(0,10000), xlim=c(0,2000))

summary(plsr1)
plsrg <- lm(rdf1$mietekalt ~ plsr1$scores[,6])
summary(plsrg)

str(summary(plsr1))

plot(plsrg, plottype = "coef", ncomp = 1:10, legendpos = "bottomleft", labels= "numbers")



## score plot & the call for its vars
plot(plsr1, plottype = "scores", comps = 1:3)
explvar(plsr1)

## Loading plot
plot(plsr1, "loadings", comps = 1:3, legendpos = "topleft", xlab = "nm")
abline(h = 0)


########
####### testing the plsr models above with standardization, i.e. scale = TRUE, division by sd
########
plsr2 <- plsr(km ~ ., ncomp = 18, data = preds, scale = TRUE)

## score plot & the call for its vars after standardization
plot(plsr2, plottype = "scores", comps = 1:3)
explvar(plsr2)
plsr2$terms
str(preds)

plsr3 <- plsr(km ~ wohnflaech+ls+singlefam+qmmiete, data = preds, scale = TRUE)
explvar(plsr3)
plot(plsr3, plottype = "scores", comps = 1:4)

plsr4 <- plsr(km ~ wohnflaech+ls+singlefam+qmmiete, data = preds)
explvar(plsr4)
plot(plsr4, plottype = "scores", comps = 1:4)



#### AIIIIIIIIIIIIIIIII

## plotting the coefficients
plot(plsr1, plottype = "coef", ncomp = 1:10, legendpos = "topright", xlab = "comp")




str(plsr2)
plsr1$scores
?lm
?prcomp
data(USArrests)
str(USArrests)
prcomp(USArrests, scale = TRUE)
prcomp(~ Murder + Assault + Rape, data = USArrests, scale = TRUE)
plot(prcomp(USArrests))
summary(prcomp(USArrests, scale = TRUE))
biplot(prcomp(USArrests, scale = TRUE))

pca.rdf1 <- prcomp(rdf1, scale = TRUE)
summary(pca.rdf1)
plot(pca.rdf1, type ="lines")
biplot(pca.rdf1, scale = 0)
pca.rdf1$rotation

pca.rdf1b <- prcomp(rdf1)
summary(pca.rdf1b)
plot(pca.rdf1b, type ="lines")

pca.rdf2 <- prcomp(rdf1, center = TRUE, scale = TRUE)
summary(pca.rdf2)
