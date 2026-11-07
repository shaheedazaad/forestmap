# Internal helpers for continuous (numeric) moderators. Not exported.
#
# A continuous moderator is one heatmap row. Each study's tile shows its
# value in one of three styles:
# * "bar":    a bar in the significance colour whose height is the value
#             (the default).
# * "tint":   the study's significance colour, pale for low values and full
#             strength for high values.
# * "stripe": a grey shade for the value, with a band in the significance
#             colour along the bottom of the tile.
# Values are scaled from the moderator's lowest value (0) to its highest (1).

continuous_text_colour <- "#666666"

# Palest tint, as a share of the way from white to the full colour.
tint_floor <- 0.18
# Lightest grey of the stripe gradient.
stripe_light <- "#e6e6e6"
# Shortest bar, as a share of the full bar height, so its colour shows.
bar_floor <- 0.12
# Bars and stripe bands sit inside the tile, clear of its white border.
tile_inset <- 0.06

# The grey the continuous gradients end at: as dark as the palette's positive
# and negative colours (CIELAB lightness), kept between 45 and 60 so it is
# neither near-black nor too faint to show a gradient. For the default palette
# this is about #6b6b6b.
continuous_grey <- function(colours) {
  lab <- grDevices::convertColor(
    t(grDevices::col2rgb(colours[c("positive", "negative")])) / 255,
    from = "sRGB", to = "Lab"
  )
  lightness <- min(max(mean(lab[, 1]), 45), 60)
  grDevices::hcl(h = 0, c = 0, l = lightness)
}

# Tint colour of `col` for scaled values `s` in [0, 1].
tint_colour <- function(col, s) {
  ramp <- grDevices::colorRamp(c("#ffffff", col))
  grDevices::rgb(ramp(tint_floor + (1 - tint_floor) * s), maxColorValue = 255)
}

# Grey shade of the stripe style for scaled values `s` in [0, 1].
stripe_colour <- function(s, grey) {
  ramp <- grDevices::colorRamp(c(stripe_light, grey), space = "Lab")
  grDevices::rgb(ramp(s), maxColorValue = 255)
}

# The neutral gradient that stands for a style in a legend or range key.
# Tint has three hues, so its key is a grey ramp of the same lightness range.
key_colours <- function(style, grey, s = seq(0, 1, length.out = 25)) {
  if (style == "tint") tint_colour(grey, s) else stripe_colour(s, grey)
}

# Scale values to [0, 1] from their lowest to their highest. If every study
# has the same value, all get 1.
rescale_unit <- function(x, range) {
  if (range[[1]] == range[[2]]) return(ifelse(is.na(x), NA_real_, 1))
  (x - range[[1]]) / diff(range)
}

# Short display form of a number: 3 significant digits, no trailing zeros.
format_number <- function(x) {
  format(signif(x, 3), scientific = FALSE, drop0trailing = TRUE, trim = TRUE,
         big.mark = ",")
}

format_range <- function(range) {
  paste0(format_number(range[[1]]), "\u2013", format_number(range[[2]]))
}

# Layers drawing a continuous moderator's tiles. `cont` has one row per
# study with a value: rank, row, block, sign_label and s (scaled value).
# The tile behind each value (light grey for bars) comes from the main
# heatmap layer. `border` is the width of the white border between tiles.
continuous_layers <- function(cont, style, colours, grey, border) {
  if (!nrow(cont)) return(list())
  sig <- unname(colours[cont$sign_label])
  switch(style,
    tint = list(ggplot2::geom_tile(
      ggplot2::aes(x = .data$rank, y = .data$row),
      data = cont, inherit.aes = FALSE, colour = "white", linewidth = border,
      fill = mapply(tint_colour, sig, cont$s, USE.NAMES = FALSE)
    )),
    stripe = list(
      ggplot2::geom_tile(
        ggplot2::aes(x = .data$rank, y = .data$row),
        data = cont, inherit.aes = FALSE, colour = "white", linewidth = border,
        fill = stripe_colour(cont$s, grey)
      ),
      # The row is the only one in its block, so it sits at y = 1.
      ggplot2::geom_rect(
        ggplot2::aes(xmin = .data$rank - 0.5 + tile_inset,
                     xmax = .data$rank + 0.5 - tile_inset),
        ymin = 0.5 + 0.03, ymax = 0.5 + 0.22,
        data = cont, inherit.aes = FALSE, fill = sig, colour = NA
      )
    ),
    bar = {
      cont$bar_top <- 0.5 + tile_inset +
        (1 - 2 * tile_inset) * (bar_floor + (1 - bar_floor) * cont$s)
      list(ggplot2::geom_rect(
        ggplot2::aes(xmin = .data$rank - 0.5, xmax = .data$rank + 0.5,
                     ymax = .data$bar_top),
        ymin = 0.5 + tile_inset,
        data = cont, inherit.aes = FALSE, fill = sig, colour = "white",
        linewidth = border
      ))
    }
  )
}

