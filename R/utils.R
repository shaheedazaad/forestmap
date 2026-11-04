# Internal helpers for plot_forestmap(). Not exported.

# Font -------------------------------------------------------------------------

# The default font, Roboto Condensed, ships with the package (inst/fonts,
# SIL Open Font License). If it is installed on the system we use that copy,
# which every graphics device can see; otherwise we register the bundled
# files with systemfonts, which ragg and svglite (ggsave() to PNG/SVG) use.
default_font <- "Roboto Condensed"

use_default_font <- function() {
  if (default_font %in% systemfonts::system_fonts()$family ||
      default_font %in% systemfonts::registry_fonts()$family) {
    return(default_font)
  }
  font_dir <- system.file("fonts", package = "forestmap")
  systemfonts::register_font(
    name = default_font,
    plain = file.path(font_dir, "RobotoCondensed-Regular.ttf"),
    bold = file.path(font_dir, "RobotoCondensed-Bold.ttf")
  )
  default_font
}

# `font` may be an installed family name ("Arial Narrow") or a path to a
# .ttf/.otf file, which is registered with systemfonts so that ragg/svglite
# devices (ggsave() to png/svg) can use it. A font that isn't installed falls
# back to the bundled default, with a warning.
resolve_font <- function(font = default_font, warn = TRUE) {
  if (!is.character(font) || length(font) != 1L || is.na(font) || !nzchar(font)) {
    stop("`font` must be a single font name or a path to a font file.", call. = FALSE)
  }
  if (identical(font, default_font)) {
    return(use_default_font())
  }
  if (grepl("\\.(ttf|otf)$", font, ignore.case = TRUE)) {
    if (!file.exists(font)) {
      stop(sprintf("Font file not found: %s", font), call. = FALSE)
    }
    # Register under a forestmap-specific name: the file's own name may
    # clash with an installed font (e.g. Arial.ttf), which systemfonts refuses.
    family <- paste0("forestmap-", tools::file_path_sans_ext(basename(font)))
    if (!family %in% systemfonts::registry_fonts()$family) {
      systemfonts::register_font(name = family, plain = font)
    }
    return(family)
  }
  if (font %in% c("sans", "serif", "mono") || font_installed(font)) {
    return(font)
  }
  if (warn) {
    warning(sprintf(
      "Font '%s' is not installed; using '%s' instead.", font, default_font
    ), call. = FALSE)
  }
  use_default_font()
}

font_installed <- function(family) {
  family %in% c(
    systemfonts::system_fonts()$family,
    systemfonts::registry_fonts()$family
  )
}

# Axis and layout --------------------------------------------------------------

# Symmetric limits around the null value, rounded up to a tidy step, wide
# enough to show every CI (and the ROPE, if given) in full. On ratio scales
# (null value above 0, every value positive) the axis stops at 0 rather than
# showing impossible negative ratios.
default_y_limits <- function(lb, ub, null_value, rope = NULL) {
  m <- max(abs(c(lb, ub, rope) - null_value), na.rm = TRUE)
  if (m == 0) m <- 1 # every CI is exactly the null value: any range will do
  step <- 10^floor(log10(m)) / 2
  m <- ceiling(m / step) * step
  limits <- c(null_value - m, null_value + m)
  if (null_value > 0 && min(c(lb, rope)) >= 0 && limits[[1]] < 0) {
    limits[[1]] <- 0
  }
  limits
}

# The reference design gave the forest plot 1/3 of the height with 18 heatmap
# rows. Keep that row-to-forest proportion for any number of rows, clamped so neither
# panel becomes unreadably small.
reference_heatmap_rows <- 18
auto_forest_height <- function(n_rows) {
  heatmap_share <- 2 * n_rows / reference_heatmap_rows
  min(max(1 / (1 + heatmap_share), 0.2), 0.6)
}

# Moderators -------------------------------------------------------------------

