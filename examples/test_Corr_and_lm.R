### playing with statistics and the rent dataset
### cor and lm and summary(lm)

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
