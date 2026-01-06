# -------------------------------------------------------------------
#' Download, merge, and clip LOD2 building tiles to AOI
#'
#' Downloads all intersecting Bavarian LOD2 CityGML tiles,
#' converts them to GeoPackage, merges them into a single
#' sf object, and clips the result to the AOI.
#'
#' @param aoi An `sf` or `sfc` object (EPSG:25832).
#' @param cache_dir Directory used to cache converted GPKG tiles.
#' @param base_url Base URL for LOD2 CityGML tiles.
#' @param target_epsg Target CRS (default: 25832).
#'
#' @return An `sf` object containing merged and clipped buildings.
#'
#' @export
download_lod2_buildings <- function(
    aoi,
    cache_dir,
    base_url = "https://download1.bayernwolke.de/a/lod2/citygml/",
    target_epsg = 25832
) {

  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  # -----------------------------------------------------------
  # Validate & prepare AOI
  # -----------------------------------------------------------
  aoi <- .validate_aoi_projected(aoi, target_epsg)
  aoi_geom <- sf::st_geometry(aoi)
  bb <- sf::st_bbox(aoi)

  # -----------------------------------------------------------
  # Determine intersecting 2 km tile indices (UTM grid)
  # -----------------------------------------------------------
  e_idx <- seq(
    floor(bb["xmin"] / 2000) * 2,
    floor(bb["xmax"] / 2000) * 2,
    by = 2
  )

  n_idx <- seq(
    floor(bb["ymin"] / 2000) * 2,
    floor(bb["ymax"] / 2000) * 2,
    by = 2
  )

  tiles <- expand.grid(E = e_idx, N = n_idx)
  tiles$name <- paste0(tiles$E, "_", tiles$N)

  message("Downloading ", nrow(tiles), " LOD2 tiles")

  buildings_list <- list()

  # -----------------------------------------------------------
  # Download + read CityGML tiles
  # -----------------------------------------------------------
  for (tile in tiles$name) {

    gml_file <- file.path(cache_dir, paste0(tile, ".gml"))

    # Download if not cached
    if (!file.exists(gml_file)) {

      gml_url <- paste0(base_url, tile, ".gml")

      resp <- httr::GET(
        gml_url,
        httr::write_disk(gml_file, overwrite = TRUE),
        httr::progress()
      )

      if (httr::status_code(resp) != 200) {
        unlink(gml_file)
        next
      }
    }

    # Read CityGML (all layers)
    layers <- tryCatch(sf::st_layers(gml_file)$name, error = function(e) NULL)
    if (is.null(layers) || !length(layers)) next

    objs <- lapply(layers, function(lyr) {
      tryCatch(
        sf::st_read(gml_file, layer = lyr, quiet = TRUE),
        error = function(e) NULL
      )
    })

    objs <- objs[!vapply(objs, is.null, logical(1))]
    if (!length(objs)) next

    tile_sf <- do.call(rbind, objs)
    if (!inherits(tile_sf, "sf") || !nrow(tile_sf)) next

    tile_sf <- sf::st_transform(tile_sf, target_epsg)
    buildings_list[[length(buildings_list) + 1]] <- tile_sf
  }

  if (!length(buildings_list)) {
    stop("No LOD2 tiles could be downloaded or read.", call. = FALSE)
  }

  # -----------------------------------------------------------
  # Merge all tiles FIRST
  # -----------------------------------------------------------
  buildings <- do.call(rbind, buildings_list)

  # -----------------------------------------------------------
  # Convert CityGML solids → 2D building footprints
  # (robust handling of mixed geometry types)
  # -----------------------------------------------------------

  # Drop Z/M first
  buildings <- sf::st_zm(buildings, drop = TRUE, what = "ZM")

  # Detect geometry types
  gtypes <- sf::st_geometry_type(buildings)

  # Indices of collection-like geometries
  is_collection <- gtypes %in% c(
    "GEOMETRYCOLLECTION",
    "MULTISURFACE",
    "POLYHEDRALSURFACE",
    "MULTIPOLYHEDRALSURFACE"
  )

  # For collections: extract polygonal components
  if (any(is_collection)) {
    buildings[is_collection, ] <- sf::st_collection_extract(
      buildings[is_collection, ],
      type = "POLYGON",
      warn = FALSE
    )
  }

  # Now GEOS is safe to use
  buildings <- sf::st_make_valid(buildings)

  # Ensure uniform MULTIPOLYGON output
  buildings <- sf::st_cast(buildings, "MULTIPOLYGON", warn = FALSE)



  # -----------------------------------------------------------
  # Clip ONCE to AOI
  # -----------------------------------------------------------
  buildings_clipped <- sf::st_intersection(buildings, aoi_geom)

  if (!nrow(buildings_clipped)) {
    stop("No LOD2 buildings intersect the AOI.", call. = FALSE)
  }

  buildings_clipped
}
