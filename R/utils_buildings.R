# -------------------------------------------------------------------
# Internal helper functions
# -------------------------------------------------------------------

# add id to each building
.add_sequential_id <- function(x, id_col = "ID") {
  x[[id_col]] <- seq_len(nrow(x))
  x
}

# split buildings and bridges in separate layers based on column "function."
.split_buildings_bridges <- function(x, function_col = "function.") {

  if (!function_col %in% names(x)) {
    stop("Column 'function.' not found in building data.", call. = FALSE)
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

# force MULTIPOLYGON geometries
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

  if (type == "GEOMETRYCOLLECTION") {
    polys <- geom[sf::st_geometry_type(geom) %in%
                    c("POLYGON", "MULTIPOLYGON")]

    if (length(polys) == 0) {
      return(NULL)
    }

    sf::st_union(polys)
  } else {
    NULL
  }
}

# classify palm building type based on function and construction age approximation
.classify_palm_type <- function(function_code, year_max) {

  f <- as.character(function_code)
  y <- ifelse(is.na(year_max), 0, year_max)

  # Bridge
  if (f == "53001_1800") {
    return(7L)
  }

  # Residential
  if (f == "31001_1000") {
    if (y %in% c(-1, 1985)) {
      return(1L)
    } else if (y >= 1986 && y <= 2000) {
      return(2L)
    } else if (y > 2000) {
      return(3L)
    } else {
      return(1L)
    }
  }

  # Non-residential
  if (y %in% c(-1, 1985)) {
    return(4L)
  } else if (y >= 1986 && y <= 2000) {
    return(5L)
  } else if (y > 2000) {
    return(6L)
  } else {
    return(4L)
  }
}

