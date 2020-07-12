



wd <- "C:\\Users\\knappn\\Desktop\\Hackaton\\"
setwd(wd)

require(raster)
require(sf)

lc.ras <- raster("APiC_Agricultural-Land-Cover-Germany_RSE-2020\\preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif")

merged.sf <- read_sf("merged2.shp")

head(merged.sf)

(lc.proj <- crs(lc.ras))
(merged.proj <- crs(merged.sf))

merged.ext <- extent(merged.sf)
# Coerce to a SpatialPolygons object
merged.ext.sp <- as(merged.ext, 'SpatialPolygons') 
plot(merged.ext.sp)
# Reproject extent
merged.ext.geo.sp <- spTransform(merged.ext.sp, CRS=CRS(lc.proj))


CRS(lc.proj)

CRS(merged.proj)


# Read the reprojected lc map from QGIS
lc.utm.ras <- raster("APiC_Agricultural-Land-Cover-Germany_RSE-2020\\preidl-etal-RSE-2020_land-cover-classification-germany-2016_utm32n.tif")

# Crop AOI
lc.aoi.utm.ras <- crop(lc.utm.ras, merged.ext.sp)
plot(lc.aoi.utm.ras)

# Raster extraction
require(exactextractr)

merged2.sf <- cbind(merged.sf, LandCover=exact_extract(lc.aoi.utm.ras, merged.sf, c('majority')))
head(merged2.sf)

require(data.table)
lc.encoding.dt <- fread("APiC_Agricultural-Land-Cover-Germany_RSE-2020\\LandCoverEncoding.csv")


merged3.sf <- merge(merged2.sf, lc.encoding.dt, all.x=T, by.x="LandCover", by.y="LandCoverCode")
head(merged3.sf)


st_write(merged3.sf, dsn="merged3.shp", layers="merged3")

st_write(merged3.sf, dsn="merged3.shp", layers="merged3")

# Export AOI as shp
crs(merged.ext.sp) <- merged.proj
merged.ext.sf <- st_as_sf(merged.ext.sp)
st_write(merged.ext.sf, dsn="aoi.shp", layers="aoi", overwrite=T, append=F)


# Read road network from kml
road.net.sf <- read_sf("OSM\\highway_lines.kml")
head(road.net.sf)
nrow(road.net.sf)

plot(st_geometry(road.net.sf))

crs(road.net.sf)
road.net.sf <- st_transform(road.net.sf, crs=merged.proj)
crs(road.net.sf)

write_sf(road.net.sf, "OSM\\highway_lines_R.shp", overwrite=T, append=F)


# Rasterize parcels for biodiv indices
require(fasterize)
require(viridis)

merged3.sf <- read_sf("merged3.shp")
template.ras <- raster(merged3.sf, res=20)
names(merged3.sf)
head(merged3.sf)
nrow(merged3.sf)
lc.parcels.ras <- fasterize(merged3.sf, raster=template.ras, field="LandCvr")
crs(lc.parcels.ras) <- merged.proj

plot(lc.parcels.ras, col=viridis(23))
zoom(lc.parcels.ras, col=viridis(23))

writeRaster(lc.parcels.ras, "LandCoverParcelsFasterized.tif", overwrite=T)

# lc.parcels.ras <- raster("LandCoverParcelsFasterized.tif")



getwd()

head(merged3.sf)


parcels.sf <- merged3.sf


# Assign yield conversion factors
yield.fac.dt <- fread("MethaneYieldPerCrop.csv")
head(yield.fac.dt)
yield.fac.dt[, MeanMethanePerHa := (MinMethanePerHa+MaxMethanePerHa)/2]

names(parcels.sf)
parcels.sf <- merge(parcels.sf, yield.fac.dt, all.x=T, by.x="LndCvrT", by.y="InputType")
head(parcels.sf)


parcels.sf$MethaneYield <- parcels.sf$MeanMethanePerHa*parcels.sf$flaeche/10000

plot(st_geometry(parcels.sf))

crs(parcels.sf)
write_sf(parcels.sf, "ParcelsWithInfo.shp")


# Calculate total yield in biogas catchment area

# Read example points
points.sf <- read_sf("OSM\\path_points.shp")

plot(st_geometry(points.sf), add=T, col="red", cex=1, pch=16)

