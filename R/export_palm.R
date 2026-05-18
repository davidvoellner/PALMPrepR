#' Export raster list to GeoTIFFs with PALM naming convention
#'
#' Exports multiple raster layers to GeoTIFF files with a standardized
#' naming convention: `{prefix}_{objectname}_{suffix}.tif`
#'
#' @param data A named list of `terra::SpatRaster` objects to export.
#'   Names become the object name in the output filename.
#' @param output_dir Directory where TIF files will be saved.
#' @param prefix A prefix for all output filenames (e.g., "MUC").
#' @param suffix Spatial resolution in map units (e.g. Meters). If NULL,
#' the resolution will be extracted from the first raster.
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
#'   data = building_list,
#'   output_dir = "output",
#'   prefix = "prefix",
#'   suffix = 10
#' )
#' }
#'
#' @export
export_to_palm <- function(data, output_dir, prefix, suffix = NULL) {

  # --- Validation ---

  if (!is.list(data) || length(data) == 0) {
    stop("`data` must be a non-empty named list of `terra::SpatRaster`.", call. = FALSE)
  }

  if (is.null(names(data)) || any(names(data) == "")) {
    stop("`data` must be a named list of `terra::SpatRaster`.", call. = FALSE)
  }

  if (!all(vapply(data, inherits, logical(1), "SpatRaster"))) {
    stop("All elements of `data` must be terra::SpatRaster objects.",
         call. = FALSE)
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # --- Get resolution if not provided ---

  if (is.null(suffix)) {
    first_raster <- data[[1]]
    res_vals <- terra::res(first_raster)
    suffix <- round(res_vals[1])  # Use first resolution value
  }

  # --- Export each raster ---

  export_info <- data.frame(
    objectname = character(0),
    filename = character(0),
    filepath = character(0),
    stringsAsFactors = FALSE
  )

  for (i in seq_along(data)) {
    objectname <- names(data)[i]
    filename <- sprintf("%s_%s_%d.tif", prefix, objectname, suffix)
    filepath <- file.path(output_dir, filename)

    terra::writeRaster(
      data[[i]],
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

  message("\nAll rasters successfully exported to: ", output_dir)
  invisible(export_info)

}
