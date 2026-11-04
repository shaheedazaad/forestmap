test_that("data must be a non-empty data frame", {
  expect_error(
    plot_forestmap(list(a = 1), "a", "a", "a", "a", font = "sans"),
    "data frame"
  )
  expect_error(
    plot_forestmap(toy_data()[0, ], "es", "lo", "hi", "pop", font = "sans"),
    "at least one row"
  )
})

test_that("column arguments must be single strings that exist", {
  d <- toy_data()
  expect_error(plot_forestmap(d, es, "lo", "hi", "pop"), "not found|object")
  expect_error(plot_forestmap(d, c("es", "lo"), "lo", "hi", "pop", font = "sans"),
               "`es` must be a single column name")
  expect_error(plot_forestmap(d, "es", "lo", "hi", 1, font = "sans"),
               "`moderators` must be")
  expect_error(plot_forestmap(d, "es", "lo", "hi", character(), font = "sans"),
               "`moderators` must be")
  expect_error(plot_forestmap(d, "nope", "lo", "hi", "pop", font = "sans"),
               "not found in `data`: nope")
  expect_error(plot_forestmap(d, "es", "lo", "hi", c("pop", "missing_mod"), font = "sans"),
               "missing_mod")
  expect_error(plot_forestmap(d, "es", "lo", "hi", c("pop", "pop"), font = "sans"),
               "only be listed once")
})

test_that("effect size and CI columns must be numeric, complete and ordered", {
  d <- toy_data()
  d$es_chr <- as.character(d$es)
  expect_error(plot_forestmap(d, "es_chr", "lo", "hi", "pop", font = "sans"),
               "must be numeric")

  d <- toy_data()
  d$es[2] <- NA
  expect_error(plot_forestmap(d, "es", "lo", "hi", "pop", font = "sans"),
               "missing or infinite")

  d <- toy_data()
  d$hi[3] <- Inf
  expect_error(plot_forestmap(d, "es", "lo", "hi", "pop", font = "sans"),
               "missing or infinite")

  d <- toy_data()
  d$lo[1] <- 0 # above its estimate (-0.5)
  expect_error(plot_forestmap(d, "es", "lo", "hi", "pop", font = "sans"),
               "lo <= es <= hi. Check row\\(s\\): 1")
})

test_that("other arguments are validated", {
  expect_error(toy_plot(forest_height = 1), "forest_height")
  expect_error(toy_plot(forest_height = 0), "forest_height")
  expect_error(toy_plot(forest_height = "tall"), "forest_height")
  expect_error(toy_plot(max_levels = 1), "max_levels")
  expect_error(toy_plot(max_levels = 2.5), "max_levels")
  expect_error(toy_plot(text_size = -1), "text_size")
  expect_error(toy_plot(text_size = "big"), "text_size")
  expect_error(toy_plot(null_value = NA), "null_value")
  expect_error(toy_plot(y_limits = c(1, -1)), "y_limits")
  expect_error(toy_plot(y_limits = 1), "y_limits")
  expect_error(toy_plot(rope = c(1, 2, 3)), "rope")
  expect_error(toy_plot(rope = "a"), "rope")
  expect_error(toy_plot(rope = c(0.1, 0.1)), "span a range")
  expect_error(toy_plot(layout = "wide"), "should be one of")
  expect_error(toy_plot(palette = "rainbow"), "palette")
  expect_error(toy_plot(y_label = c("a", "b")), "y_label")
})

test_that("moderators with no levels give an error", {
  d <- toy_data()
  d$empty <- factor(rep(NA, 4))
  expect_error(plot_forestmap(d, "es", "lo", "hi", "empty", font = "sans"),
               "no levels")
})

test_that("non-factor moderators are converted with a message", {
  d <- toy_data()
  d$pop <- as.character(d$pop)
  expect_message(
    p <- plot_forestmap(d, "es", "lo", "hi", "pop", font = "sans"),
    "not a factor"
  )
  expect_s3_class(p, "patchwork")
})
