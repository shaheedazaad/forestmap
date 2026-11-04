# default_y_limits ----------------------------------------------------------

test_that("default y limits always contain every CI", {
  set.seed(1)
  for (i in 1:2000) {
    k <- sample(2:80, 1)
    null <- sample(c(0, 1), 1)
    scale <- 10^stats::runif(1, -4, 4)
    es <- null + stats::rnorm(k, 0, scale)
    w <- abs(stats::rnorm(k, 0, scale))
    lim <- default_y_limits(es - w, es + w, null)
    expect_lte(lim[[1]], min(es - w))
    expect_gte(lim[[2]], max(es + w))
  }
})

test_that("default y limits are symmetric around the null value", {
  lim <- default_y_limits(c(-0.2, 0.8), c(1.2, 2.3), null_value = 1)
  expect_equal(mean(lim), 1)
  expect_equal(lim, c(-0.5, 2.5))
})

test_that("default y limits include the ROPE", {
  lim <- default_y_limits(-0.01, 0.01, 0, rope = c(-0.3, 0.3))
  expect_equal(lim, c(-0.3, 0.3))
})

test_that("default y limits stop at 0 on ratio scales", {
  lim <- default_y_limits(c(0.4, 1.1), c(1.5, 7.8), null_value = 1)
  expect_equal(lim, c(0, 8))
  # but not when the null value is 0, or when values go below 0
  expect_equal(default_y_limits(c(0.4, 1.1), c(1.5, 7.8), 0), c(-8, 8))
  expect_equal(default_y_limits(c(-0.4, 1.1), c(1.5, 7.8), 1), c(-6, 8))
})

test_that("default y limits handle CIs that are exactly the null value", {
  expect_equal(default_y_limits(c(0, 0), c(0, 0), 0), c(-1, 1))
})

# auto_forest_height ---------------------------------------------------------

test_that("auto curve height matches the reference proportion", {
  expect_equal(auto_forest_height(18), 1 / 3)
  expect_equal(auto_forest_height(9), 0.5)
})

test_that("auto curve height is clamped", {
  expect_equal(auto_forest_height(1), 0.6)
  expect_equal(auto_forest_height(500), 0.2)
})

# resolve_palette -----------------------------------------------------------

test_that("named palettes are returned in positive/negative/null order", {
  for (name in names(forestmap_palettes)) {
    pal <- resolve_palette(name)
    expect_named(pal, c("positive", "negative", "null"))
  }
})

test_that("custom palettes are accepted named or unnamed", {
  expect_equal(
    resolve_palette(c("red", "blue", "grey")),
    c(positive = "red", negative = "blue", null = "grey")
  )
  expect_equal(
    resolve_palette(c(null = "grey", positive = "red", negative = "blue")),
    c(positive = "red", negative = "blue", null = "grey")
  )
})

test_that("bad palettes give helpful errors", {
  expect_error(resolve_palette("nope"), '"default"')
  expect_error(resolve_palette(c(a = "red", b = "blue", c = "grey")),
               "named positive, negative and null")
  expect_error(resolve_palette(c("red", "notacolour", "grey")), "notacolour")
  expect_error(resolve_palette(c("red", "blue")), "palette")
})

# resolve_font --------------------------------------------------------------

test_that("generic families are always accepted", {
  expect_equal(resolve_font("sans"), "sans")
  expect_equal(resolve_font("serif"), "serif")
})

test_that("a missing font falls back to the bundled default", {
  expect_warning(
    expect_equal(resolve_font("No Such Font 123"), "Roboto Condensed"),
    "not installed; using 'Roboto Condensed'"
  )
  expect_no_warning(
    expect_equal(resolve_font("No Such Font 123", warn = FALSE), "Roboto Condensed")
  )
})

test_that("the bundled default font ships with the package and is usable", {
  font_dir <- system.file("fonts", package = "forestmap")
  expect_true(all(file.exists(file.path(font_dir, c(
    "RobotoCondensed-Regular.ttf", "RobotoCondensed-Bold.ttf", "OFL.txt"
  )))))
  expect_equal(resolve_font(), "Roboto Condensed")
  expect_true(font_installed("Roboto Condensed"))
  # Regular and bold faces are both found (bold is used for headings)
  bold <- systemfonts::match_fonts("Roboto Condensed", weight = "bold")
  expect_match(basename(bold$path), "Bold", ignore.case = TRUE)
})

