#' Rasterize all required bridge properties for PALM input
#'
#' Rasterizes bridge ID and height in a single operation.
#'
#' @param bridges An `sf` object with bridge polygons and properties.
#' @param template A `terra::SpatRaster` defining the output grid.
#'
#' @return A named list of two `terra::SpatRaster` objects:
#'   - `id`: Bridge ID
#'   - `height`: Bridge height (measuredHeight)
#'
#' @examples
#' \dontrun{
#' bridges <- res$bridges
#' rasters <- rasterize_bridges_palm(bridges, dem)
#'
#' rasters$id
#' rasters$height
#' }
#'
#' @export
rasterize_bridges_to_palm <- function(bridges, template) {

  # --- Validation ---

  if (!inherits(bridges, "sf")) {
    stop("`bridges` must be an sf object.", call. = FALSE)
  }

  if (!inherits(template, "SpatRaster")) {
    stop("`template` must be a terra::SpatRaster.", call. = FALSE)
  }

  required_cols <- c("ID", "measuredHeight")
  missing_cols <- setdiff(required_cols, names(bridges))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "),
         call. = FALSE)
  }

  # --- Rasterize properties ---

  list(
    id = terra::rasterize(
      bridges, template,
      field = "ID",
      fun = "max",
      touches = TRUE
    ),
    height = terra::rasterize(
      bridges, template,
      field = "measuredHeight",
      fun = "max",
      touches = TRUE
    )
  )

}