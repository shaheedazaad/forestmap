#' Forest plot of studies with a heatmap of study properties
#'
#' Plots each study's effect size and 95% confidence interval, sorted from
#' smallest to largest, above a heatmap showing each study's properties
#' (population, design, country, ...). It shows at a glance whether studies
#' with particular properties tend to find larger or smaller effects.
#'
#' Each row of `data` is one study. Effects are coloured by their confidence
#' interval: `positive` when it lies entirely above `null_value`, `negative`
#' when entirely below, and `null` otherwise. Each study's heatmap tiles take
#' the same colour.
#'
#' @section Moderators:
#' Each categorical moderator (study property) gets its own block in the
#' heatmap with one row per factor level, in the order of the factor's
#' levels. Use [factor()] with `levels =` to control the order. A missing
#' value (`NA`) means the study doesn't report that property, so it gets no
#' filled tile in that block. Character and logical columns are converted to
#' factors (with a message).
#'
#' A numeric column is a continuous moderator (e.g. mean age or year of
#' publication) and gets a single row. Each study's tile shows its value,
#' scaled from the lowest value to the highest, in the style set by
#' `continuous_style`:
#' * `"bar"`: a bar in the significance colour whose height shows the value.
#' * `"tint"`: the study's significance colour, pale for low values and full
#'   strength for high values.
#' * `"stripe"`: a grey shade for the value, with a band in the significance
#'   colour along the bottom of the tile.
#'
#' A study with a missing value gets an empty (white) tile. To show a
#' numeric column as categories instead, convert it with [factor()].
#' `continuous_range` adds the range of values to the plot: in the row's
#' label, as a small key at the right end of the row, or as a legend below
#' the plot.
#'
#' @section Orientation:
#' `orientation = "vertical"` turns the plot on its side, like a traditional
#' forest plot: one row per study (largest effect at the top), effect sizes
#' along the x-axis, and the heatmap to the right with one column per level.
#' It suits long meta-analyses, which then grow downwards, and has room for
#' study names (`study`). Each moderator's levels are labelled above their
#' columns (at `level_angle`), with the moderator's name centred above them;
#' long names are wrapped at spaces, or put `"\n"` in a name to choose where.
#' A numeric moderator's column is labelled with its name in bold, on one
#' line: it isn't wrapped, and a `"\n"` in its name is ignored (as it is in
#' the headings of the horizontal standard layout). `layout` applies only to
#' the horizontal orientation.
#'
#' If labels overlap or look cramped, make them smaller with `label_size`,
#' upright with `level_angle = 90`, or give the plot more room when you save
#' it.
#'
#' @section Size and saving:
#' The plot has no fixed physical size; choose the width and height when you
#' save it, e.g. `ggplot2::ggsave("plot.png", p, width = 7, height = 5.25)`.
#' `forest_height` and `text_size` control proportions and text.
#'
#' PNG and SVG files saved with [ggplot2::ggsave()] always use the chosen
#' font. Some other graphics devices only see fonts installed on your
#' computer, and show the bundled Roboto Condensed in another font until you
#' install it (the files are in `system.file("fonts", package = "forestmap")`):
#' * RStudio's Plots pane: or set *Tools > Global Options > General >
#'   Graphics > Backend* to *AGG*.
#' * PDF: save with `device = cairo_pdf`.
#'
#' @param data A data frame with one row per study.
#' @param es Name of the column holding each study's effect size.
#' @param lb,ub Names of the columns holding the lower and upper bounds of
#'   each study's 95% confidence interval. Give these, *or* `vi`, *or* `se`.
#' @param vi Name of a column holding each study's sampling variance (e.g.
#'   `vi` from `metafor::escalc()`). The 95% confidence interval is computed
#'   as `es` ± 1.96 × √`vi`. Use instead of `lb` and `ub`.
#' @param se Name of a column holding each study's standard error. The 95%
#'   confidence interval is computed as `es` ± 1.96 × `se`. Use instead of
#'   `lb` and `ub`.
#' @param moderators Names of the columns holding study properties (factors).
#'   Name the vector to set each moderator's heading, e.g.
#'   `c("Study design" = "design", "Population" = "population")`; unnamed
#'   entries use the column name.
#' @param font A font family installed on your computer (e.g. `"Helvetica"`),
#'   or the path to a `.ttf`/`.otf` font file. The default, `"Roboto
#'   Condensed"`, comes with the package, so it works on every computer.
#' @param palette A palette name from [forestmap_palettes] (`"default"`,
#'   `"okabe_ito"`, `"viridis"`, `"greyscale"`) or three colours, e.g.
#'   `c(positive = "darkgreen", negative = "purple", null = "grey")`.
#' @param text_size Base text size in points.
#' @param forest_height Share of the plot given to the forest plot, between 0
#'   and 1: its share of the height, or of the width when `orientation =
#'   "vertical"` (`0.5` gives the forest plot and heatmap equal space).
#'   `"auto"` (the default) gives the heatmap more room the more rows (or
#'   columns) it has.
#' @param null_value The value meaning "no effect": `0` for differences and
#'   log ratios, `1` for raw ratios such as odds ratios.
#' @param rope Optional region of practical equivalence, drawn as a shaded
#'   band: two numbers such as `c(-0.1, 0.1)`, or one number for a band
#'   symmetric around `null_value`.
#' @param y_limits Optional limits of the effect size axis (the y-axis, or
#'   the x-axis when `orientation = "vertical"`), e.g. `c(-1, 1)`. By default the axis
#'   is symmetric around `null_value` and shows every confidence interval in
#'   full; for ratios (`null_value` above 0 and every value positive) it
#'   starts at 0.
#' @param y_label,x_label Axis titles: `y_label` for the effect sizes, `x_label`
#'   for the studies. In the vertical orientation the study axis has no title
#'   unless you give `x_label`.
#' @param max_levels Optional maximum number of rows per moderator. With
#'   `max_levels = 3`, the 2 most common levels are shown and the rest are
#'   merged into one "Other" row. If levels tie for the last place, all of them
#'   are kept (with a warning). `NULL` (the default) shows every level.
#' @param layout `"standard"` puts a bold heading above each moderator's rows;
#'   `"compact"` puts the moderator name to the left of its rows instead,
#'   which makes the heatmap shorter.
#' @param continuous_style How continuous (numeric) moderators show each
#'   study's value: `"bar"` (the default), `"tint"` or `"stripe"`. See
#'   *Moderators*.
#' @param continuous_range Where to show the range of each continuous
#'   moderator: `"none"` (the default), `"label"` (after the row's label,
#'   e.g. "Mean age (19-67)"), `"end"` (a small key at the end of the row, or
#'   under the column when vertical) or `"legend"` (below the plot).
#' @param orientation `"horizontal"` (the default) puts the forest plot above
#'   the heatmap, with studies along the x-axis. `"vertical"` puts one study
#'   per row, with the heatmap to the right. See *Orientation*.
#' @param study Optional name of a column holding study names (e.g. "Smith
#'   2019"), shown beside each row when `orientation = "vertical"`.
#' @param label_size Optional text sizes, in points, for the plot's labels,
#'   named any of `study` (study names), `level` (moderator levels) and
#'   `moderator` (moderator names), e.g. `c(study = 6, level = 8)`. Labels
#'   you don't name follow `text_size` (study names at 85% of it). Make labels
#'   smaller to stop them overlapping when there are many studies or levels.
#' @param level_angle Angle, in degrees from 0 (flat) to 90 (upright), of the
#'   level labels above the heatmap's columns when `orientation = "vertical"`.
#'
#' @return A [patchwork][patchwork::patchwork-package] object. Print it to
#'   display it, or save it with [ggplot2::ggsave()].
#'
#' @examples
#' p <- plot_forestmap(
#'   forestmap_example,
#'   es = "smd", vi = "vi",
#'   moderators = c(
#'     "Population" = "population",
#'     "Outcome measure" = "outcome",
#'     "Study design" = "design",
#'     "Country" = "country"
#'   ),
#'   rope = c(-0.1, 0.1),
#'   y_label = "SMD (95% CI)"
#' )
#' p
#'
#' # With confidence interval bounds instead of variances
#' dat <- forestmap_example
#' dat$ci_lower <- dat$smd - 1.96 * sqrt(dat$vi)
#' dat$ci_upper <- dat$smd + 1.96 * sqrt(dat$vi)
#' plot_forestmap(
#'   dat, es = "smd", lb = "ci_lower", ub = "ci_upper",
#'   moderators = c("Population" = "population", "Study design" = "design")
#' )
#'
#' # A continuous moderator (sample size), shown as bars with a legend
#' plot_forestmap(
#'   forestmap_example, "smd", vi = "vi",
#'   moderators = c("Population" = "population", "Sample size" = "n"),
#'   continuous_style = "bar",
#'   continuous_range = "legend"
#' )
#'
#' # Vertical, with study names, for long meta-analyses
#' plot_forestmap(
#'   forestmap_example, "smd", vi = "vi",
#'   moderators = c("Population" = "population", "Study design" = "design"),
#'   orientation = "vertical",
#'   study = "study",
#'   label_size = c(study = 7)
#' )
#'
#' # Compact layout, Okabe-Ito palette
#' plot_forestmap(
#'   forestmap_example, "smd", vi = "vi",
#'   moderators = c("Population" = "population", "Study design" = "design"),
#'   palette = "okabe_ito",
#'   layout = "compact"
#' )
#'
#' \dontrun{
#' ggplot2::ggsave("forestmap.png", p, width = 7, height = 5.25, dpi = 300)
#' }
#' @export
plot_forestmap <- function(
  data,
  es,
  lb = NULL,
  ub = NULL,
  moderators,
  vi = NULL,
  se = NULL,
  font = "Roboto Condensed",
  palette = "default",
  text_size = 9,
  forest_height = "auto",
  null_value = 0,
  rope = NULL,
  y_limits = NULL,
  y_label = "Effect size",
  x_label = "Effect",
  max_levels = NULL,
  layout = c("standard", "compact"),
  continuous_style = c("bar", "tint", "stripe"),
  continuous_range = c("none", "label", "end", "legend"),
  orientation = c("horizontal", "vertical"),
  study = NULL,
  label_size = NULL,
  level_angle = 50
) {
  x_label_given <- !missing(x_label)
  # ---- check inputs ---------------------------------------------------------
  if (!is.data.frame(data) || !nrow(data)) {
    stop("`data` must be a data frame with at least one row.", call. = FALSE)
  }
  data <- as.data.frame(data)

  # Effect sizes and confidence intervals: es plus either lb/ub, vi or se.
  is_column_name <- function(x) is.character(x) && length(x) == 1L && !is.na(x)
  for (arg in c("es", "lb", "ub", "vi", "se")) {
    value <- get(arg)
    if (!(arg != "es" && is.null(value)) && !is_column_name(value)) {
      stop(sprintf("`%s` must be a single column name, in quotes.", arg),
           call. = FALSE)
    }
  }
  if (xor(is.null(lb), is.null(ub))) {
    stop("Give both `lb` and `ub` (the lower and upper CI bounds).", call. = FALSE)
  }
  ci_sources <- c(ci = !is.null(lb), vi = !is.null(vi), se = !is.null(se))
  if (sum(ci_sources) != 1L) {
    stop(
      "Give the confidence intervals one way: `lb` and `ub`, or `vi` ",
      "(sampling variances), or `se` (standard errors).",
      call. = FALSE
    )
  }
  if (!is.character(moderators) || !length(moderators) || anyNA(moderators)) {
    stop("`moderators` must be a vector of column names, in quotes.", call. = FALSE)
  }
  if (anyDuplicated(unname(moderators))) {
    stop("Each moderator column can only be listed once.", call. = FALSE)
  }
  if (!is.null(study) && !is_column_name(study)) {
    stop("`study` must be a single column name, in quotes.", call. = FALSE)
  }
  value_cols <- c(es, lb, ub, vi, se)
  missing_cols <- setdiff(c(value_cols, unname(moderators), study), names(data))
  if (length(missing_cols)) {
    stop(sprintf(
      "Column(s) not found in `data`: %s",
      paste(missing_cols, collapse = ", ")
    ), call. = FALSE)
  }
  for (col in value_cols) {
    if (!is.numeric(data[[col]])) {
      stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
    }
    if (anyNA(data[[col]]) || any(!is.finite(data[[col]]))) {
      stop(sprintf("Column '%s' contains missing or infinite values.", col),
           call. = FALSE)
    }
  }
  estimate <- data[[es]]
  if (ci_sources[["ci"]]) {
    lower <- data[[lb]]
    upper <- data[[ub]]
    bad <- which(lower > estimate | estimate > upper)
    if (length(bad)) {
      stop(sprintf(
        "Every row needs %s <= %s <= %s. Check row(s): %s",
        lb, es, ub, paste(utils::head(bad, 10), collapse = ", ")
      ), call. = FALSE)
    }
  } else {
    spread_col <- if (ci_sources[["vi"]]) vi else se
    spread <- data[[spread_col]]
    bad <- which(spread < 0)
    if (length(bad)) {
      stop(sprintf(
        "Column '%s' can't be negative. Check row(s): %s",
        spread_col, paste(utils::head(bad, 10), collapse = ", ")
      ), call. = FALSE)
    }
    half_width <- stats::qnorm(0.975) * (if (ci_sources[["vi"]]) sqrt(spread) else spread)
    lower <- estimate - half_width
    upper <- estimate + half_width
  }

  layout <- match.arg(layout)
  continuous_style <- match.arg(continuous_style)
  continuous_range <- match.arg(continuous_range)
  orientation <- match.arg(orientation)
  vertical <- orientation == "vertical"
  if (!is.null(study) && !vertical) {
    warning('`study` labels are only shown with orientation = "vertical".',
            call. = FALSE)
  }
  if (!is.numeric(level_angle) || length(level_angle) != 1L ||
      !is.finite(level_angle) || level_angle < 0 || level_angle > 90) {
    stop("`level_angle` must be a number of degrees between 0 and 90.",
         call. = FALSE)
  }
  if (!is.numeric(text_size) || length(text_size) != 1L ||
      !is.finite(text_size) || text_size <= 0) {
    stop("`text_size` must be a positive number, e.g. 9.", call. = FALSE)
  }
  if (!identical(forest_height, "auto") &&
      !(is.numeric(forest_height) && length(forest_height) == 1L &&
        is.finite(forest_height) && forest_height > 0 && forest_height < 1)) {
    stop('`forest_height` must be "auto" or a number between 0 and 1, e.g. 0.5.',
         call. = FALSE)
  }
  if (!is.numeric(null_value) || length(null_value) != 1L || !is.finite(null_value)) {
    stop("`null_value` must be a single number, e.g. 0.", call. = FALSE)
  }
  if (!is.null(max_levels) &&
      (!is.numeric(max_levels) || length(max_levels) != 1L ||
       !is.finite(max_levels) || max_levels < 2 || max_levels %% 1 != 0)) {
    stop("`max_levels` must be NULL or a whole number of at least 2.", call. = FALSE)
  }
  if (!is.null(y_limits) &&
      (!is.numeric(y_limits) || length(y_limits) != 2L ||
       any(!is.finite(y_limits)) || y_limits[[1]] >= y_limits[[2]])) {
    stop("`y_limits` must be NULL or two increasing numbers, e.g. c(-1, 1).",
         call. = FALSE)
  }
  for (arg in c("y_label", "x_label")) {
    value <- get(arg)
    if (!is.null(value) && (!is.character(value) || length(value) != 1L)) {
      stop(sprintf("`%s` must be a single piece of text.", arg), call. = FALSE)
    }
  }

  sizes <- resolve_label_size(label_size, text_size)

  rope_vals <- NULL
  if (!is.null(rope)) {
    if (!is.numeric(rope) || !length(rope) %in% 1:2 || any(!is.finite(rope))) {
      stop("`rope` must be one number or two numbers, e.g. c(-0.1, 0.1).",
           call. = FALSE)
    }
    rope_vals <- sort(
      if (length(rope) == 1L) null_value + c(-1, 1) * abs(rope) else rope
    )
    if (rope_vals[[1]] == rope_vals[[2]]) {
      stop("`rope` must span a range, e.g. c(-0.1, 0.1).", call. = FALSE)
    }
  }

  colours <- resolve_palette(palette)
  family <- resolve_font(font)

  # ---- moderators -----------------------------------------------------------
  titles <- unname(moderators)
  if (!is.null(names(moderators))) {
    named <- !is.na(names(moderators)) & nzchar(names(moderators))
    titles[named] <- names(moderators)[named]
  }
  moderators <- unname(moderators)
  continuous <- vapply(moderators, function(m) is.numeric(data[[m]]), logical(1))
  for (col in moderators[continuous]) {
    values <- data[[col]]
    if (all(is.na(values))) {
      stop(sprintf("Continuous moderator '%s' has no values (all missing).", col),
           call. = FALSE)
    }
    if (any(is.infinite(values))) {
      stop(sprintf("Continuous moderator '%s' contains infinite values.", col),
           call. = FALSE)
    }
  }
  for (col in moderators[!continuous]) {
    if (!is.factor(data[[col]])) {
      message(sprintf(
        "Moderator '%s' is not a factor; converting it (levels in order of appearance).",
        col
      ))
      values <- data[[col]]
      data[[col]] <- factor(values, levels = unique(values[!is.na(values)]))
    }
  }
  if (!is.null(max_levels)) {
    for (i in which(!continuous)) {
      data[[moderators[[i]]]] <- lump_levels(
        data[[moderators[[i]]]], max_levels, titles[[i]]
      )
    }
  }
  no_levels <- moderators[!continuous][
    vapply(moderators[!continuous], function(m) !nlevels(data[[m]]), logical(1))
  ]
  if (length(no_levels)) {
    stop(sprintf(
      "Moderator(s) with no levels (all values missing): %s",
      paste(no_levels, collapse = ", ")
    ), call. = FALSE)
  }

  if (is.null(y_limits)) {
    y_limits <- default_y_limits(lower, upper, null_value, rope_vals)
  }

  studies <- order_studies(estimate, lower, upper, null_value)
  if (!is.null(study)) {
    labels <- as.character(data[[study]])
    labels[is.na(labels)] <- ""
    studies$label <- labels[studies$row_id]
  }
  marks <- mark_sizes(nrow(studies), text_size)

  forest_plot <- build_forest_plot(
    studies, colours, marks, null_value, rope_vals, y_limits, y_label,
    x_label = if (vertical && !x_label_given) NULL else x_label,
    vertical = vertical, study_size = sizes[["study"]]
  )

  # ---- heatmap --------------------------------------------------------------
  # The vertical layout always names moderators above their columns, so it
  # has no heading rows.
  heatmap <- build_heatmap(
    data, studies, moderators, titles,
    if (vertical) "compact" else layout, continuous
  )
  heatmap_plot <- build_heatmap_plot(
    heatmap, titles, colours, marks, layout, vertical,
    continuous_style, continuous_range, sizes, level_angle,
    x_label = if (vertical) NULL else x_label
  )

  # Range keys at the end of continuous rows sit outside the panel.
  end_margin <- 0
  if (continuous_range == "end" && length(heatmap$ranges)) {
    key_size <- 0.8 * text_size
    for (block in names(heatmap$ranges)) {
      heatmap_plot <- heatmap_plot + range_end_layer(
        factor(block, levels = levels(heatmap$tiles$block)),
        heatmap$ranges[[block]], continuous_style, continuous_grey(colours),
        key_size, family, vertical = vertical
      )
    }
    heatmap_plot <- heatmap_plot + ggplot2::coord_cartesian(clip = "off")
    end_margin <- if (vertical) {
      range_end_height(key_size)
    } else {
      range_end_width(heatmap$ranges, key_size)
    }
  }

  legends <- NULL
  if (continuous_range == "legend" && length(heatmap$ranges)) {
    legends <- legend_row(
      lapply(names(heatmap$ranges), function(block) {
        continuous_legend(
          titles[[as.integer(block)]], heatmap$ranges[[block]],
          continuous_style, continuous_grey(colours), text_size, family
        )
      }),
      gap_pt = 2 * text_size
    )
  }

  # ---- assemble -------------------------------------------------------------
  if (identical(forest_height, "auto")) {
    forest_height <- if (vertical) {
      auto_forest_width(heatmap$n_rows)
    } else {
      auto_forest_height(heatmap$n_rows)
    }
  }
  shares <- c(forest_height, 1 - forest_height)

  if (vertical) {
    # wrap_plots() rather than `+`, which needs patchwork attached.
    if (is.null(legends)) {
      plot <- patchwork::wrap_plots(forest_plot, heatmap_plot, nrow = 1) +
        patchwork::plot_layout(widths = shares)
    } else {
      plot <- patchwork::wrap_plots(
        forest_plot, heatmap_plot, patchwork::wrap_elements(full = legends)
      ) +
        patchwork::plot_layout(
          design = c(patchwork::area(1, 1), patchwork::area(1, 2),
                     patchwork::area(2, 1, 2, 2)),
          widths = shares,
          heights = grid::unit.c(grid::unit(1, "null"),
                                 legend_row_height(text_size))
        )
    }
  } else {
    heights <- shares
    plot <- patchwork::free(forest_plot, type = "label", side = "l") / heatmap_plot
    if (!is.null(legends)) {
      heights <- grid::unit.c(grid::unit(heights, "null"), legend_row_height(text_size))
      plot <- plot / patchwork::wrap_elements(full = legends)
    }
    plot <- plot + patchwork::plot_layout(heights = heights)
  }

  plot <- plot &
    theme_forestmap(base_size = text_size, base_family = family) &
    ggplot2::theme(
      axis.ticks.y = ggplot2::element_line(linewidth = 0.3),
      axis.title.x = ggplot2::element_text(
        margin = ggplot2::margin(t = 0.7 * text_size, b = 7)
      ),
      # Moderator names in the compact layout are facet strips on the left.
      strip.placement = "outside",
      strip.background = ggplot2::element_blank(),
      strip.text.y.left = ggplot2::element_text(
        angle = 0, face = "bold", hjust = 0, vjust = 0.5,
        size = sizes[["moderator"]], margin = ggplot2::margin(r = 8)
      ),
      # The standard layout's headings are axis labels, so hide its strips.
      strip.text.y.right = ggplot2::element_blank(),
      # Moderator names in the vertical layout, centred above their columns.
      strip.text.x.top = ggplot2::element_text(
        face = "bold", hjust = 0.5, vjust = 0, lineheight = 0.95,
        size = sizes[["moderator"]], margin = ggplot2::margin(b = 0.4 * text_size)
      ),
      strip.clip = "off",
      strip.switch.pad.grid = ggplot2::unit(0, "pt"),
      panel.spacing = ggplot2::unit(0.6 * text_size, "pt")
    )

  half <- text_size / 2
  if (vertical) {
    # The heatmap's rows line up with the forest plot's, so it needs no
    # y-axis; its level labels are on the top axis, without a line or ticks.
    plot[[2]] <- plot[[2]] + ggplot2::theme(
      axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(half, 3 * text_size, half + end_margin, half)
    )
    if (!is.null(study)) {
      plot[[1]] <- plot[[1]] + ggplot2::theme(axis.ticks.y = ggplot2::element_blank())
    }
  } else if (end_margin > 0) {
    plot[[2]] <- plot[[2]] + ggplot2::theme(
      plot.margin = ggplot2::margin(half, half + end_margin, half, half)
    )
  }
  plot
}

