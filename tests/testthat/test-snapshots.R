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
      forestmap_example, "smd", "ci_lower", "ci_upper", moderators,
      font = "sans", rope = c(-0.1, 0.1), y_label = "SMD (95% CI)"
    )
  )
})

test_that("compact layout looks right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "compact",
    plot_forestmap(
      forestmap_example, "smd", "ci_lower", "ci_upper", moderators,
      font = "sans", layout = "compact", palette = "okabe_ito"
    )
  )
})

test_that("max_levels and custom palette look right", {
  skip_if_not_installed("vdiffr")
  vdiffr::expect_doppelganger(
    "max-levels-custom-palette",
    plot_forestmap(
      forestmap_example, "smd", "ci_lower", "ci_upper", moderators,
      font = "sans", max_levels = 2, forest_height = 0.5,
      palette = c(positive = "#1b7837", negative = "#762a83", null = "#bdbdbd")
    )
  )
})
