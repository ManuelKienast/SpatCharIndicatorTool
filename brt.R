library(dismo)
library(dplyr)
library(tidyr)
library(RPostgreSQL)
library(data.table)
library(caret)
library(plyr)
library(rpart.plot)




wd = "D:\\Simon\\Daten\\Berlin\\UrMo-Befragung\\Klassifikation"


connection <- dbConnect(dbDriver("PostgreSQL"), 
                        host = "localhost", 
                        port = 5432, 
                        user = "postgres", 
                        password = "postgres", 
                        dbname = "urmo")

queryString = paste("SET search_path TO ", "befragung", "")
dbGetQuery(connection, queryString)

df<-dbGetQuery(connection,'SELECT * FROM befragung.plr_data')
data <-df %>% 
  dplyr::select(
    -starts_with("flt"),
    -starts_with("st"),
    -trips_cr,
    -trips_br,
    -trips_wr,
    -trips_mr,
    -oev_karte,
    -trips_cpr,
    -trips_sr,
    -n,
    -immobil
    )%>%
  na.omit


inTrain <- createDataPartition(y=data$trips_pr,
                               p=.75,
                               list=FALSE)

training <- data[ inTrain,]
testing  <- data[-inTrain,]



res <- gbm.step(data=training, gbm.x=c(8:51,53:100), gbm.y = 52, family = "gaussian", tree.complexity = 5, learing.rate = 0.01, bag.fraction = 0.5)
names(res)
summary(res)
gbm.plot(res)
interactions <- gbm.interactions(res)
interactions$rank.list
library(gbm)
preds <- predict.gbm(res, testing, n.trees=res$gbm.call$best.trees, type="response")
calc.deviance(obs=testing$trips_pr,pred=preds, calc.mean = TRUE)
d<- as.data.frame(d<-cbind(testing$trips_pr,preds))

d$dev<- abs(d[,1]-d[,2])
print (mean(d$dev))

