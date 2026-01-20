library(sf)
library(terra)

aoi <- st_read("inst/extdata/aoi_10.gpkg")

# -------------------------------
# Process rasters
# -------------------------------

wsf <- download_wsf_data(aoi)
lc <- rast("inst/extdata/LC.tif")
dem <- rast("inst/extdata/DEM.tif")

raster_list <- list(
  DEM = dem,
  LC  = lc,
  WSF = wsf
)

out <- process_rasters(
  aoi         = aoi,
  target_epsg = 25832,
  resolution  = 10,
  rasters     = raster_list
)

# -------------------------------
# Process LOD2 building data
# -------------------------------

lod2_multipolygon <- st_read("inst/extdata/lod2_multipolygon.gpkg")

res <- process_lod2(buildings = lod2_multipolygon, aoi = aoi)

st_write(res$buildings,
         "inst/extdata/processed_buildings.gpkg",
         append=FALSE)
st_write(res$bridges,
         "inst/extdata/processed_bridges.gpkg",
         append=FALSE)

building_types <- assign_palm_building_type(
  buildings = res$buildings,
  wsf       = out$WSF
)
st_write(building_types,
         "inst/extdata/building_types.gpkg",
         append=FALSE)

# Rasterize building properties for PALM
building_rasters <- rasterize_buildings_palm(
  buildings = building_types,
  template  = out$DEM
)

# Check results
plot(building_rasters$type)
plot(building_rasters$id)
plot(building_rasters$height)

# Rasterize bridge properties for PALM
bridge_rasters <- rasterize_bridges_palm(
  bridges   = res$bridges,
  template  = out$DEM
)

# Check results
plot(bridge_rasters$id)
plot(bridge_rasters$height)
