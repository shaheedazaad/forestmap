# Getting started with forestmap

``` r

library(forestmap)
```

## What forestmap draws

A forest plot shows each study in a meta-analysis with its effect size
and confidence interval. forestmap sorts the studies from the smallest
to the largest effect and adds a heatmap underneath showing each study’s
properties: its population, design, country, or anything else you’ve
coded. Reading down a column tells you about one study; reading across a
row tells you where studies with that property fall among the effects.

## 1. Prepare your data

You need a data frame with **one row per study** and these columns:

| Column | What it holds |
|----|----|
| Effect size | The study’s effect, e.g. a standardised mean difference. |
| Lower bound | Lower end of its 95% confidence interval. |
| Upper bound | Upper end of its 95% confidence interval. |
| One column per study property | A factor giving the study’s level, e.g. `"RCT"`. `NA` means the study doesn’t report it. |

The package comes with made-up data from 60 studies:

``` r

head(forestmap_example)
#>         study   smd ci_lower ci_upper   n population     outcome
#> 1   Wang 2005 0.470    0.223    0.716 253   Children        <NA>
#> 2 Hughes 2013 0.261   -0.117    0.638 108   Children Behavioural
#> 3  Rossi 2005 0.510    0.092    0.928  88     Adults Self-report
#> 4  Baker 2006 0.410    0.170    0.649 268     Adults        <NA>
#> 5 Hughes 2008 0.786    0.442    1.130 130   Children Self-report
#> 6 Martin 2023 0.260   -0.234    0.754  63     Adults        <NA>
#>               design   country
#> 1                RCT       USA
#> 2                RCT      <NA>
#> 3 Quasi-experimental    Canada
#> 4 Quasi-experimental Australia
#> 5                RCT       USA
#> 6                RCT       USA
```

The order of a factor’s levels sets the order of the rows in the
heatmap, so use `factor(x, levels = ...)` to change it.

If you’ve computed effect sizes with
[metafor](https://www.metafor-project.org)’s `escalc()`, which gives
each study’s effect (`yi`) and sampling variance (`vi`), add the
confidence interval like this:

``` r

dat$ci_lower <- dat$yi - 1.96 * sqrt(dat$vi)
dat$ci_upper <- dat$yi + 1.96 * sqrt(dat$vi)
```

## 2. Make the plot

Tell
[`plot_forestmap()`](https://shaheedazaad.github.io/forestmap/reference/plot_forestmap.md)
which column is which. Naming the study properties sets the headings in
the plot:

``` r

plot_forestmap(
  forestmap_example,
  es = "smd",
  lb = "ci_lower",
  ub = "ci_upper",
  moderators = c(
    "Population" = "population",
    "Outcome measure" = "outcome",
    "Study design" = "design",
    "Country" = "country"
  )
)
```

![](forestmap_files/figure-html/unnamed-chunk-4-1.png)

## 3. Read the plot

- Each column is one study. The top panel shows its effect and 95%
  confidence interval; the tiles below show its properties.
- **Blue** studies have a confidence interval entirely above zero,
  **red** ones entirely below, and **grey** ones include zero. Each
  study’s tiles take the same colour.
- A row with its tiles bunched at one end means studies with that
  property tend to find smaller (left) or larger (right) effects. Here,
  every negative effect comes from an RCT, and the largest effects come
  mostly from quasi-experimental studies using self-report measures.

## 4. Save it

[`plot_forestmap()`](https://shaheedazaad.github.io/forestmap/reference/plot_forestmap.md)
returns the plot; saving it is up to you. Choose the size when you save:

``` r

p <- plot_forestmap(
  forestmap_example, "smd", "ci_lower", "ci_upper",
  moderators = c("Population" = "population", "Study design" = "design")
)

ggplot2::ggsave("forestmap.png", p, width = 7, height = 5.25, dpi = 300)
ggplot2::ggsave("forestmap.svg", p, width = 7, height = 5.25)
ggplot2::ggsave("forestmap.pdf", p, width = 7, height = 5.25, device = cairo_pdf)
```

With many study properties, make the plot taller (e.g. `height = 10`).

## Next steps

[Customising the
plot](https://shaheedazaad.github.io/forestmap/articles/customising.html)
shows how to change the headings, colours, font, sizes and layout, with
an example of each.
