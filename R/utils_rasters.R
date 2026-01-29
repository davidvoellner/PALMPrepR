# ===================================================================
# Raster Processing Utilities
# ===================================================================
# Helper functions for raster grid alignment and manipulation
# used across PALMPrepR processing workflows.
# ===================================================================

# -------------------------------------------------------------------
# Grid Snapping
# -------------------------------------------------------------------

#' Snap extent to pixel-aligned grid
#'
#' Aligns a raster extent to a regular grid with specified resolution.
#' Equivalent to GDAL's `-tap` (target aligned pixels) option.
#' Ensures consistent grid alignment across multiple rasters.
#'
#' @keywords internal
.snap_extent <- function(ext, resolution) {

  if (!inherits(ext, "SpatExtent")) {
    stop("`ext` must be a terra::ext() object.", call. = FALSE)
  }

  terra::ext(
    floor(ext$xmin / resolution) * resolution,
    ceiling(ext$xmax / resolution) * resolution,
    floor(ext$ymin / resolution) * resolution,
    ceiling(ext$ymax / resolution) * resolution
  )
}

