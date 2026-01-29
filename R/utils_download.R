# ===================================================================
# Download and Validation Utilities
# ===================================================================
# Helper functions for downloading and validating spatial data (WSF,
# rasters) and area-of-interest (AOI) objects used across the
# PALMPrepR workflow.
# ===================================================================

# -------------------------------------------------------------------
# AOI Validation
# -------------------------------------------------------------------

#' Validate AOI geometry
#' @keywords internal
.validate_aoi <- function(aoi) {

  if (inherits(aoi, "sf")) {
    geom <- sf::st_geometry(aoi)
  } else if (inherits(aoi, "sfc")) {
    geom <- aoi
  } else {
    stop("`aoi` must be an sf or sfc object.", call. = FALSE)
  }

  if (!any(sf::st_geometry_type(geom) %in% c("POLYGON", "MULTIPOLYGON"))) {
    stop("AOI geometry must be POLYGON or MULTIPOLYGON.", call. = FALSE)
  }

  if (is.na(sf::st_crs(geom))) {
    stop("AOI must have a valid CRS.", call. = FALSE)
  }

  geom
}

#' Validate and project AOI to target EPSG
#' @keywords internal
.validate_aoi_projected <- function(aoi, epsg = 25832) {

  if (!inherits(aoi, c("sf", "sfc"))) {
    stop("`aoi` must be sf or sfc.", call. = FALSE)
  }

  if (is.na(sf::st_crs(aoi))) {
    stop("`aoi` must have a CRS.", call. = FALSE)
  }

  if (sf::st_is_longlat(aoi)) {
    stop("AOI must be projected (EPSG:25832).", call. = FALSE)
  }

  sf::st_transform(aoi, epsg)
}

# -------------------------------------------------------------------
# WSF Tile Naming and Download
# -------------------------------------------------------------------

#' Construct WSF Evolution tile filename from coordinates
#' @keywords internal
.wsf_tile_name <- function(lon, lat) {
  sprintf("WSFevolution_v1_%d_%d.tif", lon, lat)
}

#' Download a single WSF Evolution raster tile
#' @keywords internal
.download_wsf_raster <- function(url) {

  tmp <- tempfile(fileext = ".tif")

  resp <- httr::GET(
    url,
    httr::write_disk(tmp, overwrite = TRUE)
  )

  if (httr::status_code(resp) != 200) {
    stop("Failed to download WSF tile: ", url, call. = FALSE)
  }

  terra::rast(tmp)
}
