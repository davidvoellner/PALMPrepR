# ===================================================================
# PALM-4U Static Driver Preparation Workflow
# ===================================================================
# Workflow to prepare static driver inputs for PALM urban
# climate simulation: raster processing, building classification,
# rasterization, and YAML configuration export.
# ===================================================================

library(sf)
library(terra)

# Load area of interest
aoi <- st_read("inst/extdata/aoi_10.gpkg")

# ===================================================================
# 1. RASTER DATA PROCESSING
# ===================================================================
# Reproject, resample, and clip rasters to common grid

# Download and load raster data
wsf <- download_wsf_data(aoi)
lc  <- rast("inst/extdata/LC_5.tif")
dem <- rast("inst/extdata/DEM_5.tif")

raster_list <- list(
  DEM = dem,
  LC  = lc,
  WSF = wsf
)

# Process rasters to common grid (10 m, EPSG:25832)
out <- process_rasters(
  aoi         = aoi,
  target_epsg = 25832,
  resolution  = 10,
  rasters     = raster_list
)

# Reclassify Land Cover to PALM surface types
lc_surfaces <- reclassify_lc_to_palm(out$LC)

# ===================================================================
# 2. BUILDING DATA PROCESSING
# ===================================================================
# Load LOD2 building footprints, split into buildings/bridges,
# classify buildings by type and construction year, rasterize.

lod2_multipolygon <- st_read("inst/extdata/lod2_multipolygon.gpkg")

# Process LOD2: clip to AOI, assign ID, split buildings/bridges
res <- process_lod2(buildings = lod2_multipolygon, aoi = aoi)

# Export intermediate building layers
st_write(res$buildings, "inst/extdata/processed_buildings.gpkg", append = FALSE)
st_write(res$bridges, "inst/extdata/processed_bridges.gpkg", append = FALSE)

# Classify buildings by ALKIS codes and WSF construction year
building_types <- assign_palm_building_type(
  buildings = res$buildings,
  wsf       = out$WSF
)
st_write(building_types, "inst/extdata/building_types.gpkg", append = FALSE)

# Rasterize building properties (type, ID, height)
building_rasters <- rasterize_buildings_palm(
  buildings = building_types,
  template  = out$DEM
)

# Rasterize bridge properties (ID, height)
bridge_rasters <- rasterize_bridges_palm(
  bridges  = res$bridges,
  template = out$DEM
)

# ===================================================================
# 3. RASTER EXPORT
# ===================================================================
# Export processed rasters to GeoTIFF with PALM naming convention

output_dir <- "inst/extdata/processed_rasters"
prefix <- "MUC"
resolution <- 10

# Export DEM (base raster)
export_to_palm(
  list(DEM = out$DEM),
  output_dir, prefix, resolution
)

# Export Land Cover surface types
export_to_palm(
  list(
    vegetation_type = lc_surfaces$vegetation,
    water_type = lc_surfaces$water,
    pavement_type = lc_surfaces$pavement
  ),
  output_dir, paste0(prefix, "_lc"), resolution
)

# Export building rasters
export_to_palm(
  list(
    building_type = building_rasters$type,
    building_id = building_rasters$id,
    building_height = building_rasters$height
  ),
  output_dir, prefix, resolution
)

# Export bridge rasters
export_to_palm(
  list(
    bridge_id = bridge_rasters$id,
    bridge_height = bridge_rasters$height
  ),
  output_dir, prefix, resolution
)

# ===================================================================
# 4. PALM CONFIGURATION FILE
# ===================================================================
# Generate YAML static driver configuration with auto-discovered files

config <- create_csd_configuration(
  prefix = "MUC",
  output_dir = output_dir,
  author = "author",
  contact_person = "David Voellner (david.voellner@stud-mail.uni-wuerzburg.de)",
  data_content = "Static driver for PALM4U Munich City domain, 10 m resolution",
  location = "Munich, Germany",
  institution = "Earth Observation Research Center (EORC), University of Wuerzburg",
  origin_time = "2025-02-16 00:00:00 +00",
  epsg = 25832,
  season = "summer",
  output_path = "/MUC_static_driver",
  file_out = "MUC_static_driver",
  version = 1,
  input_root_path = output_dir,
  pixel_size = 10.0,
  origin_x = 686750,
  origin_y = 5335300,
  nx = 39,
  ny = 39,
  dz = 10.0,
  bridge_depth = 3.0,
  buildings_3d = TRUE,
  generate_vegetation_patches = TRUE
)