# Keep the (max_levels - 1) most common levels and merge the rest into
# "Other". NA (not reported) is not counted and stays NA. Ties for the
# last kept place are all kept, with a warning. If only one level would be
# merged it keeps its own name.
lump_levels <- function(x, max_levels, title, other = "Other") {
  levs <- levels(x)
  if (length(levs) <= max_levels) return(x)
  k <- max_levels - 1L
  counts <- table(factor(x, levels = levs))
  threshold <- sort(as.integer(counts), decreasing = TRUE)[k]
  keep <- levs[counts >= threshold]
  if (length(keep) > k) {
    tied <- levs[counts == threshold]
    warning(sprintf(
      paste0(
        "Moderator '%s': couldn't choose a top %d because of a tie ",
        "(%s each have %d studies). Showing all %d levels that qualify."
      ),
      title, k, paste(tied, collapse = ", "), threshold, length(keep)
    ), call. = FALSE)
  }
  lumped <- setdiff(levs, keep)
  if (length(lumped) <= 1L) return(x)
  out <- as.character(x)
  out[out %in% lumped] <- other
  factor(out, levels = c(setdiff(keep, other), other))
}

# Studies ---------------------------------------------------------------------

# Order studies by effect size (ties keep input order) and classify
# each by whether its CI excludes the null value.
order_studies <- function(estimate, lower, upper, null_value) {
  studies <- data.frame(
    row_id = seq_along(estimate),
    estimate = estimate,
    conf_low = lower,
    conf_high = upper
  )
  studies <- studies[order(studies$estimate, studies$row_id, method = "radix"), ]
  studies$rank <- seq_len(nrow(studies))
  studies$sign_label <- ifelse(
    studies$conf_low > null_value, "positive",
    ifelse(studies$conf_high < null_value, "negative", "null")
  )
  rownames(studies) <- NULL
  studies
}

# Heatmap tiles. One facet panel ("block") per moderator. Row keys are
# "<moderator index>:<level>" so equal level names in different moderators
# stay separate. In the standard layout each block starts with a heading row
# (".header:<index>") drawn as blank tiles.
build_heatmap <- function(data, studies, moderators, titles, layout) {
  rows <- list()
  tiles <- list()
  for (i in seq_along(moderators)) {
    values <- as.character(data[[moderators[[i]]]][studies$row_id])
    block <- as.character(i)
    if (layout == "standard") {
      key <- sprintf(".header:%d", i)
      rows[[length(rows) + 1L]] <- data.frame(
        key = key, label = titles[[i]], block = block, header = TRUE
      )
      tiles[[length(tiles) + 1L]] <- data.frame(
        rank = studies$rank, row = key, block = block, fill_state = "spacer"
      )
    }
    for (lev in levels(data[[moderators[[i]]]])) {
      key <- sprintf("%d:%s", i, lev)
      included <- !is.na(values) & values == lev
      rows[[length(rows) + 1L]] <- data.frame(
        key = key, label = lev, block = block, header = FALSE
      )
      tiles[[length(tiles) + 1L]] <- data.frame(
        rank = studies$rank,
        row = key,
        block = block,
        fill_state = ifelse(included, studies$sign_label, "absent")
      )
    }
  }
  rows <- do.call(rbind, rows)
  tiles <- do.call(rbind, tiles)
  tiles$row <- factor(tiles$row, levels = rev(rows$key))
  tiles$block <- factor(tiles$block, levels = as.character(seq_along(moderators)))
  list(
    tiles = tiles,
    rows = rows,
    # Gaps between moderators count as half a row for the automatic height.
    n_rows = nrow(rows) + 0.5 * (length(moderators) - 1)
  )
}

escape_markdown <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# Theme ------------------------------------------------------------------------

# forestmap's base theme: ggplot2's classic theme (axis lines, no grid, no
# panel border) with full-size black axis text, black lines and ticks, and an
# even margin.
theme_forestmap <- function(base_size, base_family) {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      axis.line = ggplot2::element_line(
        colour = "black", linewidth = 0.5, lineend = "butt"
      ),
      axis.ticks = ggplot2::element_line(colour = "black", linewidth = 0.5),
      axis.text = ggplot2::element_text(colour = "black", size = ggplot2::rel(1)),
      plot.margin = ggplot2::margin(base_size / 2, base_size / 2,
                                    base_size / 2, base_size / 2)
    )
}
