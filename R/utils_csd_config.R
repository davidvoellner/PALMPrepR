# --------------------------------------------------------------------
# CSD Configuration Utilities
# --------------------------------------------------------------------
# Helper functions for validating directories, auto-discovering
# input raster files, constructing structured configuration lists,
# and writing PALM-4U static driver YAML configuration files.
# --------------------------------------------------------------------


# --- Directory Validation ---

#' Validate input and output directories
#' @keywords internal
.validate_csd_directories <- function(output_dir, input_root_path) {

  if (!dir.exists(output_dir)) {
    stop("Output directory does not exist: ", output_dir, call. = FALSE)
  }

  if (!dir.exists(input_root_path)) {
    stop("Input directory does not exist: ", input_root_path, call. = FALSE)
  }

  invisible(TRUE)
}


# --- File Discovery ---

#' Check if file argument is missing
#' @keywords internal
.is_missing_file <- function(x) {
  is.null(x) || is.na(x) || identical(x, "")
}


#' Find first file in directory matching pattern
#' @keywords internal
.find_matching_file <- function(pattern, input_dir) {

  files <- list.files(
    input_dir,
    pattern = pattern,
    ignore.case = TRUE
  )

  if (length(files) == 0) {
    return(NA_character_)
  }

  files[1]
}


#' Auto-discover PALM input files based on naming patterns
#' @keywords internal
.auto_discover_input_files <- function(input_root_path, files) {

  patterns <- list(
    file_zt                   = "terrain_height|zt",
    file_buildings_2d         = "building_height|buildings_2d",
    file_building_id          = "building_id",
    file_building_type        = "building_type",
    file_bridges_2d           = "bridges_height|bridges_2d",
    file_bridges_id           = "bridges_id",
    file_vegetation_type      = "vegetation_type",
    file_vegetation_height    = "vegetation_height",
    file_tree_height          = "tree_height",
    file_tree_crown_diameter  = "tree_crown_diameter",
    file_tree_trunk_diameter  = "tree_trunk_diameter",
    file_tree_type            = "tree_type",
    file_lai                  = "lai|leaf_area_index",
    file_water_type           = "water_type",
    file_pavement_type        = "pavement_type",
    file_soil_type            = "soil_type"
  )

  for (name in names(patterns)) {

    if (.is_missing_file(files[[name]])) {

      files[[name]] <- .find_matching_file(
        pattern   = patterns[[name]],
        input_dir = input_root_path
      )
    }
  }

  files
}


# --- Configuration List Builder ---

#' Build structured CSD configuration list
#' @keywords internal
.build_csd_list <- function(args, files) {

  list(

    attributes = list(
      author        = args$author,
      contact_person = args$contact_person,
      acronym       = args$acronym,
      comment       = args$comment,
      data_content  = args$data_content,
      location      = args$location,
      site          = args$site,
      institution   = args$institution,
      palm_version  = args$palm_version,
      references    = args$references,
      source        = args$source,
      origin_time   = as.character(args$origin_time)
    ),

    settings = list(
      epsg   = args$epsg,
      season = args$season
    ),

    output = list(
      path     = args$output_path,
      file_out = args$file_out,
      version  = args$version
    ),

    input_root = c(
      list(path = args$input_root_path),
      files
    ),

    domain_root = list(
      pixel_size                 = args$pixel_size,
      origin_x                   = args$origin_x,
      origin_y                   = args$origin_y,
      nx                         = args$nx,
      ny                         = args$ny,
      dz                         = args$dz,
      bridge_depth               = args$bridge_depth,
      buildings_3d               = args$buildings_3d,
      street_trees               = args$street_trees,
      overhanging_trees          = args$overhanging_trees,
      generate_vegetation_patches = args$generate_vegetation_patches
    )
  )
}


# --- YAML Writer ---

#' Write CSD configuration YAML file
#' @keywords internal
.write_csd_yaml <- function(config_list, output_dir, prefix) {

  config_filename <- paste0(prefix, "_csd_configuration.yml")
  config_path <- file.path(output_dir, config_filename)

  # Write initial YAML
  yaml::write_yaml(config_list, config_path)

  # Read lines back for post-processing
  lines <- readLines(config_path)

  # Comment out NA file entries in input_root section
  for (i in seq_along(lines)) {

    # Match file_* entries with NA value
    if (grepl("^\\s+file_.*: NA$", lines[i])) {

      # Extract key name
      key <- sub("^\\s+(file_.*): NA$", "\\1", lines[i])

      # Replace with commented line
      lines[i] <- paste0("  # ", key, ": not found")
    }
  }

  writeLines(lines, config_path)

  config_path
}
