#' Download tree data for an AOI
#'
#' Downloads all tree datasets intersecting
#' an AOI, merges them, and clips the result.
#'
#' @param aoi An sf or sfc polygon object.
#'
#' @return An sf object containing tree points.
#'
#' @export
download_trees <- function(aoi) {

  # ------------------------------------------------
  # Validate AOI
  # ------------------------------------------------

  geom <- .validate_aoi(aoi)

  geom_25832 <- sf::st_transform(
    geom,
    25832
  )

  # ------------------------------------------------
  # Load spatial index
  # ------------------------------------------------

  idx <- .load_tree_index()

  # ------------------------------------------------
  # Find intersecting datasets
  # ------------------------------------------------

  hits <- sf::st_intersects(
    idx,
    geom_25832,
    sparse = FALSE
  )[, 1]

  idx_sel <- idx[hits, ]

  if (!nrow(idx_sel)) {

    stop(
      "No tree datasets intersect AOI.",
      call. = FALSE
    )
  }

  # ------------------------------------------------
  # Download + read datasets
  # ------------------------------------------------

  pb <- utils::txtProgressBar(
    min = 0,
    max = nrow(idx_sel),
    style = 3
  )

  on.exit(close(pb), add = TRUE)

  trees <- lapply(
    seq_len(nrow(idx_sel)),
    function(i) {

      url <- idx_sel$url[i]

      tmp <- .download_tree_dataset(
        url
      )

      x <- tryCatch({

        layers <- sf::st_layers(tmp)$name

        parts <- lapply(
          layers,
          function(lyr) {

            sf::st_read(
              tmp,
              layer = lyr,
              quiet = TRUE
            )
          }
        )

        do.call(
          rbind,
          parts
        )

      }, error = function(e) {

        warning(
          "Failed to read dataset: ",
          basename(url)
        )

        NULL
      })

      utils::setTxtProgressBar(
        pb,
        i
      )

      x
    }
  )

  # ------------------------------------------------
  # Remove failed datasets
  # ------------------------------------------------

  trees <- trees[
    !vapply(
      trees,
      is.null,
      logical(1)
    )
  ]

  if (!length(trees)) {

    stop(
      "No tree datasets could be read.",
      call. = FALSE
    )
  }

  # ------------------------------------------------
  # Merge
  # ------------------------------------------------

  trees <- do.call(
    rbind,
    trees
  )

  # ------------------------------------------------
  # Clip to AOI
  # ------------------------------------------------

  trees <- sf::st_intersection(
    trees,
    geom_25832
  )

  trees
}