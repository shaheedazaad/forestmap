# forestmap 0.1.0

* First version. `plot_forestmap()` draws a forest plot of the studies in a
  meta-analysis, sorted by effect size, above a heatmap of study properties.
  Give each study's uncertainty as a sampling variance (`vi`), a standard
  error (`se`) or 95% CI bounds (`lb`, `ub`).
  Options: standard and compact layouts; built-in (`"default"`,
  `"okabe_ito"`, `"viridis"`, `"greyscale"`) and custom palettes; a bundled
  default font (Roboto Condensed) and custom fonts; automatic or manual panel heights (`forest_height`); `max_levels`
  to merge rare levels into "Other"; `rope`, `null_value` and `y_limits`.
