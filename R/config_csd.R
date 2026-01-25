#' Create PALM-4U Static Driver Configuration File
#'
#' Generates a YAML configuration file for PALM-4U static driver with all required
#' sections: attributes, settings, output, input paths, and domain definition.
#'
#' @param prefix Character string for output filename prefix (default: "static_driver")
#' @param output_dir Character string for output directory path
#'
#' @section Attributes Parameters:
#' @param author Character string with author name and email
#' @param contact_person Character string with contact person(s) name(s) and email(s)
#' @param acronym Character string for site acronym
#' @param comment Character string for additional comments
#' @param data_content Character string describing data content
#' @param location Character string for geographic location
#' @param site Character string for site name
#' @param institution Character string for institution name
#' @param palm_version Character string for PALM version
#' @param references Character string for references
#' @param source Character string for data source(s)
#' @param origin_time Character string for origin time in format "YYYY-MM-DD HH:MM:SS +00"
#'
#' @section Settings Parameters:
#' @param epsg Integer EPSG code for coordinate system
#' @param season Character string for season ("summer", "winter", etc.)
#'
#' @section Output Parameters:
#' @param output_path Character string for output directory path for processed files
#' @param file_out Character string for output filename (without extension)
#' @param version Integer for version number
#'
#' @section Input Parameters:
#' @param input_root_path Character string for input root directory path. Files are auto-discovered
#'   in this folder based on naming patterns (e.g., *terrain_height.tif, *building_height.tif).
#' @param file_zt Character string for terrain height file name. If empty (default), auto-discovered.
#' @param file_buildings_2d Character string for building height file name. If empty, auto-discovered.
#' @param file_building_id Character string for building ID file name. If empty, auto-discovered.
#' @param file_building_type Character string for building type file name. If empty, auto-discovered.
#' @param file_bridges_2d Character string for bridges height file name. If empty, auto-discovered.
#' @param file_bridges_id Character string for bridges ID file name. If empty, auto-discovered.
#' @param file_vegetation_type Character string for vegetation type file name. If empty, auto-discovered.
#' @param file_vegetation_height Character string for vegetation height file name. If empty, auto-discovered.
#' @param file_tree_height Character string for tree height file name. If empty, auto-discovered.
#' @param file_tree_crown_diameter Character string for tree crown diameter file name. If empty, auto-discovered.
#' @param file_tree_trunk_diameter Character string for tree trunk diameter file name. If empty, auto-discovered.
#' @param file_tree_type Character string for tree type file name. If empty, auto-discovered.
#' @param file_lai Character string for leaf area index file name (optional, auto-discovered if present).
#' @param file_water_type Character string for water type file name. If empty, auto-discovered.
#' @param file_pavement_type Character string for pavement type file name. If empty, auto-discovered.
#' @param file_soil_type Character string for soil type file name (optional, auto-discovered if present).
#'
#' @section Domain Parameters:
#' @param pixel_size Numeric, pixel/grid size in meters (default: 1.0)
#' @param origin_x Numeric, x-coordinate of domain origin
#' @param origin_y Numeric, y-coordinate of domain origin
#' @param nx Integer, number of grid points in x direction
#' @param ny Integer, number of grid points in y direction
#' @param dz Numeric, vertical grid spacing (default: 1.0)
#' @param bridge_depth Numeric, bridge depth in meters (default: 3.0)
#' @param buildings_3d Logical, include 3D buildings (default: TRUE)
#' @param street_trees Logical, include street trees (default: TRUE)
#' @param overhanging_trees Logical, include overhanging trees (default: TRUE)
#' @param generate_vegetation_patches Logical, generate vegetation patches (default: TRUE)
#'
#' @return Character string with path to created configuration file
#'
#' @examples
#' \dontrun{
#' create_csd_configuration(
#'   prefix = "MUC",
#'   output_dir = "/path/to/output",
#'   author = "name, email",
#'   contact_person = "name, email",
#'   acronym = "MUC",
#'   data_content = "description of data content",
#'   location = "location name",
#'   institution = "institute name",
#'   origin_time = "string in format YYYY-MM-DD HH:MM:SS +00",
#'   epsg = 25832,
#'   season = "summer",
#'   output_path = "/path/to/output",
#'   file_out = "output_filename",
#'   input_root_path = "inst/extdata/processed_rasters"
#'   # All files are auto-discovered from input_root_path
#' )
#' }
#' @export
create_csd_configuration <- function(
    # Identification
    prefix = "static_driver",
    output_dir = getwd(),
    
    # Attributes
    author = "",
    contact_person = "",
    acronym = "",
    comment = "",
    data_content = "",
    location = "",
    site = "",
    institution = "",
    palm_version = "",
    references = "",
    source = "",
    origin_time = "",
    
    # Settings
    epsg = 25832,
    season = "summer",
    
    # Output
    output_path = "",
    file_out = "",
    version = 1,
    
    # Input root
    input_root_path = "",
    file_zt = "",
    file_buildings_2d = "",
    file_building_id = "",
    file_building_type = "",
    file_bridges_2d = "",
    file_bridges_id = "",
    file_vegetation_type = "",
    file_vegetation_height = "",
    file_tree_height = "",
    file_tree_crown_diameter = "",
    file_tree_trunk_diameter = "",
    file_tree_type = "",
    file_lai = NA_character_,
    file_water_type = "",
    file_pavement_type = "",
    file_soil_type = NA_character_,
    
    # Domain
    pixel_size = 1.0,
    origin_x = NA_real_,
    origin_y = NA_real_,
    nx = NA_integer_,
    ny = NA_integer_,
    dz = 1.0,
    bridge_depth = 3.0,
    buildings_3d = TRUE,
    street_trees = TRUE,
    overhanging_trees = TRUE,
    generate_vegetation_patches = TRUE
) {
  
  # Check output directory exists
  if (!dir.exists(output_dir)) {
    stop("Output directory does not exist: ", output_dir)
  }
  
  # Check input directory exists
  if (!dir.exists(input_root_path)) {
    stop("Input directory does not exist: ", input_root_path)
  }
  
  # Helper function to find file matching pattern
  find_file <- function(pattern, input_dir) {
    files <- list.files(input_dir, pattern = pattern, ignore.case = TRUE)
    if (length(files) == 0) {
      return("")
    }
    return(files[1])  # Return first match if multiple
  }
  
  # Auto-discover files if not manually provided
  if (file_zt == "") {
    file_zt <- find_file("terrain_height|zt", input_root_path)
  }
  if (file_buildings_2d == "") {
    file_buildings_2d <- find_file("building_height|buildings_2d", input_root_path)
  }
  if (file_building_id == "") {
    file_building_id <- find_file("building_id", input_root_path)
  }
  if (file_building_type == "") {
    file_building_type <- find_file("building_type", input_root_path)
  }
  if (file_bridges_2d == "") {
    file_bridges_2d <- find_file("bridges_height|bridges_2d", input_root_path)
  }
  if (file_bridges_id == "") {
    file_bridges_id <- find_file("bridges_id", input_root_path)
  }
  if (file_vegetation_type == "") {
    file_vegetation_type <- find_file("vegetation_type", input_root_path)
  }
  if (file_vegetation_height == "") {
    file_vegetation_height <- find_file("vegetation_height", input_root_path)
  }
  if (file_tree_height == "") {
    file_tree_height <- find_file("tree_height", input_root_path)
  }
  if (file_tree_crown_diameter == "") {
    file_tree_crown_diameter <- find_file("tree_crown_diameter", input_root_path)
  }
  if (file_tree_trunk_diameter == "") {
    file_tree_trunk_diameter <- find_file("tree_trunk_diameter", input_root_path)
  }
  if (file_tree_type == "") {
    file_tree_type <- find_file("tree_type", input_root_path)
  }
  if (is.na(file_lai)) {
    file_lai_found <- find_file("lai|leaf_area_index", input_root_path)
    if (file_lai_found != "") {
      file_lai <- file_lai_found
    }
  }
  if (file_water_type == "") {
    file_water_type <- find_file("water_type", input_root_path)
  }
  if (file_pavement_type == "") {
    file_pavement_type <- find_file("pavement_type", input_root_path)
  }
  if (is.na(file_soil_type)) {
    file_soil_found <- find_file("soil_type", input_root_path)
    if (file_soil_found != "") {
      file_soil_type <- file_soil_found
    }
  }
  
  # Create filename
  config_filename <- paste0(prefix, "_csd_configuration.yml")
  config_path <- file.path(output_dir, config_filename)
  
  # Helper function to format file entries (comment out if not found)
  format_file_entry <- function(filename, prefix_comment = "") {
    if (filename == "") {
      return(paste0("  # ", prefix_comment, "not found\n"))
    }
    return(paste0("  ", prefix_comment, filename, "\n"))
  }
  
  # Build YAML content as string
  yaml_content <- paste0(
    "# -*- coding: utf-8 -*-\n",
    "#---------------------------------------------------------------------------#\n",
    "# PALM-4U static driver configuration for ", acronym, " (", 
    pixel_size, " m resolution)\n",
    "#---------------------------------------------------------------------------#\n",
    "# Attributes section\n",
    "#---------------------------------------------------------------------------#\n",
    "attributes:\n",
    "  author: ", author, "\n",
    "  contact_person: ", contact_person, "\n",
    "  acronym: ", acronym, "\n",
    "  comment: ", comment, "\n",
    "  data_content: ", data_content, "\n",
    "  location: ", location, "\n",
    "  site: ", site, "\n",
    "  institution: ", institution, "\n",
    "  palm_version: ", palm_version, "\n",
    "  references: ", references, "\n",
    "  source: ", source, "\n",
    "  origin_time: \"", origin_time, "\"\n",
    "\n",
    "#---------------------------------------------------------------------------#\n",
    "# Settings section\n",
    "#---------------------------------------------------------------------------#\n",
    "settings:\n",
    "  epsg: ", epsg, "\n",
    "  season: ", season, "\n",
    "\n",
    "#---------------------------------------------------------------------------#\n",
    "# Output section\n",
    "#---------------------------------------------------------------------------#\n",
    "output:\n",
    "  path: ", output_path, "\n",
    "  file_out: ", file_out, "\n",
    "  version: ", version, "\n",
    "\n",
    "#---------------------------------------------------------------------------#\n",
    "# Input section\n",
    "#---------------------------------------------------------------------------#\n",
    "input_root:\n",
    "  # input directory\n",
    "  path: ", input_root_path, "\n",
    "  \n",
    "  # terrain\n",
    if (file_zt == "") "  # file_zt: not found\n" else paste0("  file_zt: ", file_zt, "\n"),
    "\n",
    "  # buildings LOD1\n",
    if (file_buildings_2d == "") "  # file_buildings_2d: not found\n" else paste0("  file_buildings_2d: ", file_buildings_2d, "\n"),
    if (file_building_id == "") "  # file_building_id: not found\n" else paste0("  file_building_id: ", file_building_id, "\n"),
    if (file_building_type == "") "  # file_building_type: not found\n" else paste0("  file_building_type: ", file_building_type, "\n"),
    " \n",
    "  # bridges\n",
    if (file_bridges_2d == "") "  # file_bridges_2d: not found\n" else paste0("  file_bridges_2d: ", file_bridges_2d, "\n"),
    if (file_bridges_id == "") "  # file_bridges_id: not found\n" else paste0("  file_bridges_id: ", file_bridges_id, "\n"),
    "  \n",
    "  # vegetation\n",
    if (file_vegetation_type == "") "  # file_vegetation_type: not found\n" else paste0("  file_vegetation_type: ", file_vegetation_type, "\n"),
    if (file_vegetation_height == "") "  # file_vegetation_height: not found\n" else paste0("  file_vegetation_height: ", file_vegetation_height, "\n"),
    "\n",
    "  # resolved vegetation (trees)\n",
    if (file_tree_height == "") "  # file_tree_height: not found\n" else paste0("  file_tree_height: ", file_tree_height, "\n"),
    if (file_tree_crown_diameter == "") "  # file_tree_crown_diameter: not found\n" else paste0("  file_tree_crown_diameter: ", file_tree_crown_diameter, "\n"),
    if (file_tree_trunk_diameter == "") "  # file_tree_trunk_diameter: not found\n" else paste0("  file_tree_trunk_diameter: ", file_tree_trunk_diameter, "\n"),
    if (file_tree_type == "") "  # file_tree_type: not found\n" else paste0("  file_tree_type: ", file_tree_type, "\n")
  )
  
  # Add optional LAI file
  if (!is.na(file_lai) && file_lai != "") {
    yaml_content <- paste0(yaml_content, "  file_lai: ", file_lai, "\n")
  } else {
    yaml_content <- paste0(yaml_content, "  # file_lai: not found\n")
  }
  
  yaml_content <- paste0(
    yaml_content,
    "  \n",
    "  # water\n",
    if (file_water_type == "") "  # file_water_type: not found\n" else paste0("  file_water_type: ", file_water_type, "\n"),
    "\n",
    "  # pavement\n",
    if (file_pavement_type == "") "  # file_pavement_type: not found\n" else paste0("  file_pavement_type: ", file_pavement_type, "\n"),
    "  \n"
  )
  
  # Add optional soil file
  if (!is.na(file_soil_type) && file_soil_type != "") {
    yaml_content <- paste0(yaml_content, "  file_soil_type: ", file_soil_type, "\n")
  } else {
    yaml_content <- paste0(yaml_content, "  # file_soil_type: not found\n")
  }
  
  yaml_content <- paste0(
    yaml_content,
    "\n\n",
    "#---------------------------------------------------------------------------#\n",
    "# Domain definition (root domain)\n",
    "# NOTE:\n",
    "# The here defined domain needs to be completely within the boundaries of the data. \n",
    "# Palm-4U cannot handle non-rectangular domains\n",
    "#---------------------------------------------------------------------------#\n",
    "domain_root:\n",
    "  pixel_size: ", pixel_size, "\n",
    "  origin_x: ", origin_x, "\n",
    "  origin_y: ", origin_y, "\n",
    "  nx: ", nx, "\n",
    "  ny: ", ny, "\n",
    "  dz: ", dz, "\n",
    "  bridge_depth: ", bridge_depth, "\n",
    "  buildings_3d: ", tolower(as.character(buildings_3d)), "\n",
    "  street_trees: ", tolower(as.character(street_trees)), "\n",
    "  overhanging_trees: ", tolower(as.character(overhanging_trees)), "\n",
    "  generate_vegetation_patches: ", tolower(as.character(generate_vegetation_patches)), "\n"
  )
  
  # Write to file
  writeLines(yaml_content, con = config_path)
  
  message("Configuration file created: ", config_path)
  
  return(config_path)
}
