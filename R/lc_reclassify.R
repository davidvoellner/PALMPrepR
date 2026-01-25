# -------------------------------------------------------------------
#' Reclassify LC raster to PALM surface type rasters
#'
#' Converts a Land Cover raster to PALM-compatible vegetation, water,
#' and pavement type rasters using reclassification rules.
#'
#' @param lc_raster A `terra::SpatRaster` with LC classification codes.
#' @param nodata_out The output NoData value (default: 255).
#'
#' @return A named list of three `terra::SpatRaster` objects:
#'   - `vegetation`: Vegetation type classification
#'   - `water`: Water type classification
#'   - `pavement`: Pavement type classification
#'
#' @details
#' Reclassification mappings:
#' - Vegetation: LC 4→3, 5→1, 8→1, 9→16, 10→17, 11→7
#' - Water: LC 2→1
#' - Pavement: LC 12→1, 6→13
#'
#' @examples
#' \dontrun{
#' lc <- rast("LC.tif")
#' palm_surfaces <- reclassify_lc_to_palm(lc)
#'
#' plot(palm_surfaces$vegetation)
#' plot(palm_surfaces$water)
#' plot(palm_surfaces$pavement)
#' }
#'
#' @export
reclassify_lc_to_palm <- function(lc_raster, nodata_out = 255) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

  if (!inherits(lc_raster, "SpatRaster")) {
    stop("`lc_raster` must be a terra::SpatRaster.", call. = FALSE)
  }

  # ---------------------------------------------------------------
  # Vegetation type reclassification
  # LC 4→3, 5→1, 8→1, 9→16, 10→17, 11→7, rest→nodata
  # ---------------------------------------------------------------

  veg_rcl <- matrix(c(
    4,  3,
    5,  1,
    8,  1,
    9,  16,
    10, 17,
    11, 7
  ), ncol = 2, byrow = TRUE)

  veg_raster <- terra::classify(lc_raster, veg_rcl, others = nodata_out)

  # ---------------------------------------------------------------
  # Water type reclassification
  # LC 2→1, rest→nodata
  # ---------------------------------------------------------------

  water_rcl <- matrix(c(
    2, 1
  ), ncol = 2, byrow = TRUE)

  water_raster <- terra::classify(lc_raster, water_rcl, others = nodata_out)

  # ---------------------------------------------------------------
  # Pavement type reclassification
  # LC 12→1, 6→13, rest→nodata
  # ---------------------------------------------------------------

  pave_rcl <- matrix(c(
    12, 1,
    6,  13
  ), ncol = 2, byrow = TRUE)

  pave_raster <- terra::classify(lc_raster, pave_rcl, others = nodata_out)

  # ---------------------------------------------------------------
  # Return list of rasters
  # ---------------------------------------------------------------

  list(
    vegetation = veg_raster,
    water = water_raster,
    pavement = pave_raster
  )

}
