library(sf)
library(terra)

aoi <- st_read("inst/extdata/small_aoi.gpkg")
wsf <- download_wsf_data(aoi)
lc <- rast("inst/extdata/LC.tif")
dem <- rast("inst/extdata/DEM.tif")

rasters <- list(
  DEM = dem,
  LC  = lc,
  WSF = wsf
)

out <- process_raster_files(
  aoi         = aoi,
  target_epsg = 25832,
  resolution  = 100,
  rasters     = rasters
)
