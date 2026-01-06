library(sf)
library(terra)

aoi <- st_read("inst/extdata/small_aoi.gpkg")
wsf <- download_wsf_data(aoi)
lc <- rast("inst/extdata/LC.tif")
dem <- rast("inst/extdata/DEM.tif")
lod2 <- st_read("inst/extdata/lod2.gpkg")

raster_list <- list(
  DEM = dem,
  LC  = lc,
  WSF = wsf
)

out <- process_rasters(
  aoi         = aoi,
  target_epsg = 25832,
  resolution  = 100,
  rasters     = raster_list
)

res <- process_lod2(
  buildings = lod2,
  aoi       = aoi
  )
