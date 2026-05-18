#' Build PALM-4U static driver configuration file
#'
#' Creates a structured YAML configuration file for a PALM-4U static
#' driver. Input raster files are automatically discovered in
#' `input_root_path` based on predefined naming patterns unless
#' explicitly provided.
#'
#' The configuration file contains the following sections:
#' - `attributes`
#' - `settings`
#' - `output`
#' - `input_root`
#' - `domain_root`
#'
#' @param prefix Character string used as filename prefix.
#' @param output_dir Character directory where the YAML file is written.
#'
#' @param author Character string with author name and/or email.
#' @param contact_person Character string with contact details.
#' @param acronym Character project/site acronym.
#' @param comment Optional comment string.
#' @param data_content Character description of dataset.
#' @param location Character geographic location name.
#' @param site Character site name.
#' @param institution Character institution name.
#' @param palm_version Character PALM model version.
#' @param references Character references string.
#' @param source Character data source string.
#' @param origin_time Character or POSIXct timestamp.
#'
#' @param epsg Integer EPSG code.
#' @param season Character season ("summer", "winter", etc.).
#'
#' @param output_path Character path used inside the PALM model.
#' @param file_out Character output base name (without extension).
#' @param version Integer configuration version.
#'
#' @param input_root_path Character directory containing raster inputs.
#'
#' @param file_zt Character terrain height filename (optional).
#' @param file_buildings_2d Character building height filename (optional).
#' @param file_building_id Character building ID filename (optional).
#' @param file_building_type Character building type filename (optional).
#' @param file_bridges_2d Character bridge height filename (optional).
#' @param file_bridges_id Character bridge ID filename (optional).
#' @param file_vegetation_type Character vegetation type filename (optional).
#' @param file_vegetation_height Character vegetation height filename (optional).
#' @param file_tree_height Character tree height filename (optional).
#' @param file_tree_crown_diameter Character tree crown diameter filename (optional).
#' @param file_tree_trunk_diameter Character tree trunk diameter filename (optional).
#' @param file_tree_type Character tree type filename (optional).
#' @param file_lai Character LAI filename (optional).
#' @param file_water_type Character water type filename (optional).
#' @param file_pavement_type Character pavement type filename (optional).
#' @param file_soil_type Character soil type filename (optional).
#'
#' @param pixel_size Numeric grid resolution.
#' @param origin_x Numeric domain origin x-coordinate.
#' @param origin_y Numeric domain origin y-coordinate.
#' @param nx Integer grid size in x direction.
#' @param ny Integer grid size in y direction.
#' @param dz Numeric vertical resolution.
#' @param bridge_depth Numeric bridge depth (default 3.0).
#' @param buildings_3d Logical include 3D buildings.
#' @param street_trees Logical include street trees.
#' @param overhanging_trees Logical include overhanging trees.
#' @param generate_vegetation_patches Logical generate vegetation patches.
#'
#' @return Character path to the created YAML configuration file.
#'
#' @export
build_csd_configuration <- function(
  prefix = "static_driver",
  output_dir = getwd(),

  author = NA_character_,
  contact_person = NA_character_,
  acronym = NA_character_,
  comment = NA_character_,
  data_content = NA_character_,
  location = NA_character_,
  site = NA_character_,
  institution = NA_character_,
  palm_version = NA_character_,
  references = NA_character_,
  source = NA_character_,
  origin_time = Sys.time(),

  epsg = NA_integer_,
  season = NA_character_,

  output_path = NA_character_,
  file_out = NA_character_,
  version = 1,

  input_root_path,

  file_zt = NA_character_,
  file_buildings_2d = NA_character_,
  file_building_id = NA_character_,
  file_building_type = NA_character_,
  file_bridges_2d = NA_character_,
  file_bridges_id = NA_character_,
  file_vegetation_type = NA_character_,
  file_vegetation_height = NA_character_,
  file_tree_height = NA_character_,
  file_tree_crown_diameter = NA_character_,
  file_tree_trunk_diameter = NA_character_,
  file_tree_type = NA_character_,
  file_lai = NA_character_,
  file_water_type = NA_character_,
  file_pavement_type = NA_character_,
  file_soil_type = NA_character_,

  pixel_size,
  origin_x,
  origin_y,
  nx,
  ny,
  dz,
  bridge_depth = 3.0,
  buildings_3d = TRUE,
  street_trees = TRUE,
  overhanging_trees = TRUE,
  generate_vegetation_patches = TRUE
) {

  # --- Validation ---

  if (missing(input_root_path)) {
    stop("`input_root_path` must be provided.", call. = FALSE)
  }

  .validate_csd_directories(
    output_dir = output_dir,
    input_root_path = input_root_path
  )

  if (is.na(epsg)) {
    stop("`epsg` must be specified.", call. = FALSE)
  }

  if (is.na(pixel_size) || is.na(nx) || is.na(ny)) {
    stop("Domain parameters (`pixel_size`, `nx`, `ny`) must be provided.",
         call. = FALSE)
  }

  # --- Collect file arguments ---

  args <- as.list(environment())

  file_args <- args[grep("^file_", names(args))]

  file_args <- .auto_discover_input_files(
    input_root_path = input_root_path,
    files = file_args
  )

  # --- Build configuration list ---

  config_list <- .build_csd_list(args, file_args)

  # --- Write YAML ---

  config_path <- .write_csd_yaml(
    config_list = config_list,
    output_dir  = output_dir,
    prefix      = prefix
  )

  message("Configuration file written to: ", config_path)

  return(config_path)
}
