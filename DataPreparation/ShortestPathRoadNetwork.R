require(igraph)
require(sf)
require(raster)
require(data.table)

# Read road network from kml
road.net.sf <- read_sf("OSM\\highway_lines_R.shp")
head(road.net.sf)
nrow(road.net.sf)

road.net.sf <- st_set_crs(road.net.sf, value=merged.proj)
head(road.net.sf)

plot(st_geometry(road.net.sf))

# Read example points
points.sf <- read_sf("OSM\\path_points.shp")

plot(st_geometry(points.sf), add=T, col="red", cex=1, pch=16)

crs(points.sf)
crs(road.net.sf)
















































