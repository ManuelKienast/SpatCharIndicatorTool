###
##### aPipeDream
###   calls the win cmd prompt and tells pg_dump to send a table from one db to another



### set the wd to the folder containing the pg_dump file, neccessary b/c of conflicts in "program files" blank space.
setwd("C:\\Program Files\\PostgreSQL\\9.4\\bin")



####Pipe remote-db <> local-db

## pipe the table -t [table.name.2copy] from public.[remote.db-name] to local db
system("cmd.exe", input = "pg_dump.exe -h [remote-server.ip] -U [user.name]  -t [table.name.2copy] [remote.db-name] | psql -h localhost -U postgres [local.db-name] ")

## pipe from local 2 [remote.db-name]
system("cmd.exe", input = "pg_dump.exe  -U postgres -h localhost -t [table.name.2copy] [local.db-name] | psql -h [remote-server.ip] -p [remote.port] -U [user.name]  [remote.db-name]")

## pipe schema from local 2 urmo
system("cmd.exe", input = "pg_dump.exe  -U postgres -h localhost -n sumo_traffic urmo_locale | psql -h [remote-server.ip] -U [user.name]  urmo")





##
#### Copy * from one table in a schema into a different table in the same db, created on the fly
##
copyTable <- function( con,
                       tableName, copyFromSchema, copy2Schema
                       )
{
  copyTable <- dbGetQuery(connection, sprintf(
    "
    SELECT *
    INTO %s.%s
    FROM %s.%s
    ;"
    ,
    copy2Schema, tableName,
    copyFromSchema, tableName
  ))
}

##USAGE copy table
copyTable(con, "sumotraffic_fish_1000", "public", "sumo_traffic")

##USAGE copy list of tables
copyList <- c("sumotraffic_fish_500", "sumotraffic_fish_2000", "sumotraffic_fish_4000", "sumotraffic_hex500", "sumotraffic_hex1000", "sumotraffic_hex2000", "sumotraffic_hex4000")
for (i in copyList) copyTable(con, i, "public", "sumo_traffic")




###PLAYGROUND:
##
#system("cmd.exe", input = "C:\\Temp\\firefox\\firefox.exe http://www.spiegel.de/")
#
# system("(sprintf("cmd.%s", "exe"))", input = "(sprintf("note%s", "pad"))")
# 
# system(sprintf("paste(" cmd.exe ", ""), input = paste(" notepad ", "")")
# 
#        
#        ## For inputs of length 1, use the sep argument rather than collapse
#        paste("1st", "2nd", "3rd", collapse = ", ") # probably not what you wanted
#        paste("1st", "2nd", "3rd", sep = ", ")
#        paste("sprintf("this1st%s", "test")", "2nd", "3rd")
# 
# sprintf("%.0f%% said yes (out of a sample of size %.0f)", 66.666, 3)
# 
# xx <- sprintf("%1$d %1$x %1$X", 0:15)
# 
# sprintf("min 10-char string '%10s'",
#         c("a", "ABC", "and an even longer one"))
# 
# x <- seq(0, 2 * pi, length = 100)
# 
# paste("A", 1, "%")       #A bunch of individual character strings.
# paste(1:4, letters[1:4]) #2 or more vectors pasted element for element.
# paste(1:10)              #One vector smushed together.
# paste("a", "b", sep="")
# ?system
# ?shQuote
# tryit <- paste("use the", sQuote("-c"), "switch\nlike this")
# cat(shQuote(tryit), "\n")
# cat(shQuote(tryit, type = "csh"), "\n")
# ?cat
# 
# test <- "abc$def`gh`i\\j"
# cat(shQuote(test), "\n")