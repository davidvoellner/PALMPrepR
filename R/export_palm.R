# -------------------------------------------------------------------
#' Export rasters to GeoTIFF with PALM naming convention
#'
#' Exports multiple raster layers to GeoTIFF files with a standardized
#' naming convention: `{prefix}_{objectname}_{resolution}.tif`
#'
#' @param rasters A named list of `terra::SpatRaster` objects to export.
#'   Names become the object name in the output filename.
#' @param output_dir Directory where TIF files will be saved.
#' @param prefix A prefix for all output filenames (e.g., "MUC").
#' @param resolution Spatial resolution in map units. If NULL, will be
#'   extracted from the first raster.
#'
#' @return Invisibly returns a data frame with export details (filename, path).
#'
#' @examples
#' \dontrun{
#' # Export building rasters
#' building_list <- list(
#'   building_id = building_rasters$id,
#'   building_type = building_rasters$type,
#'   building_height = building_rasters$height
#' )
#' 
#' export_to_palm(
#'   rasters = building_list,
#'   output_dir = "output",
#'   prefix = "MUC",
#'   resolution = 10
#' )
#' }
#'
#' @export
export_to_palm <- function(rasters, output_dir, prefix, resolution = NULL) {

  # ---------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------

  if (!is.list(rasters) || length(rasters) == 0) {
    stop("`rasters` must be a non-empty named list.", call. = FALSE)
  }

  if (is.null(names(rasters)) || any(names(rasters) == "")) {
    stop("`rasters` must be a named list.", call. = FALSE)
  }

  if (!all(vapply(rasters, inherits, logical(1), "SpatRaster"))) {
    stop("All elements of `rasters` must be terra::SpatRaster objects.",
         call. = FALSE)
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # ---------------------------------------------------------------
  # Get resolution if not provided
  # ---------------------------------------------------------------

  if (is.null(resolution)) {
    first_raster <- rasters[[1]]
    res_vals <- terra::res(first_raster)
    resolution <- round(res_vals[1])  # Use first resolution value
  }

  # ---------------------------------------------------------------
  # Export each raster
  # ---------------------------------------------------------------

  export_info <- data.frame(
    objectname = character(0),
    filename = character(0),
    filepath = character(0),
    stringsAsFactors = FALSE
  )

  for (i in seq_along(rasters)) {
    objectname <- names(rasters)[i]
    filename <- sprintf("%s_%s_%d.tif", prefix, objectname, resolution)
    filepath <- file.path(output_dir, filename)

    terra::writeRaster(
      rasters[[i]],
      filepath,
      overwrite = TRUE
    )

    export_info <- rbind(
      export_info,
      data.frame(
        objectname = objectname,
        filename = filename,
        filepath = filepath,
        stringsAsFactors = FALSE
      )
    )

    message("Exported: ", filename)
  }

  message("\nAll rasters exported to: ", output_dir)
  invisible(export_info)

}
