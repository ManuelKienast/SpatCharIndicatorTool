library(dismo)
library(dplyr)
library(tidyr)
library(RPostgreSQL)
library(data.table)
library(caret)
library(plyr)
library(rpart.plot)

library(plotly)

col <- "trips_br"
idField <- "plr_id"

connection <- dbConnect(dbDriver("PostgreSQL"), 
                        host = "localhost", 
                        port = 5432, 
                        user = "postgres", 
                        password = "postgres", 
                        dbname = "urmo")

queryString = paste("SET search_path TO ", "befragung", "")
dbGetQuery(connection, queryString)

df<-dbGetQuery(connection,'SELECT * FROM befragung.plr_data')

colNum <- match(col,names(df))


df <- subset(df, df[colNum]>0)
data <-df %>% filter(n>50)%>% filter(plr_id!=10030727) %>%
  dplyr::select(
    -starts_with("flt"),
    -starts_with("st"),
    -starts_with("clus"),
    -starts_with("trips"),
    -oev_karte,
    -mmr,
    -imr,
    -fs_pkw,
    -fs_pkw,
    -fs_mrad,
    -immobil,
    -n,
    -immobil,
    -gid,
    -bz_id,
    -bzr_id,
    -prg_id,
    -sqkm,
    -simpson_trips,
    -shannon_trips
  )%>%
  na.omit



colNum <- match(col,names(df))
#print(sort(data[,colNum]))

#print(sort(data[,colNum]))

colNumId <- match(idField,names(df))

data <- dplyr:: left_join(data, df[,c(colNum,colNumId)], by=idField)


colNum <- match(col,names(data))
colNumId <- match(idField,names(data))

row.names(data) <- data[,colNumId]
data$train_param <- data[colNum]


inTrain <- createDataPartition(y=data[,colNum],
                               p=.75,
                               list=FALSE)

training <- data[ inTrain,]
testing  <- data[-inTrain,]



res <- gbm.step(data=training, gbm.x=8:(colNum-1), gbm.y = colNum, family = "gaussian", tree.complexity = 5, learing.rate = 0.01, bag.fraction = 0.5)
names(res)
summary(res)
gbm.plot(res)
#interactions <- gbm.interactions(res)
#interactions$rank.list
library(gbm)
preds <- predict.gbm(res, testing, n.trees=res$gbm.call$best.trees, type="response")

colNum <- match(col,names(testing))

testing$train_param <- testing[,colNum]
calc.deviance(obs=testing$train_param, pred=preds, calc.mean = TRUE)
testing$preds <- preds

testing <- testing[with(testing, order(train_param)),]




#pal <- c("red", "blue", "green")
#p <- ggplot(testing, aes(x=plr_id, y=testing$trips_ppr))+geom_point()+geom_point(aes(x = testing$plr_id, y= testing$preds, colour= "red"))
#p
#p <- plot_ly(testing, x=~plr_id, y = ~trips_pr)
#add_markers(p, color =~cluster_m08, colors= pal)
#plot(testing$trips, testing$preds)
#plot(testing$preds, col=plot_colors[1])


plot_colors <- c("red","green")
plot(testing[,colNum], type="o", col=plot_colors[1])
lines(testing$preds, type="o", col=plot_colors[2])

testing_1 <-testing %>% 
  dplyr::select(preds,
                train_param)
#testing$trips_ppr

testing$dev<- abs(testing$train_param-testing$preds)
print (mean(testing$dev))