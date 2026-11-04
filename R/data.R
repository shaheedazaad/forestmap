#' Example meta-analysis data
#'
#' Made-up studies from a meta-analysis of an intervention: each study's
#' standardised mean difference and sampling variance (the `yi`/`vi` pair
#' that `metafor::escalc()` produces), its sample size, and four study
#' properties. Some studies don't report their outcome
#' measure or country (`NA`). Use it to try out [plot_forestmap()].
#'
#' @format A data frame with 60 rows (studies) and 8 columns:
#' \describe{
#'   \item{study}{Study label (first author and year).}
#'   \item{smd}{Standardised mean difference (Hedges' g).}
#'   \item{vi}{Sampling variance of `smd`.}
#'   \item{n}{Total sample size.}
#'   \item{population}{Factor: `Adults`, `Children` or `Clinical`.}
#'   \item{outcome}{Factor: `Self-report` or `Behavioural`; `NA` = not
#'     reported.}
#'   \item{design}{Factor: `RCT` or `Quasi-experimental`.}
#'   \item{country}{Factor: `USA`, `UK`, `Australia`, `Germany` or `Canada`;
#'     `NA` = not reported.}
#' }
#' @source Simulated; see `data-raw/forestmap_example.R` in the package source.
"forestmap_example"
