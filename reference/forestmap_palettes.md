# Colour palettes for forestmap plots

Ready-made palettes that can be passed by name to the `palette` argument
of
[`plot_forestmap()`](https://shaheedazaad.github.io/forestmap/reference/plot_forestmap.md).
Each palette has three colours:

## Usage

``` r
forestmap_palettes
```

## Format

A named list of named character vectors (hex colours):

- default:

  Blue / red / grey.

- okabe_ito:

  Blue and vermillion from the Okabe-Ito palette (Okabe & Ito, 2008),
  designed to stay distinguishable with common colour-vision
  deficiencies; light grey for null.

- viridis:

  Teal / purple / grey.

- greyscale:

  Black / dark grey / light grey, for print.

## Details

- `positive`: the 95% CI lies entirely above the null value.

- `negative`: the 95% CI lies entirely below the null value.

- `null`: the 95% CI includes the null value.

## Examples

``` r
names(forestmap_palettes)
#> [1] "default"   "okabe_ito" "viridis"   "greyscale"
forestmap_palettes$okabe_ito
#>  positive  negative      null 
#> "#0072B2" "#D55E00" "#bdbdbd" 
```
