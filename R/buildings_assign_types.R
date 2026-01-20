# -------------------------------------------------------------------
#' Assign PALM building types using WSF Evolution data
#'
#' Assigns PALM building type classes based on ALKIS `function`
#' codes and maximum WSF Evolution construction year values
#' extracted per building footprint.
#'
#' @param buildings An `sf` object with building geometries.
#' @param wsf A `terra::SpatRaster` with WSF Evolution data.
#'
#' @return The input `sf` object with added columns
#'   `year_max` and `palm_type`.
#'
#' @examples
#' \dontrun{
#' bld <- process_building_vectors(buildings, aoi)$buildings
#' wsf <- download_wsf_data(aoi)
#'
#' bld <- assign_palm_building_type(bld, wsf)
#' }
#'
#' @export
assign_palm_building_type <- function(buildings, wsf) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

  if (!inherits(buildings, "sf")) {
    stop("`buildings` must be an sf object.", call. = FALSE)
  }

  if (!inherits(wsf, "SpatRaster")) {
    stop("`wsf` must be a terra::SpatRaster.", call. = FALSE)
  }

  if (is.na(sf::st_crs(buildings))) {
    stop("`buildings` must have a valid CRS.", call. = FALSE)
  }

  # ---------------------------------------------------------------
  # Geometry normalization
  # ---------------------------------------------------------------

  geom <- sf::st_geometry(buildings)

  geom_fixed <- lapply(geom, .force_multipolygon)
  valid <- !vapply(geom_fixed, is.null, logical(1))

  if (!any(valid)) {
    stop("No valid polygon geometries remain after normalization.",
         call. = FALSE)
  }

  buildings <- buildings[valid, ]
  sf::st_geometry(buildings) <- sf::st_sfc(geom_fixed[valid],
                                           crs = sf::st_crs(buildings))

  # ---------------------------------------------------------------
  # CRS harmonisation (terra-native)
  # ---------------------------------------------------------------

  buildings_vect <- terra::vect(buildings)
  buildings_vect <- terra::project(buildings_vect, terra::crs(wsf))

  # ---------------------------------------------------------------
  # Zonal statistics (max WSF value per building)
  # ---------------------------------------------------------------

  zs <- terra::extract(
    wsf,
    buildings_vect,
    fun = max,
    na.rm = TRUE
  )

  buildings$year_max <- ifelse(
    is.na(zs[, 2]),
    0,
    zs[, 2]
  )

  # ---------------------------------------------------------------
  # Classification
  # ---------------------------------------------------------------

  buildings$palm_type <- mapply(
    .classify_palm_type,
    buildings[["function."]],
    buildings$year_max
  )

  buildings
}
