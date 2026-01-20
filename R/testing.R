# library(sf)
# library(terra)

# aoi <- st_read("inst/extdata/aoi_10.gpkg")

# # -------------------------------
# # Process rasters
# # -------------------------------

# wsf <- download_wsf_data(aoi)
# lc <- rast("inst/extdata/LC.tif")
# dem <- rast("inst/extdata/DEM.tif")

# raster_list <- list(
#   DEM = dem,
#   LC  = lc,
#   WSF = wsf
# )

# out <- process_rasters(
#   aoi         = aoi,
#   target_epsg = 25832,
#   resolution  = 10,
#   rasters     = raster_list
# )

# # Reclassify LC to PALM surface types
# lc_surfaces <- reclassify_lc_to_palm(out$LC)

# # Check results
# plot(lc_surfaces$vegetation)
# plot(lc_surfaces$water)
# plot(lc_surfaces$pavement)

# # -------------------------------
# # Process LOD2 building data
# # -------------------------------

# lod2_multipolygon <- st_read("inst/extdata/lod2_multipolygon.gpkg")

# res <- process_lod2(buildings = lod2_multipolygon, aoi = aoi)

# st_write(res$buildings,
#          "inst/extdata/processed_buildings.gpkg",
#          append=FALSE)
# st_write(res$bridges,
#          "inst/extdata/processed_bridges.gpkg",
#          append=FALSE)

# building_types <- assign_palm_building_type(
#   buildings = res$buildings,
#   wsf       = out$WSF
# )
# st_write(building_types,
#          "inst/extdata/building_types.gpkg",
#          append=FALSE)

# # Rasterize building properties for PALM
# building_rasters <- rasterize_buildings_palm(
#   buildings = building_types,
#   template  = out$DEM
# )

# # Check results
# plot(building_rasters$type)
# plot(building_rasters$id)
# plot(building_rasters$height)

# # Rasterize bridge properties for PALM
# bridge_rasters <- rasterize_bridges_palm(
#   bridges   = res$bridges,
#   template  = out$DEM
# )

# # Check results
# plot(bridge_rasters$id)
# plot(bridge_rasters$height)

# # ---------------------------------------------------------------
# # Export all processed rasters as GeoTIFF with PALM naming
# # ---------------------------------------------------------------

# output_dir <- "inst/extdata/processed_rasters"
# prefix <- "MUC"
# resolution <- 10

# # Base rasters
# base_rasters <- list(
#   DEM = out$DEM
# )

# export_to_palm(base_rasters, output_dir, paste0(prefix, "_base"), resolution)

# # LC surface type rasters
# lc_rasters <- list(
#   vegetation_type = lc_surfaces$vegetation,
#   water_type = lc_surfaces$water,
#   pavement_type = lc_surfaces$pavement
# )

# export_to_palm(lc_rasters, output_dir, paste0(prefix, "_lc"), resolution)

# # Building rasters
# building_export <- list(
#   building_type = building_rasters$type,
#   building_id = building_rasters$id,
#   building_height = building_rasters$height
# )

# export_to_palm(building_export, output_dir, prefix, resolution)

# # Bridge rasters
# bridge_export <- list(
#   bridge_id = bridge_rasters$id,
#   bridge_height = bridge_rasters$height
# )

# export_to_palm(bridge_export, output_dir, prefix, resolution)
