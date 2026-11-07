# Changelog

## forestmap 0.1.0

- First version.
  [`plot_forestmap()`](https://shaheedazaad.github.io/forestmap/reference/plot_forestmap.md)
  draws a forest plot of the studies in a meta-analysis, sorted by
  effect size, above a heatmap of study properties. Give each study’s
  uncertainty as a sampling variance (`vi`), a standard error (`se`) or
  95% CI bounds (`lb`, `ub`). Options: standard and compact layouts;
  built-in (`"default"`, `"okabe_ito"`, `"viridis"`, `"greyscale"`) and
  custom palettes; a bundled default font (Roboto Condensed) and custom
  fonts; automatic or manual panel heights (`forest_height`);
  `max_levels` to merge rare levels into “Other”; `rope`, `null_value`
  and `y_limits`.
- Numeric moderators (e.g. mean age) are shown as a single continuous
  row, drawn as a bar (the default), a tint of the study’s colour, or a
  grey shade with a coloured stripe (`continuous_style`).
  `continuous_range` adds the range of values to the row’s label, at the
  end of the row, or as a legend.