# The forest plot. Horizontal: studies along the x-axis, effect sizes up the
# y-axis. Vertical: effect sizes along the x-axis, studies up the y-axis
# (largest effect at the top), labelled with `studies$label` if present.
build_forest_plot <- function(studies, colours, marks, null_value, rope_vals,
                              limits, effect_label, x_label, vertical,
                              study_size) {
  n <- nrow(studies)
  if (vertical) {
    plot <- ggplot2::ggplot(
      studies,
      ggplot2::aes(x = .data$estimate, y = .data$rank, colour = .data$sign_label)
    )
    if (!is.null(rope_vals)) {
      plot <- plot +
        ggplot2::annotate(
          "rect", ymin = -Inf, ymax = Inf,
          xmin = rope_vals[[1]], xmax = rope_vals[[2]],
          fill = "#d3d3d3", alpha = 0.1
        ) +
        ggplot2::geom_vline(
          xintercept = rope_vals, linetype = "dotted",
          colour = "grey55", linewidth = 0.3
        )
    }
    study_scale <- if (is.null(studies$label)) {
      study_axis("y", n)
    } else {
      study_axis(
        "y", n, breaks = studies$rank, labels = studies$label,
        guide = ggplot2::guide_axis(theme = ggplot2::theme(
          axis.text.y = ggplot2::element_text(size = study_size)
        ))
      )
    }
    return(plot +
      ggplot2::geom_vline(
        xintercept = null_value, linetype = "dashed", colour = "grey70"
      ) +
      ggplot2::geom_errorbar(
        ggplot2::aes(xmin = .data$conf_low, xmax = .data$conf_high),
        width = 0, linewidth = marks$line, orientation = "y"
      ) +
      ggplot2::geom_point(size = marks$point) +
      ggplot2::scale_colour_manual(values = colours, guide = "none") +
      study_scale +
      ggplot2::coord_cartesian(xlim = limits) +
      ggplot2::labs(x = effect_label, y = x_label))
  }

  plot <- ggplot2::ggplot(
    studies,
    ggplot2::aes(x = .data$rank, y = .data$estimate, colour = .data$sign_label)
  )
  if (!is.null(rope_vals)) {
    plot <- plot +
      ggplot2::annotate(
        "rect", xmin = -Inf, xmax = Inf,
        ymin = rope_vals[[1]], ymax = rope_vals[[2]],
        fill = "#d3d3d3", alpha = 0.1
      ) +
      ggplot2::geom_hline(
        yintercept = rope_vals, linetype = "dotted",
        colour = "grey55", linewidth = 0.3
      )
  }
  plot +
    ggplot2::geom_hline(
      yintercept = null_value, linetype = "dashed", colour = "grey70"
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$conf_low, ymax = .data$conf_high),
      width = 0, linewidth = marks$line
    ) +
    ggplot2::geom_point(size = marks$point) +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    study_axis("x", n) +
    ggplot2::coord_cartesian(ylim = limits) +
    ggplot2::labs(x = NULL, y = effect_label)
}

