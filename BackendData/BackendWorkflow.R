# Energy landscape optimizer

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
parcels.sf <- read_sf("ParcelsWithInfo.shp")

# Extract the coordinate reference system information
crs.obj <- crs(parcels.sf)

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
biogas.catchment.sf <- st_set_crs(biogas.catchment.sf, value=crs.obj)

# Crop the parcels with the AOI 
# ToDo: Do an intersection which does not cut through the parcels, to 
# make accurate area-based yield calculations
suppressWarnings(aoi.parcels.sf <- st_crop(parcels.sf, biogas.catchment.sf))

# Sum up the yield (Nm3 of methane, which can be produced by all parcels)
(total.energy.sum <- sum(aoi.parcels.sf$MthnYld, na.rm=T))

# Rasterize the landcover classes
suppressWarnings(template.ras <- raster(aoi.parcels.sf, res=20))
crs(template.ras) <- crs.obj
aoi.landcover.ras <- fasterize(st_collection_extract(aoi.parcels.sf, "POLYGON"), 
                               raster=template.ras, field="LandCvr")
crs(aoi.landcover.ras) <- crs.obj

# ToDo: Calculate the landscape metrics

















