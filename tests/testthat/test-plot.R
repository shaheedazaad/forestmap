test_that("plot_forestmap returns a two-panel patchwork", {
  p <- toy_plot()
  expect_s3_class(p, "patchwork")
  expect_length(p, 2)
  expect_s3_class(forest_panel(p), "ggplot")
  expect_s3_class(heatmap_panel(p), "ggplot")
})

test_that("the example data plots without messages or warnings", {
  expect_no_condition(
    p <- plot_forestmap(
      forestmap_example, "smd", "ci_lower", "ci_upper",
      moderators = c("population", "outcome", "design", "country"),
      font = "sans"
    )
  )
  expect_equal(nrow(forest_panel(p)$data), nrow(forestmap_example))
})

test_that("plots render without error", {
  for (layout in c("standard", "compact")) {
    p <- toy_plot(layout = layout, rope = 0.1)
    path <- withr::local_tempfile(fileext = ".png")
    expect_no_error(ggplot2::ggsave(path, p, width = 5, height = 4, dpi = 50))
    expect_true(file.exists(path))
  }
})

test_that("the curve is sorted and coloured by significance", {
  p <- toy_plot()
  d <- forest_panel(p)$data
  expect_equal(d$estimate, sort(toy_data()$es))
  expect_equal(d$sign_label, c("negative", "null", "null", "positive"))
})

test_that("default and custom axis labels are used", {
  p <- toy_plot()
  expect_equal(heatmap_panel(p)$labels$x, "Effect")
  expect_equal(forest_panel(p)$labels$y, "Effect size")

  p <- toy_plot(x_label = "Specification", y_label = "Hedges' g")
  expect_equal(heatmap_panel(p)$labels$x, "Specification")
  expect_equal(forest_panel(p)$labels$y, "Hedges' g")
})

test_that("palette colours are used for the curve and the heatmap", {
  p <- toy_plot(palette = c(positive = "green", negative = "purple", null = "grey50"))
  curve_build <- ggplot2::ggplot_build(forest_panel(p))
  point_colours <- curve_build$data[[length(curve_build$data)]]$colour
  expect_equal(point_colours, c("purple", "grey50", "grey50", "green"))

  heat_build <- ggplot2::ggplot_build(heatmap_panel(p))
  expect_true(all(c("purple", "green", "#f0f0f0") %in% heat_build$data[[1]]$fill))
})

test_that("rope adds a shaded band and dotted lines", {
  layers <- function(p) {
    vapply(forest_panel(p)$layers, function(l) class(l$geom)[1], character(1))
  }
  expect_false("GeomRect" %in% layers(toy_plot()))
  with_rope <- layers(toy_plot(rope = c(-0.1, 0.1)))
  expect_true("GeomRect" %in% with_rope)
  expect_equal(sum(with_rope == "GeomHline"), 2)
})

test_that("a single rope number is symmetric around null_value", {
  p <- toy_plot(rope = 0.2, null_value = 0.1)
  hlines <- Filter(function(l) inherits(l$geom, "GeomHline"), forest_panel(p)$layers)
  rope_layer <- hlines[[1]]
  expect_equal(sort(rope_layer$data$yintercept), c(-0.1, 0.3))
})

test_that("y limits default to symmetric and can be set", {
  p <- toy_plot()
  lim <- forest_panel(p)$coordinates$limits$y
  expect_equal(lim, c(-0.9, 0.9))

  p <- toy_plot(y_limits = c(-2, 3))
  expect_equal(forest_panel(p)$coordinates$limits$y, c(-2, 3))
})

test_that("forest_height sets the panel proportions", {
  p <- toy_plot(forest_height = 0.5)
  expect_equal(p$patches$layout$heights, c(0.5, 0.5))

  p <- toy_plot(forest_height = 0.3)
  expect_equal(p$patches$layout$heights, c(0.3, 0.7))
})

test_that("auto forest_height depends on the number of heatmap rows", {
  standard <- toy_plot()$patches$layout$heights[[1]]
  compact <- toy_plot(layout = "compact")$patches$layout$heights[[1]]
  expect_equal(standard, auto_forest_height(6.5))
  expect_equal(compact, auto_forest_height(4.5))
  expect_gt(compact, standard)
})

test_that("standard layout shows bold headings as axis labels", {
  p <- toy_plot()
  scale <- heatmap_panel(p)$scales$get_scales("y")
  labels <- scale$labels(c(".header:1", "1:Adults"))
  expect_equal(labels, c("<b>Population</b>", "Adults"))
})

test_that("compact layout labels facets with moderator names", {
  p <- toy_plot(layout = "compact")
  facet <- heatmap_panel(p)$facet
  expect_s3_class(facet, "FacetGrid")
  expect_equal(facet$params$switch, "y")
  labeller <- facet$params$labeller
  out <- labeller(data.frame(block = c("1", "2")))
  expect_equal(out[[1]], c("Population", "Design"))
})

test_that("unnamed moderators use column names as headings", {
  p <- plot_forestmap(toy_data(), "es", "lo", "hi", c("pop", Design = "design"),
                     font = "sans")
  scale <- heatmap_panel(p)$scales$get_scales("y")
  expect_equal(scale$labels(c(".header:1", ".header:2")),
               c("<b>pop</b>", "<b>Design</b>"))
})

test_that("headings with markdown characters are escaped", {
  p <- plot_forestmap(toy_data(), "es", "lo", "hi", c("Age < 18" = "pop"),
                     font = "sans")
  scale <- heatmap_panel(p)$scales$get_scales("y")
  expect_equal(scale$labels(".header:1"), "<b>Age &lt; 18</b>")
})

test_that("max_levels is applied to the heatmap", {
  d <- data.frame(
    es = seq(-0.5, 0.5, length.out = 12),
    lo = seq(-0.5, 0.5, length.out = 12) - 0.3,
    hi = seq(-0.5, 0.5, length.out = 12) + 0.3,
    region = factor(c(rep("Europe", 5), rep("Asia", 4), "Africa", "Oceania", NA))
  )
  p <- plot_forestmap(d, "es", "lo", "hi", "region", font = "sans",
                     max_levels = 3, layout = "compact")
  rows <- levels(heatmap_panel(p)$data$row)
  expect_setequal(rows, c("1:Europe", "1:Asia", "1:Other"))
})

test_that("max_levels ties warn through plot_forestmap", {
  d <- toy_data()
  d$pop <- factor(c("A", "B", "C", "D"))
  expect_warning(
    plot_forestmap(d, "es", "lo", "hi", c(Pop = "pop"), font = "sans", max_levels = 2),
    "Pop.*tie"
  )
})

test_that("a missing user-chosen font warns and falls back", {
  expect_warning(toy_plot_font <- plot_forestmap(
    toy_data(), "es", "lo", "hi", "pop", font = "No Such Font 123"
  ), "not installed")
  expect_equal(toy_plot_font$theme$text$family, "sans")
})

test_that("text_size sets the base text size", {
  p <- toy_plot(text_size = 14)
  expect_equal(p$theme$text$size, 14)
  expect_equal(p$theme$strip.text.y.left$size, 14)
})

test_that("tibbles are accepted", {
  skip_if_not_installed("tibble")
  expect_s3_class(
    plot_forestmap(tibble::as_tibble(toy_data()), "es", "lo", "hi", "pop",
                  font = "sans"),
    "patchwork"
  )
})

test_that("the plot uses the forestmap theme", {
  p <- toy_plot()
  expect_s3_class(p$theme$panel.border, "ggplot2::element_blank")
  expect_equal(p$theme$axis.line$colour, "black")
  expect_equal(p$theme$text$family, "sans")
})
