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

.validate_aoi_projected <- function(aoi, epsg = 25832) {

  if (!inherits(aoi, c("sf", "sfc"))) {
    stop("AOI must be sf or sfc.", call. = FALSE)
  }

  if (is.na(sf::st_crs(aoi))) {
    stop("AOI must have a CRS.", call. = FALSE)
  }

  if (sf::st_is_longlat(aoi)) {
    stop("AOI must be projected (EPSG:25832).", call. = FALSE)
  }

  sf::st_transform(aoi, epsg)
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

# create tile index
.building_tile_index <- function(x, y) {
  list(
    xi = floor(x / 1000),
    yi = floor(y / 1000)
  )
}

# create tile name
.building_tile_name <- function(xi, yi) {
  sprintf("%d_%d.gml", xi, yi)
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

.convert_gml_to_gpkg <- function(gml_file, gpkg_file, epsg = 25832) {

  v <- tryCatch(
    terra::vect(gml_file),
    error = function(e) NULL
  )

  if (is.null(v) || nrow(v) == 0) {
    return(FALSE)
  }

  # Reproject (terra-native)
  v <- terra::project(v, paste0("EPSG:", epsg))

  # Write directly — DO NOT touch geometry further
  terra::writeVector(
    v,
    gpkg_file,
    overwrite = TRUE,
    filetype = "GPKG"
  )

  TRUE
}
