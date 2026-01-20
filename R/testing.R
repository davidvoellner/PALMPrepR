library(sf)
library(terra)

aoi <- st_read("inst/extdata/small_aoi.gpkg")
wsf <- download_wsf_data(aoi)
lc <- rast("inst/extdata/LC.tif")
dem <- rast("inst/extdata/DEM.tif")
lod2 <- st_read("inst/extdata/lod2.gpkg")

raster_list <- list(
  DEM = dem,
  LC  = lc,
  WSF = wsf
)

out <- process_rasters(
  aoi         = aoi,
  target_epsg = 25832,
  resolution  = 100,
  rasters     = raster_list
)

# -------------------------------
lod2_multipolygon <- st_read("inst/extdata/lod2_multipolygon.gpkg")
res <- process_lod2(buildings = lod2_multipolygon, aoi = aoi)

summary(lod2_multipolygon)
summary(res$buildings)

run_ogr2ogr <- function(src, dst, nlt = "MULTIPOLYGON", ogr2ogr_path = NULL, extra = character()) {
  if (is.null(ogr2ogr_path) || ogr2ogr_path == "") {
    ogr2ogr_path <- Sys.which("ogr2ogr")
    if (ogr2ogr_path == "") {
      candidates <- c(
        "C:/OSGeo4W64/bin/ogr2ogr.exe",
        "C:/OSGeo4W/bin/ogr2ogr.exe",
        "C:/OSGeo4W64/apps/gdal/bin/ogr2ogr.exe"
      )
      ogr2ogr_path <- Filter(file.exists, candidates)[1]
      if (is.null(ogr2ogr_path)) stop("ogr2ogr not found; set `ogr2ogr_path` or add it to PATH", call. = FALSE)
    }
  }
  args <- c("-f", "GPKG", dst, src, "-nlt", nlt, extra)
  out <- system2(ogr2ogr_path, args = args, stdout = TRUE, stderr = TRUE)
  invisible(out)
}

# direct conversion (recommended)
run_ogr2ogr("inst/extdata/lod2.gpkg", "inst/extdata/lod2_multipolygon.gpkg")

# check ogr2ogr location / version
Sys.which("ogr2ogr")
system2(ifelse(Sys.which("ogr2ogr")!="", Sys.which("ogr2ogr"), "ogr2ogr"),
        args = "--version", stdout = TRUE, stderr = TRUE)


# change functions that it calls the right attribute from lod2 layer ("function.")