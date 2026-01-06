# -------------------------------------------------------------------
#' Process building vectors: clip, ID, split
#'
#' Clips building polygons to an AOI, assigns sequential IDs,
#' and splits the dataset into buildings and bridges according
#' to the ALKIS function code.
#'
#' @param buildings An `sf` object containing building polygons.
#' @param aoi An `sf` or `sfc` object defining the area of interest.
#' @param target_epsg Target CRS EPSG code (default: 25832).
#'
#' @return A named list with elements `buildings` and `bridges`
#'   (both `sf` objects).
#'
#' @examples
#' \dontrun{
#' bld <- sf::st_read("lod2_buildings.gpkg")
#' aoi <- sf::st_read("aoi.gpkg")
#'
#' res <- process_lod2(
#'   buildings = bld,
#'   aoi       = aoi
#' )
#'
#' res$buildings
#' res$bridges
#' }
#'
#' @export
process_lod2 <- function(
    buildings,
    aoi,
    target_epsg = 25832
) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

  if (!inherits(buildings, "sf")) {
    stop("`buildings` must be an sf object.", call. = FALSE)
  }

  if (!inherits(aoi, c("sf", "sfc"))) {
    stop("`aoi` must be an sf or sfc object.", call. = FALSE)
  }

  if (is.na(sf::st_crs(buildings))) {
    stop("`buildings` must have a valid CRS.", call. = FALSE)
  }

  # ---------------------------------------------------------------
  # CRS harmonization
  # ---------------------------------------------------------------

  buildings <- sf::st_transform(buildings, target_epsg)
  aoi_geom  <- sf::st_transform(sf::st_geometry(aoi), target_epsg)

  # ---------------------------------------------------------------
  # Clip to AOI
  # ---------------------------------------------------------------

  buildings_clipped <- sf::st_intersection(buildings, aoi_geom)

  if (!nrow(buildings_clipped)) {
    stop("No buildings intersect AOI.", call. = FALSE)
  }

  # ---------------------------------------------------------------
  # Add sequential ID
  # ---------------------------------------------------------------

  buildings_clipped <- .add_sequential_id(buildings_clipped)

  # ---------------------------------------------------------------
  # Split buildings vs bridges
  # ---------------------------------------------------------------

  .split_buildings_bridges(buildings_clipped)
}
