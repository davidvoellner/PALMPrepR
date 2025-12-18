# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

BASE_URL <- "https://download.geoservice.dlr.de/WSF_EVO/files/"

# -------------------------------------------------------------------
# Helper functions (internal)
# -------------------------------------------------------------------

tile_name <- function(lon, lat) {
  sprintf("WSFevolution_v1_%d_%d.tif", lon, lat)
}

download_file <- function(url, output_path) {
  message("Downloading ", output_path, " ...")

  resp <- httr::GET(
    url,
    httr::write_disk(output_path, overwrite = TRUE),
    httr::progress()
  )

  if (httr::status_code(resp) == 200) {
    message("Saved ", output_path)
  } else {
    warning(
      sprintf(
        "Failed (HTTP %d) for %s",
        httr::status_code(resp),
        url
      )
    )
  }
}

read_extent_and_crs <- function(gpkg_path) {
  layer_info <- sf::st_layers(gpkg_path)
  layer <- layer_info$name[1]

  x <- sf::st_read(gpkg_path, layer = layer, quiet = TRUE)

  list(
    bounds = sf::st_bbox(x),
    crs    = sf::st_crs(x)
  )
}

reproject_bounds <- function(bounds, src_crs, dst_crs = 4326) {

  poly <- sf::st_as_sfc(bounds)
  sf::st_crs(poly) <- src_crs

  poly_4326 <- sf::st_transform(poly, dst_crs)

  list(
    bounds = sf::st_bbox(poly_4326),
    geom   = poly_4326
  )
}

# -------------------------------------------------------------------
#' Download WSF Evolution tiles intersecting an AOI
#'
#' Downloads all WSF Evolution raster tiles (2×2 degree grid) that
#' intersect the spatial extent of an input AOI provided as a GeoPackage.
#' The AOI is automatically reprojected to EPSG:4326 for tile selection.
#'
#' @param gpkg_file Path to a GeoPackage defining the AOI extent.
#' @param out_dir Output directory for downloaded WSF tiles.
#'
#' @return Invisibly returns the output directory.
#'
#' @examples
#' \dontrun{
#' # Use the example AOI shipped with the package
#' aoi <- system.file(
#'   "extdata",
#'   "test_aoi.gpkg",
#'   package = "PALMPrepR"
#' )
#'
#' out_dir <- file.path(tempdir(), "wsf_tiles")
#' dir.create(out_dir, showWarnings = FALSE)
#'
#' download_wsf_tiles(
#'   gpkg_file = aoi,
#'   out_dir   = out_dir
#' )
#'
#' list.files(out_dir)
#'}

#' @export
download_wsf_tiles <- function(gpkg_file, out_dir) {

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  message("Reading extent from ", gpkg_file, " ...")

  info <- read_extent_and_crs(gpkg_file)
  reproj <- reproject_bounds(info$bounds, info$crs)

  b <- reproj$bounds
  geom4326 <- reproj$geom

  lon_start <- floor(b["xmin"] / 2) * 2
  lon_end   <- ceiling(b["xmax"] / 2) * 2
  lat_start <- floor(b["ymin"] / 2) * 2
  lat_end   <- ceiling(b["ymax"] / 2) * 2

  tiles <- list()

  for (lon in seq(lon_start, lon_end - 2, by = 2)) {
    for (lat in seq(lat_start, lat_end - 2, by = 2)) {

      tile_geom <- sf::st_as_sfc(
        sf::st_bbox(
          c(xmin = lon, ymin = lat, xmax = lon + 2, ymax = lat + 2),
          crs = 4326
        )
      )

      if (sf::st_intersects(geom4326, tile_geom, sparse = FALSE)) {
        tiles <- append(tiles, list(c(lon, lat)))
      }
    }
  }

  if (!length(tiles)) {
    message("No tiles intersect the GPKG extent.")
    return(invisible(NULL))
  }

  for (t in tiles) {
    filename <- tile_name(t[1], t[2])
    download_file(
      paste0(BASE_URL, filename),
      file.path(out_dir, filename)
    )
  }

  invisible(out_dir)
}