test_that("the default font never warns", {
  expect_no_warning(toy_plot_default <- plot_forestmap(
    toy_data(), "es", "lo", "hi", "pop"
  ))
})

test_that("font files are checked and registered", {
  expect_error(resolve_font("does/not/exist.ttf"), "Font file not found")
  font_file <- system.file("fonts", package = "systemfonts")
  ttf <- list.files(
    c(font_file, systemfonts::system_fonts()$path |> dirname() |> unique() |> utils::head(3)),
    pattern = "\\.ttf$", full.names = TRUE
  )
  skip_if(!length(ttf), "No .ttf file available to test with")
  family <- resolve_font(ttf[[1]])
  expect_equal(family, paste0("forestmap-", tools::file_path_sans_ext(basename(ttf[[1]]))))
  # registering the same file again is fine
  expect_equal(resolve_font(ttf[[1]]), family)
  expect_true(family %in% systemfonts::registry_fonts()$family)
})

test_that("font must be a single string", {
  expect_error(resolve_font(c("a", "b")), "single font name")
  expect_error(resolve_font(""), "single font name")
})

# lump_levels ---------------------------------------------------------------

test_that("lump_levels leaves moderators with few levels alone", {
  x <- factor(c("a", "b", "c"))
  expect_identical(lump_levels(x, 3, "m"), x)
})

test_that("lump_levels keeps the most common levels and merges the rest", {
  x <- factor(c(rep("A", 5), rep("B", 4), rep("C", 2), "D", NA))
  out <- lump_levels(x, 3, "m")
  expect_equal(levels(out), c("A", "B", "Other"))
  expect_equal(as.vector(table(out)), c(5, 4, 3))
  expect_true(is.na(out[length(out)]))
})

test_that("lump_levels keeps all levels tied for the last place, with a warning", {
  x <- factor(c(rep("A", 5), rep("B", 3), rep("C", 3), "D", "E"))
  expect_warning(out <- lump_levels(x, 3, "Region"),
                 "Region.*top 2.*B, C.*3 levels")
  expect_equal(levels(out), c("A", "B", "C", "Other"))
})

test_that("lump_levels doesn't rename a single leftover level", {
  x <- factor(c(rep("A", 5), rep("B", 3), rep("C", 3), "D"))
  expect_warning(out <- lump_levels(x, 3, "m"), "tie")
  expect_equal(levels(out), c("A", "B", "C", "D"))
})

test_that("lump_levels merges into an existing 'Other' level", {
  x <- factor(c(rep("Other", 5), rep("B", 4), "C", "D"))
  out <- lump_levels(x, 3, "m")
  expect_equal(levels(out), c("B", "Other"))
  expect_equal(sum(out == "Other"), 7)
})

test_that("lump_levels doesn't count NA as a level", {
  x <- factor(c(rep(NA, 10), "A", "A", "B", "C", "D"), levels = c("A", "B", "C", "D"))
  out <- lump_levels(x, 2, "m")
  expect_equal(levels(out), c("A", "Other"))
  expect_equal(sum(is.na(out)), 10)
})

# order_studies -------------------------------------------------------------

test_that("studies are sorted and classified", {
  d <- toy_data()
  studies <- order_studies(d$es, d$lo, d$hi, null_value = 0)
  expect_equal(studies$estimate, sort(d$es))
  expect_equal(studies$rank, 1:4)
  expect_equal(studies$row_id, c(1, 2, 4, 3))
  expect_equal(studies$sign_label, c("negative", "null", "null", "positive"))
})

test_that("ties keep the input order", {
  studies <- order_studies(c(1, 0, 1), c(0, -1, 0), c(2, 1, 2), 0)
  expect_equal(studies$row_id, c(2, 1, 3))
})

test_that("classification respects null_value", {
  studies <- order_studies(c(1.5, 0.8), c(1.1, 0.5), c(2, 1.2), null_value = 1)
  expect_equal(studies$sign_label, c("null", "positive"))
})

test_that("a CI touching the null value counts as null", {
  studies <- order_studies(0.2, 0, 0.4, 0)
  expect_equal(studies$sign_label, "null")
})

# build_heatmap -------------------------------------------------------------

