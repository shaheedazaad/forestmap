# Helpers ---------------------------------------------------------------------

test_that("label sizes default to text_size and can be set by name", {
  expect_equal(resolve_label_size(NULL, 10), c(study = 8.5, level = 10, moderator = 10))
  expect_equal(resolve_label_size(c(level = 7), 10), c(study = 8.5, level = 7, moderator = 10))
  expect_error(resolve_label_size(c(7, 8), 10), "label_size")
  expect_error(resolve_label_size(c(size = 7), 10), "label_size")
  expect_error(resolve_label_size(c(level = -1), 10), "label_size")
  expect_error(resolve_label_size(c(level = "7"), 10), "label_size")
})

test_that("long moderator names are wrapped to the width of their columns", {
  expect_equal(wrap_title(c("Population", "Study design"), c(3, 2)),
               c("Population", "Study\ndesign"))
  # A name with its own line break is left alone
  expect_equal(wrap_title("A long\nname here", 1), "A long\nname here")
})

test_that("angled level labels are justified to start at their column", {
  expect_equal(angle_just(0), c(h = 0.5, v = 0))
  expect_equal(angle_just(50), c(h = 0, v = 0))
  expect_equal(angle_just(90), c(h = 0, v = 0.5))
})

test_that("auto forest width shrinks with more heatmap columns, within limits", {
  expect_gt(auto_forest_width(6), auto_forest_width(20))
  expect_equal(auto_forest_width(1), 0.7)
  expect_equal(auto_forest_width(500), 0.3)
})

# Vertical orientation ----------------------------------------------------------

vertical_plot <- function(...) {
  plot_forestmap(
    toy_continuous(), "es", "lo", "hi",
    moderators = c("Population" = "pop", "Mean age" = "age"),
    font = "sans", orientation = "vertical", ...
  )
}

test_that("vertical puts studies on the y-axis of both panels", {
  p <- vertical_plot()
  forest <- forest_panel(p)
  points <- ggplot2::layer_data(forest, length(forest$layers))
  # Effect sizes along x, studies (ranks) up y
  expect_equal(points$x, sort(toy_data()$es))
  expect_equal(points$y, 1:4)
  heat <- heatmap_panel(p)
  tiles <- ggplot2::layer_data(heat, 1)
  expect_setequal(unique(tiles$y), 1:4)
  expect_equal(names(heat$facet$params$cols), "block")
  # The two panels share the same study axis, so rows line up
  expect_equal(forest$scales$get_scales("y")$limits, c(0.5, 4.5))
  expect_equal(heat$scales$get_scales("y")$limits, c(0.5, 4.5))
})

test_that("vertical sets the forest plot's share of the width", {
  p <- vertical_plot(forest_height = 0.4)
  expect_equal(p$patches$layout$widths, c(0.4, 0.6))
})

test_that("vertical has no heading rows and labels continuous columns in bold", {
  p <- vertical_plot()
  heat <- heatmap_panel(p)
  expect_false(any(grepl("^\\.header", levels(heat$data$row))))
  labels <- heat$scales$get_scales("x")$labels(c("1:Adults", ".cont:2"))
  expect_equal(labels, c("Adults", "<b>Mean age</b>"))
  strip <- heat$facet$params$labeller(data.frame(block = c("1", "2")))
  expect_equal(strip[[1]], c("Population", ""))
})

test_that("study labels are shown in vertical and warn otherwise", {
  d <- toy_continuous()
  d$name <- c("A 2001", "B 2002", "C 2003", NA)
  p <- plot_forestmap(d, "es", "lo", "hi", moderators = "pop", font = "sans",
                      orientation = "vertical", study = "name")
  scale <- forest_panel(p)$scales$get_scales("y")
  expect_equal(scale$get_labels(), c("A 2001", "B 2002", "", "C 2003"))
  expect_warning(
    plot_forestmap(d, "es", "lo", "hi", moderators = "pop", font = "sans", study = "name"),
    "only shown"
  )
  expect_error(plot_forestmap(d, "es", "lo", "hi", moderators = "pop", study = "nope"),
               "not found")
})

test_that("the x_label default is hidden in vertical but a chosen one is shown", {
  expect_null(forest_panel(vertical_plot())$labels$y)
  expect_equal(forest_panel(vertical_plot(x_label = "Study"))$labels$y, "Study")
})

test_that("every option renders in vertical", {
  for (style in c("bar", "tint", "stripe")) {
    for (range in c("none", "label", "end", "legend")) {
      p <- vertical_plot(continuous_style = style, continuous_range = range,
                         rope = 0.1, level_angle = 90,
                         label_size = c(study = 6, level = 7, moderator = 8))
      path <- withr::local_tempfile(fileext = ".png")
      expect_no_condition(ggplot2::ggsave(path, p, width = 5, height = 4, dpi = 50))
    }
  }
})

test_that("a legend in vertical keeps the forest plot and heatmap first", {
  p <- vertical_plot(continuous_range = "legend")
  expect_length(p, 3)
  expect_s3_class(forest_panel(p), "ggplot")
  expect_s3_class(p[[3]], "wrapped_patch")
})

test_that("new arguments are validated", {
  expect_error(vertical_plot(level_angle = 120), "level_angle")
  expect_error(toy_plot(orientation = "diagonal"), "should be one of")
  expect_error(vertical_plot(label_size = c(heading = 8)), "label_size")
  expect_error(toy_plot(study = c("a", "b")), "single column name")
})

# Label sizes -------------------------------------------------------------------

test_that("label sizes reach the level labels and moderator names", {
  p <- toy_plot(label_size = c(level = 7, moderator = 11))
  heat <- heatmap_panel(p)
  guide_theme <- heat$scales$get_scales("y")$guide$params$theme
  expect_equal(guide_theme$axis.text.y$size, 7)
  # Headings in the standard layout are sized with markdown
  expect_equal(heat$scales$get_scales("y")$labels(".header:1"),
               "<span style='font-size:11pt'><b>Population</b></span>")
  # Compact moderator names are facet strips
  p <- toy_plot(layout = "compact", label_size = c(moderator = 11))
  expect_equal(p$theme$strip.text.y.left$size, 11)
})

# Study axis ticks ----------------------------------------------------------------

test_that("study_ticks = FALSE removes the study axis breaks", {
  horizontal <- function(...) {
    plot_forestmap(toy_continuous(), "es", "lo", "hi",
                   moderators = c("Population" = "pop"), font = "sans", ...)
  }
  breaks <- function(p, i, axis) ggplot2::layer_scales(p[[i]])[[axis]]$get_breaks()
  expect_gt(length(breaks(horizontal(), 1, "x")), 0)
  p <- horizontal(study_ticks = FALSE)
  expect_null(breaks(p, 1, "x"))
  expect_null(breaks(p, 2, "x"))
  expect_null(breaks(vertical_plot(study_ticks = FALSE), 1, "y"))
  # Study names are kept
  named <- vertical_plot(study = "pop", study_ticks = FALSE)
  expect_gt(length(breaks(named, 1, "y")), 0)
  expect_error(horizontal(study_ticks = NA), "study_ticks")
  expect_error(horizontal(study_ticks = "no"), "study_ticks")
})
