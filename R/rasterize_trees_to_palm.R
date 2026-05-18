#' Rasterize tree properties for PALM input
#'
#' Rasterizes:
#'   - tree height
#'   - tree type
#'
#' @param trees An `sf` object containing tree points.
#' @param template A `terra::SpatRaster` defining the target grid.
#' @param tree_type Integer PALM tree type value.
#'
#' @return A named list of rasters.
#'
#' @export
rasterize_trees_to_palm <- function(
  trees,
  template,
  tree_type = 0
) {

  # ------------------------------------------------
  # Validation
  # ------------------------------------------------

  if (!inherits(trees, "sf")) {

    stop(
      "`trees` must be an sf object.",
      call. = FALSE
    )
  }

  if (!inherits(template, "SpatRaster")) {

    stop(
      "`template` must be a terra::SpatRaster.",
      call. = FALSE
    )
  }

  required_cols <- c("baumhoehe")

  missing_cols <- setdiff(
    required_cols,
    names(trees)
  )

  if (length(missing_cols) > 0) {

    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  # ------------------------------------------------
  # Convert to SpatVector
  # ------------------------------------------------

  trees_vect <- terra::vect(trees)

  # ------------------------------------------------
  # Add constant PALM tree type
  # ------------------------------------------------

  trees_vect$tree_type <- tree_type

  # ------------------------------------------------
  # Rasterize
  # ------------------------------------------------

  list(

    height = terra::rasterize(
      trees_vect,
      template,
      field = "baumhoehe",
      fun = "max"
    ),

    type = terra::rasterize(
      trees_vect,
      template,
      field = "tree_type",
      fun = "max"
    )

  )
}