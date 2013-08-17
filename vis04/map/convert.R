# Converts a shapefile to a CSV file
library(maptools)

setwd("/Users/mongo/Documents/code/Processing/casa/vis04/map/")
map <- readShapePoly("london_map2.shp")

ids <- c()
x <- c()
y <- c()

for (a in 1:length(map@polygons)) {
  id <- a
  p <- map@polygons[[a]]@Polygons
  c <- p[[1]]@coords
  for (b in 1:length(c[,1])) {
    ids <- c(ids, id)
    x <- c(x, c[[b, 1]])
    y <- c(y, c[[b, 2]])
  }
}

d <- data.frame(id=ids, name=map$name[ids], lat=y, lon=x)
write.csv(d, file="boroughs.csv", quote=FALSE, row.names=FALSE)