# The heatmap. Horizontal: one row per level, studies along the x-axis, with
# moderator names as bold heading rows ("standard") or facet strips on the
# left ("compact"). Vertical: one column per level, studies up the y-axis,
# level labels angled above the columns and moderator names centred above
# them; a continuous moderator's column is labelled with its name in bold.
build_heatmap_plot <- function(heatmap, titles, colours, marks, layout,
                               vertical, continuous_style, continuous_range,
                               sizes, level_angle, x_label) {
  label_lookup <- stats::setNames(heatmap$rows$label, heatmap$rows$key)
  header_keys <- heatmap$rows$key[heatmap$rows$header]
  cont_keys <- heatmap$rows$key[heatmap$rows$continuous]
  # Range of each continuous moderator, by row key, for continuous_range = "label".
  range_lookup <- stats::setNames(
    vapply(heatmap$ranges, format_range, character(1)),
    sprintf(".cont:%s", names(heatmap$ranges))
  )
  show_range_label <- continuous_range == "label" && length(cont_keys)
  # Bold heading text, at the moderator-name size if it differs from the
  # level-label size.
  heading <- function(text) {
    text <- paste0("<b>", text, "</b>")
    if (sizes[["moderator"]] != sizes[["level"]]) {
      text <- sprintf("<span style='font-size:%gpt'>%s</span>",
                      sizes[["moderator"]], text)
    }
    text
  }
  with_range <- function(text, keys) {
    sprintf("%s <span style='color:%s'>(%s)</span>", text,
            continuous_text_colour, range_lookup[keys])
  }
  markdown_labels <- function(keys) {
    text <- escape_markdown(unname(label_lookup[keys]))
    is_bold <- keys %in% c(header_keys, cont_keys)
    text[is_bold] <- heading(text[is_bold])
    if (show_range_label) {
      is_cont <- keys %in% cont_keys
      text[is_cont] <- with_range(text[is_cont], keys[is_cont])
    }
    text
  }
  block_titles <- stats::setNames(titles, as.character(seq_along(titles)))

  tiles <- heatmap$tiles
  if (vertical) {
    tiles$row <- factor(tiles$row, levels = heatmap$rows$key)
    cont <- heatmap$cont
    cont$row <- factor(cont$row, levels = levels(tiles$row))
    # A continuous column is labelled with its name, so its strip is empty.
    cont_blocks <- unique(as.character(heatmap$rows$block[heatmap$rows$continuous]))
    block_titles[cont_blocks] <- ""
    columns <- table(factor(heatmap$rows$block, levels = names(block_titles)))
    block_titles <- wrap_title(block_titles, as.integer(columns))
    just <- angle_just(level_angle)
    scale <- ggplot2::scale_x_discrete(
      position = "top", labels = markdown_labels,
      # A guide-local theme survives the theme applied to the whole patchwork.
      guide = ggplot2::guide_axis(theme = ggplot2::theme(
        axis.text.x.top = ggtext::element_markdown(
          angle = level_angle, hjust = just[["h"]], vjust = just[["v"]],
          size = sizes[["level"]]
        )
      ))
    )
    facets <- ggplot2::facet_grid(
      cols = ggplot2::vars(.data$block), scales = "free_x", space = "free_x",
      labeller = ggplot2::as_labeller(block_titles)
    )
    tile_aes <- ggplot2::aes(x = .data$row, y = .data$rank, fill = .data$fill_state)
    labels <- list(ggplot2::labs(x = NULL, y = NULL), study_axis("y", max(tiles$rank)))
  } else {
    cont <- heatmap$cont
    if (layout == "standard") {
      scale <- ggplot2::scale_y_discrete(
        labels = markdown_labels,
        guide = ggplot2::guide_axis(theme = ggplot2::theme(
          axis.text.y = ggtext::element_markdown(
            hjust = 1, vjust = 0.5, size = sizes[["level"]]
          )
        ))
      )
      facets <- ggplot2::facet_grid(
        rows = ggplot2::vars(.data$block), scales = "free_y", space = "free_y",
        labeller = ggplot2::as_labeller(block_titles)
      )
    } else {
      # The moderator name is in the facet strip, so a continuous row's own
      # label is empty, or its range.
      scale <- ggplot2::scale_y_discrete(
        labels = function(keys) {
          text <- unname(label_lookup[keys])
          is_cont <- keys %in% cont_keys
          text[is_cont] <- if (show_range_label) range_lookup[keys[is_cont]] else ""
          text
        },
        guide = ggplot2::guide_axis(theme = ggplot2::theme(
          axis.text.y = ggplot2::element_text(size = sizes[["level"]])
        ))
      )
      facets <- ggplot2::facet_grid(
        rows = ggplot2::vars(.data$block), scales = "free_y", space = "free_y",
        switch = "y", labeller = ggplot2::as_labeller(block_titles)
      )
    }
    tile_aes <- ggplot2::aes(x = .data$rank, y = .data$row, fill = .data$fill_state)
    labels <- list(ggplot2::labs(x = x_label, y = NULL), study_axis("x", max(tiles$rank)))
  }

  ggplot2::ggplot(tiles, tile_aes) +
    ggplot2::geom_tile(colour = "white", linewidth = marks$border) +
    ggplot2::scale_fill_manual(
      values = c(colours, absent = "#f0f0f0", spacer = "#ffffff"),
      guide = "none"
    ) +
    continuous_layers(
      cont, continuous_style, colours, continuous_grey(colours),
      border = marks$border, vertical = vertical
    ) +
    scale +
    facets +
    labels
}
