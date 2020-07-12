




wd <- "C:\\Users\\knappn\\Desktop\\Hackaton\\"
setwd(wd)


zip.vec <- list.files("ALKIS_KB58_shp", pattern=".zip")


for(i in 1:length(zip.vec)){
  #i=1
  my.zip <- zip.vec[i]
  unzip(paste0("ALKIS_KB58_shp\\", my.zip))
  print(i)
}


require(raster)
require(rgdal)

flurstueck.vec <- list.files(pattern="flurstueck.shp")

flurstueck.spdf <- readOGR(flurstueck.vec[1])
plot(flurstueck.spdf)

length(flurstueck.vec)

for(i in 2:length(flurstueck.vec)){
  #i=1
  new.flurstueck.spdf <- readOGR(flurstueck.vec[i])
  flurstueck.spdf <- rbind(flurstueck.spdf, new.flurstueck.spdf)
  print(i)
}

#plot(flurstueck.spdf)

writeOGR(flurstueck.spdf, dsn="all_merged2.shp", layer="all_merged", driver="ESRI Shapefile")



require(sf)

sf.list <- list()

flurstueck.vec <- list.files(pattern="flurstueck.shp")


for(i in 1:length(flurstueck.vec)){
  # i=1
  sf.list[[i]] <- read_sf(flurstueck.vec[i])
  print(i)
}


length(sf.list)
element.vec <- 1:length(sf.list)
element.vec <- element.vec[element.vec != 751]
new.sf.list <- sf.list
new.sf.list[[751]] <- NULL
new.sf.list[[1130]] <- NULL
new.sf.list[[2011]] <- NULL
length(new.sf.list)

merged.sf <- st_as_sf(data.table::rbindlist(new.sf.list))
#plot(st_geometry(test))
head(test)


st_write(merged.sf, dsn="merged2.shp", layers="merged2")





