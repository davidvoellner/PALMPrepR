#' Process building vectors: clip, ID, split
#'
#' Clips building and bridges to an AOI, assigns sequential IDs,
#' and splits the dataset into buildings and bridges according
#' to the ALKIS function code. Handles polyhedral geometries
#' (e.g., from CityGML) with automatic conversion fallbacks.
#'
#' @param data An `sf` object containing buildings and bridges.
#' @param aoi An `sf` or `sfc` object defining the area of interest.
#' @param target_epsg Target CRS EPSG code (default: 25832).
#'
#' @return A named list with elements `buildings` and `bridges`
#'   (both `sf` objects with geometry normalized to MULTIPOLYGON).
#'
#' @details
#' If input contains unsupported geometry types (POLYHEDRALSURFACE, TIN):
#' 1. Attempts per-feature extraction to polygons
#' 2. Tries GDAL vectortranslate as fallback
#' 3. Provides clear error with conversion instructions if all fail
#'
#' @export
process_lod2 <- function(
  data,
  aoi,
  target_epsg = 25832
) {

  # --- Validation ---

  if (!inherits(data, "sf")) {
    stop("`data` must be an sf object.", call. = FALSE)
  }

  if (!inherits(aoi, c("sf", "sfc"))) {
    stop("`aoi` must be an sf or sfc object.", call. = FALSE)
  }

  if (is.na(sf::st_crs(data))) {
    stop("`data` must have a valid CRS.", call. = FALSE)
  }

  # --- Normalize geometries ---
  # drop Z/M and try to convert unsupported geometry types
  # (e.g. POLYHEDRALSURFACE / TIN) to MULTIPOLYGON.
  # If this fails, provide a clear error explaining WKB type 15.

  # drop Z/M dimensions where possible
  try({
    data <- sf::st_zm(data, drop = TRUE, what = "ZM")
  }, silent = TRUE)

  # detect geometry types present
  geom_types <- unique(as.character(sf::st_geometry_type(data)))

  # If polyhedral or tin geometries are present, try to cast to POLYGON/MULTIPOLYGON
  if (any(geom_types %in% c("POLYHEDRALSURFACE", "TIN"))) {
    cast_ok <- FALSE
    try({
      data <- sf::st_cast(data, "MULTIPOLYGON")
      cast_ok <- TRUE
    }, silent = TRUE)

    if (!cast_ok) {
      # Attempt a per-feature extraction of polygon faces from polyhedral geometries.
      failed_idx <- integer(0)
      new_geoms <- vector("list", nrow(data))
      for (i in seq_len(nrow(data))) {
        g <- sf::st_geometry(data)[[i]]
        gtype <- as.character(sf::st_geometry_type(g))

        if (gtype %in% c("POLYHEDRALSURFACE", "TIN")) {
          polys <- NULL
          # try casting to POLYGON first
          try({
            polys <- sf::st_cast(g, "POLYGON")
          }, silent = TRUE)

          # fallback to collection extract
          if (is.null(polys) || length(polys) == 0) {
            try({
              polys <- sf::st_collection_extract(g, "POLYGON")
            }, silent = TRUE)
          }

          if (is.null(polys) || length(polys) == 0) {
            failed_idx <- c(failed_idx, i)
            next
          }

          # merge faces and cast to MULTIPOLYGON
          merged <- NULL
          try({
            merged <- sf::st_union(polys)
          }, silent = TRUE)

          if (is.null(merged)) {
            # as last resort, combine without union
            merged <- sf::st_combine(polys)
          }

          new_geoms[[i]] <- sf::st_cast(merged, "MULTIPOLYGON")
        } else {
          # ensure non-polyhedral geometries are multipolygons
          g_conv <- NULL
          try({
            g_conv <- sf::st_cast(g, "MULTIPOLYGON")
          }, silent = TRUE)
          if (!is.null(g_conv)) {
            new_geoms[[i]] <- g_conv
          } else {
            new_geoms[[i]] <- g
          }
        }
      }

      if (length(failed_idx) > 0) {
        # Try GDAL/ogr2ogr conversion as a robust fallback: write temporary GPKG,
        # run vectortranslate to force MULTIPOLYGON, and read back.
        gdal_ok <- FALSE
        tmp_in <- tempfile(fileext = ".gpkg")
        tmp_out <- tempfile(fileext = ".gpkg")
        try({
          sf::st_write(data, tmp_in, delete_dsn = TRUE, quiet = TRUE)
          sf::gdal_utils(
            "vectortranslate",
            src_dataset = tmp_in,
            dst_dataset = tmp_out,
            options = c("-nlt", "MULTIPOLYGON", "-overwrite")
          )
          data_conv <- sf::st_read(tmp_out, quiet = TRUE)
          geom_after <- unique(as.character(sf::st_geometry_type(data_conv)))
          if (!all(geom_after %in% c("POLYGON", "MULTIPOLYGON", "MULTISURFACE"))) {
            stop("GDAL conversion did not produce polygon geometries", call. = FALSE)
          }
          data <- data_conv
          gdal_ok <- TRUE
        }, silent = TRUE)

        if (!gdal_ok) {
          stop(
            "Input `data` contains polyhedral geometries that could not be converted (feature indexes: ",
            paste(head(failed_idx, 10), collapse = ", "),
            if (length(failed_idx) > 10) " ...",
            ").\nAutomatic in-R extraction failed; GDAL/ogr2ogr conversion also failed or is not available.\n",
            "Please convert the layer externally (e.g. `ogr2ogr -f GPKG data_multipolygon.gpkg data.gpkg -nlt MULTIPOLYGON`) or use pre-cast (multi-)polygons.",
            call. = FALSE
          )
        }

      } else {
        # build new sfc and assign back to the sf object
        sfc_new <- sf::st_sfc(new_geoms, crs = sf::st_crs(data))
        sf::st_geometry(data) <- sfc_new
      }
    }
  }

  # --- CRS harmonization ---

  data <- sf::st_transform(data, target_epsg)
  aoi_geom  <- sf::st_transform(sf::st_geometry(aoi), target_epsg)

  # --- Clip to AOI ---

  data_clipped <- sf::st_intersection(data, aoi_geom)

  if (!nrow(data_clipped)) {
    stop("No features of `data` intersect with AOI.", call. = FALSE)
  }

  # --- Cast back to MULTIPOLYGON to preserve original geometry type ---

  data_clipped <- sf::st_cast(data_clipped, "MULTIPOLYGON")

  # --- Add sequential ID ---

  data_clipped <- .add_sequential_id(data_clipped)

  # --- Split buildings vs bridges ---

  .split_buildings_bridges(data_clipped)
}
