#' Reproject, clip, and resample rasters to a common grid
#'
#' @param target_epsg Integer EPSG code (e.g. 25832)
#' @param resolution Target resolution in map units (meters)
#' @param extent_gpkg GeoPackage defining the clipping extent
#' @param out_dir Output directory
#' @param rasters Character vector of input raster paths
#'
#' @return Invisibly returns vector of output file paths
#'
#' @examples
#' \dontrun{
#' # Example using a small AOI and dummy raster paths
#' aoi <- system.file(
#'   "extdata",
#'   "test_aoi.gpkg",
#'   package = "PALMPrepR"
#' )
#'
#' process_raster_files(
#'   target_epsg = 25832,
#'   resolution  = 1,
#'   extent_gpkg = aoi,
#'   out_dir     = tempdir(),
#'   rasters     = c(
#'     "DGM.tif",
#'     "LC.tif",
#'     "WSF.tif"
#'   )
#' )
#' }
#'

#' @export
process_raster_files <- function(
    target_epsg,
    resolution,
    extent_gpkg,
    out_dir,
    rasters
) {

  if (!length(rasters)) {
    stop("No input rasters provided.")
  }

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  message("==========================================================")
  message(" Target CRS:        EPSG:", target_epsg)
  message(" Target Resolution: ", resolution, " m")
  message(" Clip Extent:       ", extent_gpkg)
  message(" Output Directory:  ", out_dir)
  message("==========================================================\n")

  # ------------------------------------------------------------------
  # Read and reproject extent
  # ------------------------------------------------------------------
  ext_sf <- sf::st_read(extent_gpkg, quiet = TRUE)
  ext_sf <- sf::st_transform(ext_sf, target_epsg)
  ext_vect <- terra::vect(ext_sf)

  # ------------------------------------------------------------------
  # Loop over rasters
  # ------------------------------------------------------------------
  outputs <- character()

  for (r_path in rasters) {

    basename <- tools::file_path_sans_ext(basename(r_path))
    outfile  <- file.path(
      out_dir,
      sprintf("%s_grid_%sm.tif", basename, resolution)
    )

    message("---- Processing ", r_path, " ----")
    message("Output -> ", outfile)

    # Determine resampling method
    if (grepl("LC|WSF", basename, ignore.case = TRUE)) {
      method <- "near"
    } else {
      method <- "bilinear"
    }

    # ----------------------------------------------------------------
    # Read raster
    # ----------------------------------------------------------------
    r <- terra::rast(r_path)

    # ----------------------------------------------------------------
    # Project to target CRS
    # ----------------------------------------------------------------
    r_proj <- terra::project(
      r,
      paste0("EPSG:", target_epsg),
      method = method
    )

    # ----------------------------------------------------------------
    # Create target grid
    # ----------------------------------------------------------------
    target_grid <- terra::rast(
      terra::ext(ext_vect),
      resolution = resolution,
      crs = terra::crs(r_proj)
    )

    # ----------------------------------------------------------------
    # Resample onto target grid
    # ----------------------------------------------------------------
    r_resampled <- terra::resample(
      r_proj,
      target_grid,
      method = method
    )

    # ----------------------------------------------------------------
    # Crop & mask to AOI
    # ----------------------------------------------------------------
    r_clipped <- terra::crop(r_resampled, ext_vect)
    r_clipped <- terra::mask(r_clipped, ext_vect)

    # ----------------------------------------------------------------
    # Write output
    # ----------------------------------------------------------------
    terra::writeRaster(
      r_clipped,
      outfile,
      overwrite = TRUE,
      NAflag = -9999,
      wopt = list(
        gdal = c("COMPRESS=DEFLATE", "TILED=YES")
      )
    )

    message("[INFO] Finished ", outfile, "\n")

    outputs <- c(outputs, outfile)

    # ----------------------------------------------------------------
    # Terrain detection (same logic as shell script)
    # ----------------------------------------------------------------
    if (grepl("DGM|terrain|DEM", basename, ignore.case = TRUE)) {
      static_input <- "/dss/dsshome1/00/di97paz/container_palm/data_MUC/palm_csd_ready"
      dest <- file.path(static_input, "MUC_terrain_height.tif")

      message("Detected terrain file (", basename, "). Copying to:")
      message("    ", dest)

      file.copy(outfile, dest, overwrite = TRUE)
    }
  }

  # ------------------------------------------------------------------
  # Summary check
  # ------------------------------------------------------------------
  message("---- Checking results ----")

  for (f in outputs) {
    r <- terra::rast(f)
    message(basename(f), ":")
    message("  CRS:  ", terra::crs(r))
    message("  Res:  ", paste(terra::res(r), collapse = " x "))
  }

  message("[INFO] All rasters processed successfully!")

  invisible(outputs)
}
