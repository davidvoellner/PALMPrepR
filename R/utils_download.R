# -------------------------------------------------------------------
# Internal helper functions
# -------------------------------------------------------------------

# AOI validation
.validate_aoi <- function(aoi) {

  if (inherits(aoi, "sf")) {
    geom <- sf::st_geometry(aoi)
  } else if (inherits(aoi, "sfc")) {
    geom <- aoi
  } else {
    stop("AOI must be an sf or sfc object.", call. = FALSE)
  }

  if (!any(sf::st_geometry_type(geom) %in%
           c("POLYGON", "MULTIPOLYGON"))) {
    stop("AOI geometry must be POLYGON or MULTIPOLYGON.", call. = FALSE)
  }

  if (is.na(sf::st_crs(geom))) {
    stop("AOI must have a valid CRS.", call. = FALSE)
  }

  geom
}

# WSF tile name construction
.wsf_tile_name <- function(lon, lat) {
  sprintf("WSFevolution_v1_%d_%d.tif", lon, lat)
}

# WSF download
.download_wsf_raster <- function(url) {

  tmp <- tempfile(fileext = ".tif")

  resp <- httr::GET(
    url,
    httr::write_disk(tmp, overwrite = TRUE),
    httr::progress()
  )

  if (httr::status_code(resp) != 200) {
    stop("Failed to download WSF tile: ", url, call. = FALSE)
  }

  terra::rast(tmp)
}

# index tile coordinates for building grid
.building_tile_index <- function(x, y, tile_size = 2000) {
  # Compute lower-left index of containing 2km tile
  xi <- floor(x / tile_size) * tile_size
  yi <- floor(y / tile_size) * tile_size
  list(xi = xi, yi = yi)
}


# construct building tile filename
.building_tile_name <- function(xi, yi) {
  sprintf("%d_%d.gml", xi / 1000, yi / 1000)
}


# download GML
.download_building_gml <- function(url) {
  tmp <- tempfile(fileext = ".gml")
  resp <- httr::GET(
    url,
    httr::write_disk(tmp, overwrite = TRUE),
    httr::progress()
  )
  if (httr::status_code(resp) != 200) {
    unlink(tmp)
    warning("Failed to download ", url)
    return(NULL)
  }
  tmp
}