biogas.plant.sf <- points.sf[1, ]
biogas.plant.ext <- extent(biogas.plant.sf)
ext.distance <- 10000
biogas.catchment.ext <- extent(biogas.plant.ext[1]-ext.distance,
                               biogas.plant.ext[2]+ext.distance,
                               biogas.plant.ext[3]-ext.distance,
                               biogas.plant.ext[4]+ext.distance)
# Coerce to a SpatialPolygons object
biogas.catchment.sp <- as(biogas.catchment.ext, 'SpatialPolygons') 
biogas.catchment.sf <- st_as_sf(biogas.catchment.sp)

biogas.catchment.sf <- st_set_crs(biogas.catchment.sf, value=merged.proj)

# plot(st_geometry(biogas.catchment.sf), add=T, border="blue")
plot(st_geometry(biogas.catchment.sf), border="blue")
plot(st_geometry(points.sf), add=T, col="red", pch=16)

crs(biogas.catchment.sf)
crs(parcels.sf)

biogas.catchment.sf <- st_set_crs(biogas.catchment.sf, value=merged.proj)
parcels.sf <- st_set_crs(parcels.sf, value=merged.proj)

st_crs(biogas.catchment.sf)
st_crs(parcels.sf)

aoi.parcels.sf <- st_crop(parcels.sf, biogas.catchment.sf)
crs(aoi.parcels.sf)
st_crs(aoi.parcels.sf)

plot(st_geometry(aoi.parcels.sf), add=T, border="red")
plot(st_geometry(aoi.parcels.sf))
# plot(st_geometry(parcels.sf))



# Simulate selected parcels
aoi.parcels.sf
head(aoi.parcels.sf)

plot(st_geometry(aoi.parcels.sf), border="red")

nrow(aoi.parcels.sf)

aoi.parcels.dt <- data.table(aoi.parcels.sf)


energy.crops <- c("Maize", "Sugar Beets", "Winter Wheat")
more.energy.crops <- c("Maize", "Sugar Beets", "Winter Wheat", "Spelt", "Winter Barley", "Spring Oat", "Grassland")
aoi.parcels.dt[, Selected := F]
aoi.parcels.dt[LndCvrT %in% energy.crops, Selected := ifelse(runif(.N) > 0.5, 1, 0)]

aoi.parcels.sf$Selected <- aoi.parcels.dt$Selected
selected.parcels.sf <- subset(aoi.parcels.sf, Selected==T)

plot(st_geometry(aoi.parcels.sf), border="red")
plot(st_geometry(selected.parcels.sf), border="red", col="black", add=T)


aoi.parcels.dt[Selected == T, Crops1 := LndCvrT]
aoi.parcels.dt[Selected == T, Crops2 := "Maize"]
aoi.parcels.dt[Selected == T, Crops3 := sample(more.energy.crops, .N, replace = T)]


head(lc.encoding.dt)

lc.encoding.dt.copy <- copy(lc.encoding.dt)
setnames(lc.encoding.dt.copy, old="LandCoverCode", new="Crops1Code")
aoi.parcels.dt <- merge(aoi.parcels.dt, lc.encoding.dt.copy, all.x=T, by.x="Crops1", by.y="LandCoverType")
setnames(lc.encoding.dt.copy, old="Crops1Code", new="Crops2Code")
aoi.parcels.dt <- merge(aoi.parcels.dt, lc.encoding.dt.copy, all.x=T, by.x="Crops2", by.y="LandCoverType")
setnames(lc.encoding.dt.copy, old="Crops2Code", new="Crops3Code")
aoi.parcels.dt <- merge(aoi.parcels.dt, lc.encoding.dt.copy, all.x=T, by.x="Crops3", by.y="LandCoverType")


aoi.parcels.sf$Crops1 <- aoi.parcels.dt$Crops1 
aoi.parcels.sf$Crops2 <- aoi.parcels.dt$Crops2 
aoi.parcels.sf$Crops3 <- aoi.parcels.dt$Crops3 
aoi.parcels.sf$Crops1Code <- aoi.parcels.dt$Crops1Code
aoi.parcels.sf$Crops2Code <- aoi.parcels.dt$Crops2Code 
aoi.parcels.sf$Crops3Code <- aoi.parcels.dt$Crops3Code 

library(mapview)
mapview(aoi.parcels.sf)


write_sf(aoi.parcels.sf, "AOIParcelsWithInfo.shp")