# Range key at the right end of a continuous row: a thin bracket (bars) or a
# small vertical gradient (tint, stripe), with the highest value at the top
# and the lowest at the bottom.
GeomRangeEnd <- ggplot2::ggproto(
  "GeomRangeEnd", ggplot2::Geom,
  required_aes = c("ymin", "ymax"),
  draw_key = ggplot2::draw_key_blank,
  draw_panel = function(data, panel_params, coord, key_labels, key_fills,
                        key_size, key_family, key_colour) {
    labels <- key_labels
    fills <- key_fills
    fontsize <- key_size
    family <- key_family
    colour <- key_colour
    d <- coord$transform(data, panel_params)
    y0 <- d$ymin[[1]]
    y1 <- d$ymax[[1]]
    gap <- grid::unit(0.35 * fontsize, "pt")
    x0 <- grid::unit(1, "npc") + gap
    if (is.null(fills)) {
      mark_width <- grid::unit(0, "pt")
      mark <- grid::segmentsGrob(
        x0, grid::unit(y0, "npc"), x0, grid::unit(y1, "npc"),
        gp = grid::gpar(col = colour, lwd = 0.6)
      )
    } else {
      k <- length(fills)
      step <- (y1 - y0) / k
      mark_width <- grid::unit(0.4 * fontsize, "pt")
      mark <- grid::rectGrob(
        x = x0, y = grid::unit(y0 + (seq_len(k) - 1) * step, "npc"),
        width = mark_width, height = grid::unit(step, "npc"),
        just = c("left", "bottom"), gp = grid::gpar(fill = fills, col = NA)
      )
    }
    x_text <- x0 + mark_width + grid::unit(0.25 * fontsize, "pt")
    text_gp <- grid::gpar(fontsize = fontsize, fontfamily = family, col = colour)
    grid::grobTree(
      mark,
      grid::textGrob(labels[[2]], x_text, grid::unit(y1, "npc"),
                     just = c("left", "top"), gp = text_gp),
      grid::textGrob(labels[[1]], x_text, grid::unit(y0, "npc"),
                     just = c("left", "bottom"), gp = text_gp)
    )
  }
)

range_end_layer <- function(block, range, style, grey, fontsize, family) {
  ggplot2::layer(
    geom = GeomRangeEnd, stat = "identity", position = "identity",
    data = data.frame(block = block, ymin = 0.5 + tile_inset,
                      ymax = 1.5 - tile_inset),
    mapping = ggplot2::aes(ymin = .data$ymin, ymax = .data$ymax),
    inherit.aes = FALSE, show.legend = FALSE,
    params = list(
      key_labels = c(format_number(range[[1]]), format_number(range[[2]])),
      key_fills = if (style == "bar") NULL else key_colours(style, grey),
      key_size = fontsize, key_family = family, key_colour = continuous_text_colour
    )
  )
}

# Room the range keys need to the right of the heatmap, in points.
range_end_width <- function(ranges, fontsize) {
  chars <- max(nchar(c(vapply(ranges, function(r) format_number(r), character(2)))))
  (0.35 + 0.4 + 0.25) * fontsize + 0.55 * fontsize * chars
}

