#' Rasterize all required building properties for PALM input
#'
#' Rasterizes building type, ID, and height in a single operation.
#'
#' @param buildings An `sf` object with building polygons and properties.
#' @param template A `terra::SpatRaster` defining the output grid.
#'
#' @return A named list of three `terra::SpatRaster` objects:
#'   - `type`: Building type classification (palm_type)
#'   - `id`: Building ID
#'   - `height`: Building height (measuredHeight)
#'
#' @examples
#' \dontrun{
#' buildings <- assign_palm_building_type(buildings, wsf)
#' rasters <- rasterize_buildings_palm(buildings, dem)
#'
#' rasters$type
#' rasters$id
#' rasters$height
#' }
#'
#' @export
rasterize_buildings_to_palm <- function(buildings, template) {

  # --- Validation ---

  if (!inherits(buildings, "sf")) {
    stop("`buildings` must be an sf object.", call. = FALSE)
  }

  if (!inherits(template, "SpatRaster")) {
    stop("`template` must be a terra::SpatRaster.", call. = FALSE)
  }

  required_cols <- c("palm_type", "ID", "measuredHeight")
  missing_cols <- setdiff(required_cols, names(buildings))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "),
         call. = FALSE)
  }

  # --- Rasterize all properties ---

  list(
    type = terra::rasterize(
      buildings, template,
      field = "palm_type",
      fun = "max",
      touches = TRUE
    ),
    id = terra::rasterize(
      buildings, template,
      field = "ID",
      fun = "max",
      touches = TRUE
    ),
    height = terra::rasterize(
      buildings, template,
      field = "measuredHeight",
      fun = "max",
      touches = TRUE
    )
  )

}