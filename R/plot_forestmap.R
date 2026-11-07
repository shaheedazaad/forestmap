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
#' @param forest_height Share of the plot's height given to the forest plot
#'   (the top panel), between 0 and 1 (`0.5` gives the forest plot and heatmap
#'   equal height).
#'   `"auto"` (the default) gives the heatmap more room the more rows it has.
#' @param null_value The value meaning "no effect": `0` for differences and
#'   log ratios, `1` for raw ratios such as odds ratios.
#' @param rope Optional region of practical equivalence, drawn as a shaded
#'   band: two numbers such as `c(-0.1, 0.1)`, or one number for a band
#'   symmetric around `null_value`.
#' @param y_limits Optional y-axis limits, e.g. `c(-1, 1)`. By default the axis
#'   is symmetric around `null_value` and shows every confidence interval in
#'   full; for ratios (`null_value` above 0 and every value positive) it
#'   starts at 0.
#' @param y_label,x_label Axis titles.
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
#'   e.g. "Mean age (19-67)"), `"end"` (a small key at the right end of the
#'   row) or `"legend"` (below the plot).
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
  continuous_range = c("none", "label", "end", "legend")
) {
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
  value_cols <- c(es, lb, ub, vi, se)
  missing_cols <- setdiff(c(value_cols, unname(moderators)), names(data))
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
  marks <- mark_sizes(nrow(studies), text_size)

  # ---- forest plot (top panel) ---------------------------------------------
  forest_plot <- ggplot2::ggplot(
    studies,
    ggplot2::aes(x = .data$rank, y = .data$estimate, colour = .data$sign_label)
  )
  if (!is.null(rope_vals)) {
    forest_plot <- forest_plot +
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
  forest_plot <- forest_plot +
    ggplot2::geom_hline(
      yintercept = null_value, linetype = "dashed", colour = "grey70"
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$conf_low, ymax = .data$conf_high),
      width = 0, linewidth = marks$line
    ) +
    ggplot2::geom_point(size = marks$point) +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::coord_cartesian(ylim = y_limits) +
    ggplot2::labs(x = NULL, y = y_label)

  # ---- heatmap --------------------------------------------------------------
  heatmap <- build_heatmap(data, studies, moderators, titles, layout, continuous)
  label_lookup <- stats::setNames(heatmap$rows$label, heatmap$rows$key)
  header_keys <- heatmap$rows$key[heatmap$rows$header]
  cont_keys <- heatmap$rows$key[heatmap$rows$continuous]
  # Range of each continuous row, by row key, for continuous_range = "label".
  range_lookup <- stats::setNames(
    vapply(heatmap$ranges, format_range, character(1)),
    sprintf(".cont:%s", names(heatmap$ranges))
  )
  show_range_label <- continuous_range == "label" && length(cont_keys)
  block_labels <- ggplot2::as_labeller(
    stats::setNames(titles, as.character(seq_along(titles)))
  )

  if (layout == "standard") {
    y_scale <- ggplot2::scale_y_discrete(
      labels = function(keys) {
        text <- escape_markdown(unname(label_lookup[keys]))
        is_bold <- keys %in% c(header_keys, cont_keys)
        text[is_bold] <- paste0("<b>", text[is_bold], "</b>")
        if (show_range_label) {
          is_cont <- keys %in% cont_keys
          text[is_cont] <- sprintf(
            "%s <span style='color:%s'>(%s)</span>", text[is_cont],
            continuous_text_colour, range_lookup[keys[is_cont]]
          )
        }
        text
      },
      # A guide-local theme survives the theme applied to the whole patchwork.
      guide = ggplot2::guide_axis(theme = ggplot2::theme(
        axis.text.y = ggtext::element_markdown(hjust = 1, vjust = 0.5)
      ))
    )
    facets <- ggplot2::facet_grid(
      rows = ggplot2::vars(.data$block), scales = "free_y", space = "free_y",
      labeller = block_labels
    )
  } else {
    # The moderator name is in the facet strip, so a continuous row's own
    # label is empty, or its range.
    y_scale <- ggplot2::scale_y_discrete(
      labels = function(keys) {
        text <- unname(label_lookup[keys])
        is_cont <- keys %in% cont_keys
        text[is_cont] <- if (show_range_label) range_lookup[keys[is_cont]] else ""
        text
      }
    )
    facets <- ggplot2::facet_grid(
      rows = ggplot2::vars(.data$block), scales = "free_y", space = "free_y",
      switch = "y", labeller = block_labels
    )
  }

  heatmap_plot <- ggplot2::ggplot(
    heatmap$tiles,
    ggplot2::aes(x = .data$rank, y = .data$row, fill = .data$fill_state)
  ) +
    ggplot2::geom_tile(colour = "white", linewidth = marks$border) +
    ggplot2::scale_fill_manual(
      values = c(colours, absent = "#f0f0f0", spacer = "#ffffff"),
      guide = "none"
    ) +
    continuous_layers(
      heatmap$cont, continuous_style, colours, continuous_grey(colours),
      border = marks$border
    ) +
    y_scale +
    facets +
    ggplot2::labs(x = x_label, y = NULL)

  # Range keys at the right end of continuous rows sit outside the panel.
  end_margin <- 0
  if (continuous_range == "end" && length(heatmap$ranges)) {
    key_size <- 0.8 * text_size
    for (block in names(heatmap$ranges)) {
      heatmap_plot <- heatmap_plot + range_end_layer(
        factor(block, levels = levels(heatmap$tiles$block)),
        heatmap$ranges[[block]], continuous_style, continuous_grey(colours),
        key_size, family
      )
    }
    heatmap_plot <- heatmap_plot + ggplot2::coord_cartesian(clip = "off")
    end_margin <- range_end_width(heatmap$ranges, key_size)
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
    forest_height <- auto_forest_height(heatmap$n_rows)
  }

  heights <- c(forest_height, 1 - forest_height)
  plot <- patchwork::free(forest_plot, type = "label", side = "l") / heatmap_plot
  if (!is.null(legends)) {
    heights <- grid::unit.c(grid::unit(heights, "null"), legend_row_height(text_size))
    plot <- plot / patchwork::wrap_elements(full = legends)
  }

  plot <- plot +
    patchwork::plot_layout(heights = heights) &
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
        angle = 0, face = "bold", hjust = 0, vjust = 0.5, size = text_size,
        margin = ggplot2::margin(r = 8)
      ),
      # The standard layout's headings are axis labels, so hide its strips.
      strip.text.y.right = ggplot2::element_blank(),
      strip.switch.pad.grid = ggplot2::unit(0, "pt"),
      panel.spacing.y = ggplot2::unit(0.6 * text_size, "pt")
    )
  if (end_margin > 0) {
    plot[[2]] <- plot[[2]] + ggplot2::theme(plot.margin = ggplot2::margin(
      text_size / 2, text_size / 2 + end_margin, text_size / 2, text_size / 2
    ))
  }
  plot
}
