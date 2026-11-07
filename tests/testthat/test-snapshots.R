# Visual regression tests. Snapshots live in tests/testthat/_snaps/snapshots/.
# After an intended visual change, review with testthat::snapshot_review().

moderators <- c(
  "Population" = "population",
  "Outcome measure" = "outcome",
  "Study design" = "design",
  "Country" = "country"
)

test_that("standard layout looks right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "standard",
    plot_forestmap(
      forestmap_example, "smd", vi = "vi", moderators = moderators,
      font = "sans", rope = c(-0.1, 0.1), y_label = "SMD (95% CI)"
    )
  )
})

test_that("compact layout looks right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "compact",
    plot_forestmap(
      forestmap_example, "smd", vi = "vi", moderators = moderators,
      font = "sans", layout = "compact", palette = "okabe_ito"
    )
  )
})

test_that("max_levels and custom palette look right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "max-levels-custom-palette",
    plot_forestmap(
      forestmap_example, "smd", vi = "vi", moderators = moderators,
      font = "sans", max_levels = 2, forest_height = 0.5,
      palette = c(positive = "#1b7837", negative = "#762a83", null = "#bdbdbd")
    )
  )
})

continuous_moderators <- c(
  "Population" = "population",
  "Sample size" = "n",
  "Study design" = "design"
)

test_that("continuous tint with range in the label looks right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "continuous-tint-label",
    plot_forestmap(
      forestmap_example, "smd", vi = "vi", moderators = continuous_moderators,
      font = "sans", continuous_style = "tint", continuous_range = "label"
    )
  )
})

test_that("continuous stripe with a legend looks right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "continuous-stripe-legend",
    plot_forestmap(
      forestmap_example, "smd", vi = "vi", moderators = continuous_moderators,
      font = "sans", continuous_style = "stripe", continuous_range = "legend",
      layout = "compact"
    )
  )
})

test_that("continuous bars with an end key look right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "continuous-bar-end",
    plot_forestmap(
      forestmap_example, "smd", vi = "vi", moderators = continuous_moderators,
      font = "sans", continuous_style = "bar", continuous_range = "end",
      palette = "okabe_ito"
    )
  )
})
