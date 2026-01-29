# ===================================================================
# Building Processing Utilities
# ===================================================================
# Helper functions for building data classification, geometry
# normalization, and property assignment used across PALMPrepR.
# ===================================================================

# -------------------------------------------------------------------
# Building ID Assignment
# -------------------------------------------------------------------

#' Add sequential IDs to building features
#' @keywords internal
.add_sequential_id <- function(x, id_col = "ID") {
  x[[id_col]] <- seq_len(nrow(x))
  x
}

# -------------------------------------------------------------------
# Building/Bridge Separation
# -------------------------------------------------------------------

#' Split buildings and bridges based on ALKIS function code
#'
#' Separates buildings into two categories using the standard ALKIS
#' function code: "53001_1800" identifies bridges, all others are
#' classified as buildings.
#'
#' @keywords internal
.split_buildings_bridges <- function(x, function_col = "function.") {

  if (!function_col %in% names(x)) {
    stop("Column 'function.' not found in building data.", call. = FALSE)
  }

  # ALKIS code 53001_1800 = bridges
  bridges <- x[x[[function_col]] == "53001_1800", ]

  # All others = buildings (including NA values)
  buildings <- x[
    x[[function_col]] != "53001_1800" | is.na(x[[function_col]]),
  ]

  list(
    buildings = buildings,
    bridges   = bridges
  )
}

# -------------------------------------------------------------------
# Geometry Normalization
# -------------------------------------------------------------------

#' Normalize geometry to MULTIPOLYGON
#'
#' Converts various polygon geometry types (POLYGON, MULTIPOLYGON,
#' GEOMETRYCOLLECTION) to MULTIPOLYGON format. Returns NULL if
#' normalization is not possible.
#'
#' @keywords internal
.force_multipolygon <- function(geom) {

  if (is.null(geom)) {
    return(NULL)
  }

  type <- sf::st_geometry_type(geom, by_geometry = FALSE)

  if (type == "MULTIPOLYGON") {
    return(geom)
  }

  if (type == "POLYGON") {
    return(sf::st_multipolygon(list(geom)))
  }

  # Extract polygons from geometry collections
  if (type == "GEOMETRYCOLLECTION") {
    polys <- geom[sf::st_geometry_type(geom) %in%
                    c("POLYGON", "MULTIPOLYGON")]

    if (length(polys) == 0) {
      return(NULL)
    }

    sf::st_union(polys)
  } else {
    # Unsupported geometry type
    NULL
  }
}

# -------------------------------------------------------------------
# PALM Building Type Classification
# -------------------------------------------------------------------

#' Classify buildings into PALM types
#'
#' Assigns PALM building types (1-7) based on ALKIS function codes
#' and WSF-derived construction year. Classification logic:
#' - Type 7: Bridges (ALKIS 53001_1800)
#' - Types 1-3: Residential (ALKIS 31001_1000)
#'   - Type 1: pre-1986
#'   - Type 2: 1986-2000
#'   - Type 3: post-2000
#' - Types 4-6: Non-residential
#'   - Type 4: pre-1986
#'   - Type 5: 1986-2000
#'   - Type 6: post-2000
#'
#' @keywords internal
.classify_palm_type <- function(function_code, year_max) {

  f <- as.character(function_code)
  y <- ifelse(is.na(year_max), 0, year_max)

  # Bridge
  if (f == "53001_1800") {
    return(7L)
  }

  # Residential buildings (ALKIS code 31001_1000)
  if (f == "31001_1000") {
    if (y %in% c(-1, 1985)) {
      return(1L)  # Pre-1986
    } else if (y >= 1986 && y <= 2000) {
      return(2L)  # 1986-2000
    } else if (y > 2000) {
      return(3L)  # Post-2000
    } else {
      return(1L)  # Default
    }
  }

  # Non-residential buildings (default)
  if (y %in% c(-1, 1985)) {
    return(4L)  # Pre-1986
  } else if (y >= 1986 && y <= 2000) {
    return(5L)  # 1986-2000
  } else if (y > 2000) {
    return(6L)  # Post-2000
  } else {
    return(4L)  # Default
  }
}

