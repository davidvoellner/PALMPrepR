# -------------------------------------------------------------------
#' Rasterize building properties to a regular grid
#'
#' Converts vector building data to raster format, assigning building
#' properties (type, height, etc.) to grid cells.
#'
#' @param buildings An `sf` object with building polygons and properties.
#' @param template A `terra::SpatRaster` defining the output grid.
#' @param property The column name to rasterize (e.g., "palm_type", "HoeheGrund").
#' @param fun The aggregation function for cells with multiple buildings
#'   (default: "max" - useful for building types and heights).
#'
#' @return A `terra::SpatRaster` with building properties rasterized to the grid.
#'
#' @examples
#' \dontrun{
#' buildings <- assign_palm_building_type(buildings, wsf)
#' palm_type_raster <- rasterize_buildings(
#'   buildings = buildings,
#'   template = dem,
#'   property = "palm_type"
#' )
#' }
#'
#' @export
rasterize_buildings <- function(buildings, template, property, fun = "max") {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

  if (!inherits(buildings, "sf")) {
    stop("`buildings` must be an sf object.", call. = FALSE)
  }

  if (!inherits(template, "SpatRaster")) {
    stop("`template` must be a terra::SpatRaster.", call. = FALSE)
  }

  if (!property %in% names(buildings)) {
    stop("Column '", property, "' not found in buildings data.", call. = FALSE)
  }

  # ---------------------------------------------------------------
  # Rasterize
  # ---------------------------------------------------------------

  rasterized <- terra::rasterize(
    buildings,
    template,
    field = property,
    fun = fun
  )

  rasterized

}

# -------------------------------------------------------------------
#' Rasterize all building properties for PALM input
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
rasterize_buildings_palm <- function(buildings, template) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

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

  # ---------------------------------------------------------------
  # Rasterize all properties
  # ---------------------------------------------------------------

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

# -------------------------------------------------------------------
#' Rasterize bridge properties for PALM input
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
rasterize_bridges_palm <- function(bridges, template) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

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

  # ---------------------------------------------------------------
  # Rasterize properties
  # ---------------------------------------------------------------

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