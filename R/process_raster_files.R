# -------------------------------------------------------------------
#' Reproject, clip, and resample rasters to a common grid.
#' The resampling method is based on the name of the rasters in the
#' *named* list of `terra::SpatRaster` objects.
#' LC or WFS --> nearest neighbour
#' else --> bilinear
#'
#' @param aoi An `sf` or `sfc` object defining the area of interest.
#' @param target_epsg Integer EPSG code (e.g. 25832).
#' @param resolution Target resolution in map units (e.g. meters).
#' @param rasters A named list of `terra::SpatRaster` objects.
#' @param out_dir Optional output directory. If NULL, nothing is written
#'   to disk and rasters are returned in memory.
#'
#' @return A named list of processed `terra::SpatRaster` objects.
#'
#' @examples
#' \dontrun{
#' library(sf)
#' library(terra)
#'
#' aoi <- st_read("inst/extdata/test_aoi.gpkg")
#'
#' rasters <- list(
#'   DEM = rast("DEM.tif"),
#'   LC  = rast("LC.tif"),
#'   WSF = rast("WSF.tif")
#' )
#'
#' out <- process_raster_files(
#'   aoi          = aoi,
#'   target_epsg  = 25832,
#'   resolution   = 1,
#'   rasters      = rasters,
#'   out_dir      = tempdir()
#' )
#'
#' out$DEM
#' }
#'
#' @export
process_raster_files <- function(
    aoi,
    target_epsg,
    resolution,
    rasters,
    out_dir = NULL
) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

  if (!inherits(aoi, c("sf", "sfc"))) {
    stop("`aoi` must be an sf or sfc object.", call. = FALSE)
  }

  if (!length(rasters)) {
    stop("No input rasters provided.", call. = FALSE)
  }

  if (!all(vapply(rasters, inherits, logical(1), "SpatRaster"))) {
    stop("All elements of `rasters` must be terra::SpatRaster objects.",
         call. = FALSE)
  }

  if (is.null(names(rasters)) || any(names(rasters) == "")) {
    stop("`rasters` must be a *named* list.", call. = FALSE)
  }

  if (!is.null(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }

  message("==========================================================")
  message(" Target CRS:        EPSG:", target_epsg)
  message(" Target Resolution: ", resolution)
  message("==========================================================\n")

  # ---------------------------------------------------------------
  # Prepare AOI
  # ---------------------------------------------------------------

  aoi_geom <- sf::st_geometry(aoi)
  aoi_geom <- sf::st_transform(aoi_geom, target_epsg)
  aoi_vect <- terra::vect(aoi_geom)

  # ---------------------------------------------------------------
  # Create reference grid (from AOI)
  # ---------------------------------------------------------------

  ref_grid <- terra::rast(
    terra::ext(aoi_vect),
    resolution = resolution,
    crs = paste0("EPSG:", target_epsg)
  )

  # ---------------------------------------------------------------
  # Process rasters
  # ---------------------------------------------------------------

  outputs <- list()

  for (name in names(rasters)) {

    message("---- Processing ", name, " ----")

    r <- rasters[[name]]

    # Determine resampling method
    method <- if (grepl("LC|WSF", name, ignore.case = TRUE)) {
      "near"
    } else {
      "bilinear"
    }

    # Reproject
    r_proj <- terra::project(
      r,
      terra::crs(ref_grid),
      method = method
    )

    # Resample to reference grid
    r_resampled <- terra::resample(
      r_proj,
      ref_grid,
      method = method
    )

    # Crop and mask
    r_clipped <- terra::crop(r_resampled, aoi_vect)
    r_clipped <- terra::mask(r_clipped, aoi_vect)

    outputs[[name]] <- r_clipped

    # Optional writing to disk
    if (!is.null(out_dir)) {

      outfile <- file.path(
        out_dir,
        sprintf("%s_grid_%sm.tif", name, resolution)
      )

      terra::writeRaster(
        r_clipped,
        outfile,
        overwrite = TRUE,
        NAflag = -9999,
        wopt = list(
          gdal = c("COMPRESS=DEFLATE", "TILED=YES")
        )
      )

      message("Output -> ", outfile)
    }

    message("[INFO] Finished ", name, "\n")
  }

  message("[INFO] All rasters processed successfully!")

  outputs
}
