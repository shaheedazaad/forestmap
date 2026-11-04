# Example meta-analysis data

Made-up studies from a meta-analysis of an intervention: each study's
standardised mean difference and sampling variance (the `yi`/`vi` pair
that `metafor::escalc()` produces), its sample size, and four study
properties. Some studies don't report their outcome measure or country
(`NA`). Use it to try out
[`plot_forestmap()`](https://shaheedazaad.github.io/forestmap/reference/plot_forestmap.md).

## Usage

``` r
forestmap_example
```

## Format

A data frame with 60 rows (studies) and 8 columns:

- study:

  Study label (first author and year).

- smd:

  Standardised mean difference (Hedges' g).

- vi:

  Sampling variance of `smd`.

- n:

  Total sample size.

- population:

  Factor: `Adults`, `Children` or `Clinical`.

- outcome:

  Factor: `Self-report` or `Behavioural`; `NA` = not reported.

- design:

  Factor: `RCT` or `Quasi-experimental`.

- country:

  Factor: `USA`, `UK`, `Australia`, `Germany` or `Canada`; `NA` = not
  reported.

## Source

Simulated; see `data-raw/forestmap_example.R` in the package source.
