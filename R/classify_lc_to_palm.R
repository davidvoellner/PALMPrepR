#' Reclassify LC raster to PALM surface type rasters
#'
#' Converts a Land Cover raster to PALM-compatible vegetation, water,
#' and pavement type rasters using reclassification rules.
#'
#' @param data A `terra::SpatRaster` object with LC classification codes.
#' @param nodata_out The output NoData value (default: 255).
#' @param mapping Optional reclassification table.  Can be:
#'   * `NULL` (default) to use the built‑in rules described below;
#'   * a filename pointing to a text file (CSV/TSV) containing columns
#'     `surface`, `src`, and `dst`;
#'   * a data.frame with the same three columns.  The `surface` column
#'     indicates which of the three PALM raster layers (`vegetation`,
#'     `water`, `pavement`) the row applies to.
#'
#' @return A named list of three `terra::SpatRaster` objects:
#'   - `vegetation`: Vegetation type classification
#'   - `water`: Water type classification
#'   - `pavement`: Pavement type classification
#'
#' @details
#' When `mapping = NULL` the following default rules are applied:
#' - Vegetation: LC 4→3, 5→1, 8→1, 9→16, 10→17, 11→7
#' - Water: LC 2→1
#' - Pavement: LC 12→1, 6→13
#' 
#' A user‑provided mapping overrides these defaults.  An example of a CSV
#' file suitable for `mapping`:
#' 
#' ```csv
#' surface,src,dst
#' vegetation,4,3
#' vegetation,5,1
#' vegetation,8,1
#' vegetation,9,16
#' vegetation,10,17
#' vegetation,11,7
#' water,2,1
#' pavement,12,1
#' pavement,6,13
#' ```
#'
#' @examples
#' \dontrun{
#' lc <- rast("LC.tif")
#' 
#' # use built-in rules
#' palm_surfaces <- classify_lc_to_palm(lc)
#' 
#' # or read a simple conversion table
#' conv <- read.csv("lc_to_palm.csv")
#' palm_surfaces <- classify_lc_to_palm(lc, mapping = conv)
#' 
#' # file path also works
#' palm_surfaces <- classify_lc_to_palm(lc, mapping = "lc_to_palm.csv")
#' 
#' plot(palm_surfaces$vegetation)
#' plot(palm_surfaces$water)
#' plot(palm_surfaces$pavement)
#' }
#'
#' @export
classify_lc_to_palm <- function(data, nodata_out = 255,
                                   mapping = NULL) {

  # --- Validation ---
  if (!inherits(data, "SpatRaster")) {
    stop("`data` must be a terra::SpatRaster.", call. = FALSE)
  }

  # mapping may be
  # * NULL (use built‑in defaults),
  # * a path to a CSV file with columns `surface`, `src`, `dst`,
  # * a data.frame with the same three columns.
  # `surface` values must (for now) be one of "vegetation", "water", "pavement".

  build_rcl <- function(df) {
    # expect columns src, dst
    matrix(c(t(df[, c("src", "dst")])), ncol = 2, byrow = TRUE)
  }

  if (!is.null(mapping)) {
    if (is.character(mapping) && length(mapping) == 1) {
      # read file; try common delimiters
      mapping <- utils::read.table(mapping, header = TRUE, sep = ",",
                                   stringsAsFactors = FALSE)
    }
    if (!is.data.frame(mapping)) {
      stop("`mapping` must be NULL, a filename, or a data.frame.", call. = FALSE)
    }
    required <- c("surface", "src", "dst")
    if (!all(required %in% names(mapping))) {
      stop("`mapping` data must contain columns: ", paste(required, collapse = ", "),
           call. = FALSE)
    }
  }

  # --- Build reclassification tables ---
  if (is.null(mapping)) {
    # default rules as before
    veg_rcl <- matrix(c(
      4,  3,
      5,  1,
      8,  1,
      9,  16,
      10, 17,
      11, 7
    ), ncol = 2, byrow = TRUE)

    water_rcl <- matrix(c(
      2, 1
    ), ncol = 2, byrow = TRUE)

    pave_rcl <- matrix(c(
      12, 1,
      6,  13
    ), ncol = 2, byrow = TRUE)
  } else {
    veg_rcl <- build_rcl(subset(mapping, surface == "vegetation"))
    water_rcl <- build_rcl(subset(mapping, surface == "water"))
    pave_rcl <- build_rcl(subset(mapping, surface == "pavement"))
  }

  veg_raster <- terra::classify(data, veg_rcl, others = nodata_out)
  water_raster <- terra::classify(data, water_rcl, others = nodata_out)
  pave_raster <- terra::classify(data, pave_rcl, others = nodata_out)

  # Return list of rasters
  list(
    vegetation = veg_raster,
    water = water_raster,
    pavement = pave_raster
  )

}
