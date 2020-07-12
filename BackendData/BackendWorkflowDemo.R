# Energy landscape optimizer

# Choose a demo scenario
my.scenario <- 3

# Load packages
require(data.table)
require(raster)
require(rgdal)
require(sf)
require(fasterize)

# Set working directory
wd <- "C:\\Users\\knappn\\Desktop\\Hackaton\\BackendData\\"
setwd(wd)

# Load point data of the power plant
points.sf <- read_sf("path_points.shp")
# Select the first point, which is the power plant location 
# (later coming from the user)
biogas.plant.sf <- points.sf[1, ]

# Load parcel polygons
#parcels.sf <- read_sf("ParcelsWithInfo.shp")
parcels.sf <- read_sf("AOIParcelsWithInfo.shp")

# Extract the coordinate reference system information
crs.obj <- crs(parcels.sf)

# Load the lookup table for the landcover type encoding
lc.encoding.dt <- fread("LandCoverEncoding.csv")

# Load the lookup table for the methane yield per crop
yield.fac.dt <- fread("MethaneYieldPerCrop.csv")
yield.fac.dt[, MeanMethanePerHa := (MinMethanePerHa+MaxMethanePerHa)/2]

names(parcels.sf)
head(parcels.sf)

sel.sf <- subset(parcels.sf, Selected==T)

# Demo of 3 scenarios
selection.vec <- parcels.sf$Selected == T
if(my.scenario == 1){
  parcels.sf$LndCvrT[selection.vec] <- parcels.sf$Crops1[selection.vec]
}else if(my.scenario == 2){
  parcels.sf$LndCvrT[selection.vec] <- parcels.sf$Crops2[selection.vec]
}else if(my.scenario == 3){
  parcels.sf$LndCvrT[selection.vec] <- parcels.sf$Crops3[selection.vec]
}

# Generate area of interest (AOI) polygon based on distance
biogas.plant.ext <- extent(biogas.plant.sf)
ext.distance <- 2500
biogas.catchment.ext <- extent(biogas.plant.ext[1]-ext.distance,
                               biogas.plant.ext[2]+ext.distance,
                               biogas.plant.ext[3]-ext.distance,
                               biogas.plant.ext[4]+ext.distance)
# Coerce to a SpatialPolygons object and then to a sf object
biogas.catchment.sp <- as(biogas.catchment.ext, 'SpatialPolygons') 
biogas.catchment.sf <- st_as_sf(biogas.catchment.sp)
# Assign CRS
suppressWarnings(biogas.catchment.sf <- st_set_crs(biogas.catchment.sf, value=crs.obj))
suppressWarnings(parcels.sf <- st_set_crs(parcels.sf, value=crs.obj))

# Crop the parcels with the AOI 
# ToDo: Do an intersection which does not cut through the parcels, to 
# make accurate area-based yield calculations
suppressWarnings(aoi.parcels.sf <- st_crop(parcels.sf, biogas.catchment.sf))

# Assign the methane yield per ha based on crops
aoi.parcels.sf <- merge(aoi.parcels.sf, yield.fac.dt, all.x=T, by.x="LndCvrT", by.y="InputType")

# Multiply the yield per ha with the areas to get yield per parcel
aoi.parcels.sf$MethaneYield <- aoi.parcels.sf$MeanMethanePerHa*aoi.parcels.sf$flaeche/10000

# Subset selected parcels
selected.parcels.sf <- subset(aoi.parcels.sf, Selected==T)
str(selected.parcels.sf)

# Sum up the yield (Nm3 of methane, which can be produced by all parcels)
(total.energy.sum <- sum(selected.parcels.sf$MethaneYield, na.rm=T))

# Add landcover codes
aoi.parcels.sf <- merge(aoi.parcels.sf, lc.encoding.dt, all.x=T, by.x="LndCvrT", by.y="LandCoverType")

# Rasterize the landcover classes
suppressWarnings(template.ras <- raster(aoi.parcels.sf, res=20))
crs(template.ras) <- crs.obj
aoi.landcover.ras <- fasterize(st_collection_extract(aoi.parcels.sf, "POLYGON"), 
                               raster=template.ras, field="LandCoverCode")
crs(aoi.landcover.ras) <- crs.obj

# ToDo: Calculate the landscape metrics

# Produce raster files as output
if(my.scenario == 1){
  writeRaster(aoi.landcover.ras, "LandcoverRasterScenario1.tif", overwrite=T)
}else if(my.scenario == 2){
  writeRaster(aoi.landcover.ras, "LandcoverRasterScenario2.tif", overwrite=T)
}else if(my.scenario == 3){
  writeRaster(aoi.landcover.ras, "LandcoverRasterScenario3.tif", overwrite=T)
}















