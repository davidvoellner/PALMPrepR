# Configuration

BASE_URL <- "https://download.geoservice.dlr.de/WSF_EVO/files/"

# Internal helper functions

# -------------------------------------------------------------------
#' Download, merge, and clip WSF Evolution data to an AOI
#'
#' Downloads all WSF Evolution raster tiles (2×2 degree grid)
#' intersecting an AOI, mosaics them, and clips the result
#' exactly to the AOI.
#'
#' @param aoi An `sf` or `sfc` object defining the area of interest.
#'
#' @return A `terra::SpatRaster` clipped to the AOI.
#'
#' @examples
#' \dontrun{
#' library(sf)
#'
#' aoi <- st_read("inst/extdata/test_aoi.gpkg")
#'
#' wsf <- download_wsf_data(aoi)
#'
#' wsf
#' terra::plot(wsf)
#' }
#'
#' @export
download_wsf_data <- function(aoi) {

  # --- validate AOI ---
  geom <- .validate_aoi(aoi)

  # --- reproject AOI to WGS84 ---
  geom_4326 <- sf::st_transform(geom, 4326)
  bbox <- sf::st_bbox(geom_4326)

  # --- determine intersecting 2×2 degree tiles ---
  lon_start <- floor(bbox["xmin"] / 2) * 2
  lon_end   <- ceiling(bbox["xmax"] / 2) * 2
  lat_start <- floor(bbox["ymin"] / 2) * 2
  lat_end   <- ceiling(bbox["ymax"] / 2) * 2

  tile_coords <- list()

  for (lon in seq(lon_start, lon_end - 2, by = 2)) {
    for (lat in seq(lat_start, lat_end - 2, by = 2)) {

      tile_geom <- sf::st_as_sfc(
        sf::st_bbox(
          c(
            xmin = lon,
            ymin = lat,
            xmax = lon + 2,
            ymax = lat + 2
          ),
          crs = 4326
        )
      )

      if (sf::st_intersects(geom_4326, tile_geom, sparse = FALSE)) {
        tile_coords[[paste(lon, lat, sep = "_")]] <- c(lon, lat)
      }
    }
  }

  if (!length(tile_coords)) {
    stop("No WSF tiles intersect AOI.", call. = FALSE)
  }

  # --- download tiles ---
  rasters <- lapply(
    tile_coords,
    function(t) {
      url <- paste0(BASE_URL, .wsf_tile_name(t[1], t[2]))
      .download_wsf_raster(url)
    }
  )

  # --- ensure rasters exist ---
  if (length(rasters) == 0) {
    stop("WSF tiles were identified but none could be downloaded.", call. = FALSE)
  }

  # --- mosaic tiles ---
  wsf_merged <- Reduce(terra::mosaic, rasters)


  # --- clip & mask to AOI ---
  aoi_vect <- terra::vect(geom_4326)

  wsf_clipped <- terra::mask(
    terra::crop(wsf_merged, aoi_vect),
    aoi_vect
  )

  wsf_clipped
}
