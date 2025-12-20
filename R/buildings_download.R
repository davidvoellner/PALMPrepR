# -------------------------------------------------------------------
# Internal helper: index tile coordinates for LOD2 grid
# -------------------------------------------------------------------
.lod2_tile_index <- function(x, y, tile_size = 2000) {
  # Compute lower-left index of containing 2km tile
  xi <- floor(x / tile_size) * tile_size
  yi <- floor(y / tile_size) * tile_size
  list(xi = xi, yi = yi)
}

# -------------------------------------------------------------------
# Internal helper: construct LOD2 tile filename
# -------------------------------------------------------------------
.lod2_tile_name <- function(xi, yi) {
  sprintf("%d_%d.gml", xi / 1000, yi / 1000)
}

# -------------------------------------------------------------------
# Internal helper: download GML
# -------------------------------------------------------------------
.download_lod2_gml <- function(url) {
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

# -------------------------------------------------------------------
#' Download LOD2 CityGML tiles intersecting an AOI
#'
#' Given an AOI (projected), find the intersecting 2km LOD2 tile names,
#' download them, read them as `sf`, and clip to the AOI.
#'
#' @param aoi An `sf` or `sfc` object with a projected CRS (e.g., EPSG:25832)
#' @param base_url Base URL prefix for LOD2 tiles
#'   (default: `"https://download1.bayernwolke.de/a/lod2/citygml/"`)
#' @param tile_size Size of tiles in CRS units (default 2000 m)
#'
#' @return A merged `sf` of clipped LOD2 features
#' @export
download_lod2_tiles <- function(
    aoi,
    base_url = "https://download1.bayernwolke.de/a/lod2/citygml/",
    tile_size = 2000
) {

  # --- Validate AOI ---
  if (!inherits(aoi, c("sf", "sfc"))) {
    stop("AOI must be sf or sfc", call. = FALSE)
  }
  if (is.na(sf::st_crs(aoi))) {
    stop("AOI must have a defined CRS", call. = FALSE)
  }

  # Get projected extent
  # Ensure AOI is in a projected CRS (units in meters)
  aoi_proj <- sf::st_transform(aoi, sf::st_crs(aoi))
  bb <- sf::st_bbox(aoi_proj)

  # Compute range of tile indices
  x_idx <- seq(
    floor(bb["xmin"] / tile_size) * tile_size,
    floor((bb["xmax"] - 1) / tile_size) * tile_size,
    by = tile_size
  )
  y_idx <- seq(
    floor(bb["ymin"] / tile_size) * tile_size,
    floor((bb["ymax"] - 1) / tile_size) * tile_size,
    by = tile_size
  )

  if (length(x_idx) == 0 || length(y_idx) == 0) {
    stop("AOI is empty or too small", call. = FALSE)
  }

  tiles <- expand.grid(xi = x_idx, yi = y_idx)

  # Build URLs
  tiles$tile_name <- with(tiles, .lod2_tile_name(xi, yi))
  tiles$url <- paste0(base_url, tiles$tile_name)

  # Download
  gml_files <- list()
  for (i in seq_len(nrow(tiles))) {
    gml <- .download_lod2_gml(tiles$url[i])
    if (!is.null(gml)) {
      gml_files[[tiles$tile_name[i]]] <- gml
    }
  }
  if (length(gml_files) == 0) {
    stop("No LOD2 tiles downloaded", call. = FALSE)
  }

  # Read + clip
  result_list <- list()
  for (nm in names(gml_files)) {
    gml_path <- gml_files[[nm]]
    try({
      g <- sf::st_read(gml_path, quiet = TRUE)
      g <- sf::st_transform(g, sf::st_crs(aoi_proj))
      clipped <- sf::st_intersection(g, aoi_proj)
      if (nrow(clipped) > 0) {
        result_list[[nm]] <- clipped
      }
    }, silent = TRUE)
    unlink(gml_path)
  }
  if (length(result_list) == 0) {
    stop("No LOD2 features intersected the AOI", call. = FALSE)
  }

  do.call(rbind, result_list)
}