test_that("standard heatmap has a header row per moderator", {
  d <- toy_data()
  studies <- order_studies(d$es, d$lo, d$hi, 0)
  hm <- build_heatmap(d, studies, c("pop", "design"), c("Population", "Design"), "standard")
  expect_equal(hm$rows$key, c(".header:1", "1:Adults", "1:Children",
                              ".header:2", "2:RCT", "2:Cohort"))
  expect_equal(hm$rows$header, c(TRUE, FALSE, FALSE, TRUE, FALSE, FALSE))
  expect_equal(hm$rows$label[hm$rows$header], c("Population", "Design"))
  expect_equal(hm$n_rows, 6.5)
  expect_equal(nrow(hm$tiles), 6 * 4)
})

test_that("compact heatmap has no header rows", {
  d <- toy_data()
  studies <- order_studies(d$es, d$lo, d$hi, 0)
  hm <- build_heatmap(d, studies, c("pop", "design"), c("Population", "Design"), "compact")
  expect_false(any(hm$rows$header))
  expect_equal(nrow(hm$rows), 4)
  expect_equal(hm$n_rows, 4.5)
})

test_that("tiles are coloured by the study's significance", {
  d <- toy_data()
  studies <- order_studies(d$es, d$lo, d$hi, 0)
  hm <- build_heatmap(d, studies, c("pop", "design"), c("P", "D"), "compact")
  fill <- function(row, rank) {
    hm$tiles$fill_state[hm$tiles$row == row & hm$tiles$rank == rank]
  }
  # rank 1 = row 1 (Adults, RCT, negative)
  expect_equal(fill("1:Adults", 1), "negative")
  expect_equal(fill("1:Children", 1), "absent")
  expect_equal(fill("2:RCT", 1), "negative")
  # rank 4 = row 3 (Adults, Cohort, positive)
  expect_equal(fill("1:Adults", 4), "positive")
  expect_equal(fill("2:Cohort", 4), "positive")
  # rank 3 = row 4 (population NA -> no filled tile in that block)
  expect_equal(fill("1:Adults", 3), "absent")
  expect_equal(fill("1:Children", 3), "absent")
  expect_equal(fill("2:Cohort", 3), "null")
})

test_that("equal level names in different moderators stay separate", {
  d <- data.frame(
    es = c(0, 1), lo = c(-1, 0.5), hi = c(1, 1.5),
    a = factor(c("Yes", "No")), b = factor(c("No", "Yes"))
  )
  studies <- order_studies(d$es, d$lo, d$hi, 0)
  hm <- build_heatmap(d, studies, c("a", "b"), c("A", "B"), "compact")
  expect_equal(anyDuplicated(hm$rows$key), 0L)
  expect_setequal(hm$rows$key, c("1:No", "1:Yes", "2:No", "2:Yes"))
})

test_that("unused factor levels get an empty row", {
  d <- toy_data()
  d$pop <- factor(d$pop, levels = c("Adults", "Children", "Elderly"))
  studies <- order_studies(d$es, d$lo, d$hi, 0)
  hm <- build_heatmap(d, studies, "pop", "P", "compact")
  expect_true("1:Elderly" %in% hm$rows$key)
  expect_true(all(hm$tiles$fill_state[hm$tiles$row == "1:Elderly"] == "absent"))
})

# escape_markdown -----------------------------------------------------------

test_that("markdown special characters are escaped", {
  expect_equal(escape_markdown("a < b & c > d"), "a &lt; b &amp; c &gt; d")
})

# theme_forestmap --------------------------------------------------------------

test_that("theme_forestmap has black axes, no grid and full-size axis text", {
  th <- theme_forestmap(9, "sans")
  expect_s3_class(th, "theme")
  expect_equal(th$text$size, 9)
  expect_equal(th$text$family, "sans")
  expect_equal(th$axis.line$colour, "black")
  expect_equal(th$axis.line$lineend, "butt")
  expect_equal(th$axis.ticks$colour, "black")
  expect_equal(th$axis.text$colour, "black")
  expect_equal(unclass(th$axis.text$size), 1)
  full <- ggplot2::complete_theme(th)
  expect_s3_class(ggplot2::calc_element("panel.grid.major", full), "ggplot2::element_blank")
  expect_s3_class(ggplot2::calc_element("panel.grid.minor", full), "ggplot2::element_blank")
  expect_s3_class(ggplot2::calc_element("panel.border", full), "ggplot2::element_blank")
})
