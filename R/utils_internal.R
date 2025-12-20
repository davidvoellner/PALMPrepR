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

#add id to each building
.add_sequential_id <- function(x, id_col = "ID") {
  x[[id_col]] <- seq_len(nrow(x))
  x
}

#split buildings and bridges in separate layers based
.split_buildings_bridges <- function(x, function_col = "function") {

  if (!function_col %in% names(x)) {
    stop("Column 'function' not found in building data.", call. = FALSE)
  }

  bridges <- x[x[[function_col]] == "53001_1800", ]
  buildings <- x[
    x[[function_col]] != "53001_1800" | is.na(x[[function_col]]),
  ]

  list(
    buildings = buildings,
    bridges   = bridges
  )
}