# Legend for one continuous moderator, as a ggplot whose legend is the only
# thing drawn: a colour bar for tint and stripe, or a short and a tall sample
# bar for bars.
continuous_legend <- function(title, range, style, grey, text_size, family) {
  legend_theme <- theme_forestmap(base_size = text_size, base_family = family) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.title = ggplot2::element_text(size = text_size - 1),
      legend.text = ggplot2::element_text(size = text_size - 1),
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      legend.box.margin = ggplot2::margin(0, 0, 0, 0)
    )
  if (style == "bar") {
    key_bar <- function(data, params, size) {
      grid::grobTree(
        grid::rectGrob(gp = grid::gpar(fill = "#f0f0f0", col = NA)),
        grid::rectGrob(
          y = grid::unit(tile_inset, "npc"), vjust = 0,
          height = grid::unit((1 - 2 * tile_inset) * data$alpha, "npc"),
          width = grid::unit(0.8, "npc"),
          gp = grid::gpar(fill = grey, col = NA)
        )
      )
    }
    labels <- unique(c(format_number(range[[1]]), format_number(range[[2]])))
    keys <- data.frame(x = seq_along(labels), key = factor(labels, levels = labels))
    plot <- ggplot2::ggplot(keys, ggplot2::aes(.data$x, .data$x, alpha = .data$key)) +
      ggplot2::geom_point(key_glyph = key_bar) +
      ggplot2::scale_alpha_manual(
        title, values = c(bar_floor, 1)[seq_along(labels)],
        guide = ggplot2::guide_legend(
          title.position = "left", nrow = 1,
          keywidth = grid::unit(0.7, "lines"), keyheight = grid::unit(1.1, "lines")
        )
      )
  } else {
    limits <- if (range[[1]] == range[[2]]) range + c(-0.5, 0.5) else range
    plot <- ggplot2::ggplot(
      data.frame(v = limits), ggplot2::aes(.data$v, .data$v, colour = .data$v)
    ) +
      ggplot2::geom_point() +
      ggplot2::scale_colour_gradientn(
        title, colours = key_colours(style, grey), limits = limits,
        labels = format_number,
        guide = ggplot2::guide_colourbar(
          title.position = "left", title.vjust = 0.9,
          barheight = grid::unit(0.6, "lines"), barwidth = grid::unit(5, "lines")
        )
      )
  }
  plot + legend_theme
}

# A grob that draws the legends of `plots` in one right-aligned row. The
# legends are built when the grob is drawn, because measuring their text
# needs the graphics device the plot is drawn on.
legend_row <- function(plots, gap_pt) {
  grid::gTree(plots = plots, gap_pt = gap_pt, cl = "forestmap_legends")
}

#' @exportS3Method grid::makeContent
makeContent.forestmap_legends <- function(x) {
  legends <- lapply(x$plots, extract_legend)
  widths <- grid::unit(1, "null")
  for (g in legends) {
    widths <- grid::unit.c(widths, grid::unit(x$gap_pt, "pt"), sum(g$widths))
  }
  layout <- grid::grid.layout(1, length(widths), widths = widths)
  children <- lapply(seq_along(legends), function(i) {
    grid::gTree(
      children = grid::gList(legends[[i]]),
      vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2 * i + 1)
    )
  })
  frame <- grid::gTree(
    children = do.call(grid::gList, children),
    vp = grid::viewport(layout = layout)
  )
  grid::setChildren(x, grid::gList(frame))
}

extract_legend <- function(plot) {
  table <- ggplot2::ggplotGrob(plot)
  boxes <- grep("^guide-box", table$layout$name)
  boxes <- boxes[!vapply(table$grobs[boxes], inherits, logical(1), "zeroGrob")]
  table$grobs[[boxes[[1]]]]
}

# Height of the legend row: enough for a colour bar with labels underneath
# (the taller of the two kinds of legend).
legend_row_height <- function(text_size) {
  grid::unit(1.9 * text_size, "pt")
}
