# -------------------------------------------------------------------
# Internal helper functions
# -------------------------------------------------------------------

# snap extent to resolution grid (GDAL -tap equivalent)
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

