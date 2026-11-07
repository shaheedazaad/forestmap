# Helpers -------------------------------------------------------------------

test_that("continuous_grey matches the palette's darkness, within limits", {
  lightness <- function(col) {
    unname(grDevices::convertColor(t(grDevices::col2rgb(col)) / 255, "sRGB", "Lab")[, 1])
  }
  expect_equal(lightness(continuous_grey(forestmap_palettes$default)), 44, tolerance = 0.03)
  # viridis's dark purple would give a near-black grey: clamped to 45
  expect_equal(lightness(continuous_grey(forestmap_palettes$viridis)), 45, tolerance = 0.02)
  pale <- c(positive = "#dddddd", negative = "#eeeeee", null = "#f5f5f5")
  expect_equal(lightness(continuous_grey(pale)), 60, tolerance = 0.02)
})

test_that("tint and stripe colours run from pale to full", {
  expect_equal(tint_colour("#0571b0", 1), "#0571B0")
  expect_equal(tint_colour("#000000", 0), grDevices::rgb(0.82, 0.82, 0.82))
  # Lab interpolation can round the light end by one step.
  ends <- grDevices::col2rgb(stripe_colour(c(0, 1), "#6b6b6b"))
  expect_equal(ends[, 1], grDevices::col2rgb("#e6e6e6")[, 1], tolerance = 0.01)
  expect_equal(ends[, 2], grDevices::col2rgb("#6b6b6b")[, 1])
})

test_that("rescale_unit scales to [0, 1] and handles a single value", {
  expect_equal(rescale_unit(c(10, 15, 20), c(10, 20)), c(0, 0.5, 1))
  expect_equal(rescale_unit(c(5, NA), c(5, 5)), c(1, NA))
})

test_that("numbers and ranges are formatted briefly", {
  expect_equal(format_number(c(19, 0.12345, 1234567, 2.50)), c("19", "0.123", "1,230,000", "2.5"))
  expect_equal(format_range(c(19, 67)), "19–67")
})

# build_heatmap ---------------------------------------------------------------

test_that("a continuous moderator is one row with its values in `cont`", {
  d <- toy_continuous()
  studies <- order_studies(d$es, d$lo, d$hi, 0)
  hm <- build_heatmap(d, studies, c("pop", "age"), c("Population", "Mean age"),
                      "standard", continuous = c(FALSE, TRUE))
  expect_equal(hm$rows$key, c(".header:1", "1:Adults", "1:Children", ".cont:2"))
  expect_equal(hm$rows$continuous, c(FALSE, FALSE, FALSE, TRUE))
  expect_equal(hm$rows$label[4], "Mean age")
  expect_equal(hm$n_rows, 4.5)
  expect_equal(hm$ranges[["2"]], c(20, 40))

  # rank 3 is row 4 (age NA): white tile, no value
  tiles <- hm$tiles[hm$tiles$row == ".cont:2", ]
  expect_equal(tiles$fill_state, c("absent", "absent", "absent", "spacer"))
  expect_equal(hm$cont$rank, c(1, 2, 3))
  expect_equal(hm$cont$value, c(20, 40, 30))
  expect_equal(hm$cont$s, c(0, 1, 0.5))
  expect_equal(hm$cont$sign_label, c("negative", "null", "null"))
})

# plot_forestmap --------------------------------------------------------------

test_that("numeric moderators are continuous, without a conversion message", {
  expect_no_message(p <- toy_cont_plot())
  rows <- levels(heatmap_panel(p)$data$row)
  expect_true(".cont:2" %in% rows)
  expect_false(any(grepl("^2:", rows)))
})

test_that("every style and range option renders", {
  for (style in c("tint", "stripe", "bar")) {
    for (range in c("none", "label", "end", "legend")) {
      for (layout in c("standard", "compact")) {
        p <- toy_cont_plot(continuous_style = style, continuous_range = range,
                           layout = layout)
        path <- withr::local_tempfile(fileext = ".png")
        expect_no_condition(
          ggplot2::ggsave(path, p, width = 5, height = 4, dpi = 50)
        )
      }
    }
  }
})

test_that("each style adds its own layers", {
  geoms <- function(style) {
    p <- toy_cont_plot(continuous_style = style)
    unname(vapply(heatmap_panel(p)$layers, function(l) class(l$geom)[1], character(1)))
  }
  expect_equal(geoms("tint"), c("GeomTile", "GeomTile"))
  expect_equal(geoms("stripe"), c("GeomTile", "GeomTile", "GeomRect"))
  expect_equal(geoms("bar"), c("GeomTile", "GeomRect"))
})

test_that("tint uses the palette colours, pale for low values", {
  p <- toy_cont_plot(continuous_style = "tint",
                     palette = c(positive = "green", negative = "purple", null = "grey50"))
  fills <- heatmap_panel(p)$layers[[2]]$aes_params$fill
  expect_equal(fills, c(tint_colour("purple", 0), tint_colour("grey50", 1),
                        tint_colour("grey50", 0.5)))
})

test_that("continuous_range = 'label' adds the range to the label", {
  y_labels <- function(...) {
    heatmap_panel(toy_cont_plot(...))$scales$get_scales("y")$labels(c(".header:1", ".cont:2"))
  }
  expect_equal(y_labels(), c("<b>Population</b>", "<b>Mean age</b>"))
  expect_equal(
    y_labels(continuous_range = "label")[2],
    "<b>Mean age</b> <span style='color:#666666'>(20–40)</span>"
  )
  compact <- function(...) {
    heatmap_panel(toy_cont_plot(layout = "compact", ...))$scales$get_scales("y")$labels(".cont:2")
  }
  expect_equal(compact(), "")
  expect_equal(compact(continuous_range = "label"), "20–40")
})

test_that("continuous_range = 'end' adds a key and room for it", {
  p <- toy_cont_plot(continuous_range = "end")
  heat <- heatmap_panel(p)
  expect_true(any(vapply(heat$layers, function(l) inherits(l$geom, "GeomRangeEnd"), logical(1))))
  expect_equal(heat$coordinates$clip, "off")
  expect_gt(as.numeric(heat$theme$plot.margin[2]),
            as.numeric(forest_panel(p)$theme$plot.margin[2]))
})

test_that("continuous_range = 'legend' adds a legend row", {
  p <- toy_cont_plot(continuous_range = "legend")
  expect_length(p, 3)
  expect_equal(as.numeric(p$patches$layout$heights)[1:2],
               c(auto_forest_height(4.5), 1 - auto_forest_height(4.5)))
  legend <- p[[3]]
  expect_s3_class(legend, "wrapped_patch")
})

test_that("no continuous moderators means no range additions", {
  p <- toy_plot(continuous_range = "legend")
  expect_length(p, 2)
  p <- toy_plot(continuous_range = "end")
  expect_false(identical(heatmap_panel(p)$coordinates$clip, "off"))
})

test_that("max_levels leaves continuous moderators alone", {
  expect_no_condition(p <- toy_cont_plot(max_levels = 2))
  expect_true(".cont:2" %in% levels(heatmap_panel(p)$data$row))
})

test_that("continuous moderators are validated", {
  d <- toy_continuous()
  d$age <- NA_real_
  expect_error(plot_forestmap(d, "es", "lo", "hi", "age", font = "sans"), "no values")
  d$age <- c(1, Inf, 2, 3)
  expect_error(plot_forestmap(d, "es", "lo", "hi", "age", font = "sans"), "infinite")
  expect_error(toy_cont_plot(continuous_style = "dots"), "should be one of")
  expect_error(toy_cont_plot(continuous_range = "axis"), "should be one of")
})
