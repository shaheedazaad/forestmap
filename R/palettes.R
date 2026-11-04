#' Colour palettes for forestmap plots
#'
#' Ready-made palettes that can be passed by name to the `palette` argument of
#' [plot_forestmap()]. Each palette has three colours:
#'
#' * `positive`: the 95% CI lies entirely above the null value.
#' * `negative`: the 95% CI lies entirely below the null value.
#' * `null`: the 95% CI includes the null value.
#'
#' @format A named list of named character vectors (hex colours):
#' \describe{
#'   \item{default}{Blue / red / grey.}
#'   \item{okabe_ito}{Blue and vermillion from the Okabe-Ito palette
#'     (Okabe & Ito, 2008), designed to stay distinguishable with common
#'     colour-vision deficiencies; light grey for null.}
#'   \item{viridis}{Teal / purple / grey.}
#'   \item{greyscale}{Black / dark grey / light grey, for print.}
#' }
#' @examples
#' names(forestmap_palettes)
#' forestmap_palettes$okabe_ito
#' @export
forestmap_palettes <- list(
  default     = c(positive = "#0571b0", negative = "#ca0020", null = "#bdbdbd"),
  okabe_ito   = c(positive = "#0072B2", negative = "#D55E00", null = "#bdbdbd"),
  viridis     = c(positive = "#21908C", negative = "#440154", null = "#c7c7c7"),
  greyscale   = c(positive = "#000000", negative = "#6b6b6b", null = "#cfcfcf")
)

# Turn a palette name or a vector of three colours into a named
# c(positive, negative, null) vector.
resolve_palette <- function(palette) {
  if (is.character(palette) && length(palette) == 1L &&
      palette %in% names(forestmap_palettes)) {
    return(forestmap_palettes[[palette]])
  }
  if (is.character(palette) && length(palette) == 3L && !anyNA(palette)) {
    if (is.null(names(palette))) {
      names(palette) <- c("positive", "negative", "null")
    }
    if (!setequal(names(palette), c("positive", "negative", "null"))) {
      stop(
        "A custom `palette` needs three colours named positive, negative and null.",
        call. = FALSE
      )
    }
    bad <- !vapply(palette, is_colour, logical(1))
    if (any(bad)) {
      stop(sprintf(
        "Not a valid colour in `palette`: %s",
        paste(palette[bad], collapse = ", ")
      ), call. = FALSE)
    }
    return(palette[c("positive", "negative", "null")])
  }
  stop(sprintf(
    "`palette` must be one of %s, or three colours c(positive = , negative = , null = ).",
    paste0('"', names(forestmap_palettes), '"', collapse = ", ")
  ), call. = FALSE)
}

is_colour <- function(x) {
  tryCatch({
    grDevices::col2rgb(x)
    TRUE
  }, error = function(e) FALSE)
}
