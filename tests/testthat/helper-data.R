# Small hand-made dataset with known ordering and significance.
#   row: 1 = negative, 2 = null, 3 = positive, 4 = null (population not reported)
toy_data <- function() {
  data.frame(
    es = c(-0.5, 0.0, 0.6, 0.1),
    lo = c(-0.8, -0.2, 0.3, -0.1),
    hi = c(-0.2, 0.2, 0.9, 0.3),
    pop = factor(c("Adults", "Children", "Adults", NA),
                 levels = c("Adults", "Children")),
    design = factor(c("RCT", "RCT", "Cohort", "Cohort"),
                    levels = c("RCT", "Cohort"))
  )
}

# plot_forestmap() with the toy data and a font that exists everywhere.
toy_plot <- function(...) {
  plot_forestmap(
    toy_data(), "es", "lo", "hi",
    moderators = c("Population" = "pop", "Design" = "design"),
    font = "sans", ...
  )
}

forest_panel <- function(p) p[[1]]
heatmap_panel <- function(p) p[[2]]

# toy_data() plus a numeric moderator with one missing value.
#   ranks (by es): row 1, row 2, row 4, row 3
toy_continuous <- function() {
  d <- toy_data()
  d$age <- c(20, 40, NA, 30)
  d
}

toy_cont_plot <- function(...) {
  plot_forestmap(
    toy_continuous(), "es", "lo", "hi",
    moderators = c("Population" = "pop", "Mean age" = "age"),
    font = "sans", ...
  )
}
