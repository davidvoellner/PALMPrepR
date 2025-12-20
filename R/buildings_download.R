# -------------------------------
#' Download Bavarian LOD2 buildings clipped to AOI
#'
#' Downloads LOD2 CityGML tiles (2 km × 2 km UTM grid),
#' converts them immediately to GeoPackage,
#' clips to the AOI, and returns merged building footprints.
#'
#' @param aoi An `sf` or `sfc` object (EPSG:25832).
#' @param cache_dir Directory used to cache converted GPKG tiles.
#' @param base_url Base URL for LOD2 tiles.
#'
#' @return An `sf` object with building footprints clipped to AOI.
#'
#' @examples
#' \dontrun{
#' aoi <- sf::st_read("inst/extdata/small_aoi.gpkg")
#'
#' lod2 <- download_lod2_buildings(
#'   aoi       = aoi,
#'   cache_dir = "lod2_cache"
#' )
#'
#' plot(sf::st_geometry(lod2))
#' }
#'
#' @export
download_lod2_buildings <- function(
    aoi,
    cache_dir,
    base_url = "https://download1.bayernwolke.de/a/lod2/citygml/"
) {

  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  # -----------------------------------------------------------
  # Prepare AOI
  # -----------------------------------------------------------

  aoi <- .validate_aoi_projected(aoi)
  aoi_geom <- sf::st_geometry(aoi)
  bb <- sf::st_bbox(aoi)

  # -----------------------------------------------------------
  # Compute tile indices (UTM km grid, step = 2 km)
  # -----------------------------------------------------------

  e_start <- floor(bb["xmin"] / 1000 / 2) * 2
  e_end   <- floor(bb["xmax"] / 1000 / 2) * 2
  n_start <- floor(bb["ymin"] / 1000 / 2) * 2
  n_end   <- floor(bb["ymax"] / 1000 / 2) * 2

  e_idx <- seq(e_start, e_end, by = 2)
  n_idx <- seq(n_start, n_end, by = 2)

  tiles <- expand.grid(E = e_idx, N = n_idx)
  tiles$name <- paste0(tiles$E, "_", tiles$N)

  message("Downloading ", nrow(tiles), " LOD2 building tiles")

  results <- list()

  # -----------------------------------------------------------
  # Download → convert → clip
  # -----------------------------------------------------------

  for (i in seq_len(nrow(tiles))) {

    tile <- tiles$name[i]
    message("Processing tile ", tile)

    gml_url  <- paste0(base_url, tile, ".gml")
    gpkg_out <- file.path(cache_dir, paste0(tile, ".gpkg"))

    # Convert only once (cache)
    if (!file.exists(gpkg_out)) {

      tmp_gml <- tempfile(fileext = ".gml")

      resp <- httr::GET(
        gml_url,
        httr::write_disk(tmp_gml, overwrite = TRUE),
        httr::progress()
      )

      if (httr::status_code(resp) != 200) {
        unlink(tmp_gml)
        next
      }

      ok <- .convert_gml_to_gpkg(tmp_gml, gpkg_out)
      unlink(tmp_gml)

      if (!ok) {
        next
      }
    }

    # Read converted GPKG
    gpkg <- tryCatch(
      sf::st_read(gpkg_out, quiet = TRUE),
      error = function(e) NULL
    )

    if (is.null(gpkg) || nrow(gpkg) == 0) {
      next
    }

    gpkg <- sf::st_make_valid(gpkg)

    clipped <- tryCatch(
      sf::st_intersection(gpkg, aoi_geom),
      error = function(e) NULL
    )

    if (!is.null(clipped) && nrow(clipped) > 0) {
      results[[length(results) + 1]] <- clipped
    }
  }

  if (!length(results)) {
    stop("No LOD2 buildings intersect the AOI.", call. = FALSE)
  }

  do.call(rbind, results)
}
