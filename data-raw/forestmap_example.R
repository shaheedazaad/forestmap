# Builds `forestmap_example`: made-up studies from a meta-analysis.
# Run from the package root: source("data-raw/forestmap_example.R")
#
# Each row is one study: its standardised mean difference (Hedges' g) and
# sampling variance (as from metafor::escalc()), its sample size, and four
# study properties. Some studies don't
# report their country or outcome measure (NA).

set.seed(2026)

n_studies <- 60

pick <- function(levels, prob) {
  sample(levels, n_studies, replace = TRUE, prob = prob)
}

population <- pick(c("Adults", "Children", "Clinical"), c(0.5, 0.3, 0.2))
outcome <- pick(c("Self-report", "Behavioural"), c(0.6, 0.4))
design <- pick(c("RCT", "Quasi-experimental"), c(0.55, 0.45))
country <- pick(c("USA", "UK", "Australia", "Germany", "Canada"),
                c(0.35, 0.25, 0.15, 0.15, 0.10))

# Not reported
outcome[sample(n_studies, 4)] <- NA
country[sample(n_studies, 6)] <- NA

# How each property shifts the true effect.
shift <- c(
  Adults = 0, Children = 0.15, Clinical = -0.35,
  `Self-report` = 0.10, Behavioural = -0.05,
  RCT = -0.05, `Quasi-experimental` = 0.08,
  USA = 0.03, UK = 0, Australia = 0.05, Germany = -0.02, Canada = 0
)
shift_of <- function(x) ifelse(is.na(x), 0, shift[x])

n <- round(exp(stats::runif(n_studies, log(40), log(600))))
se <- sqrt(4 / n) # approximate SE of a standardised mean difference
true_effect <- 0.15 + shift_of(population) + shift_of(outcome) +
  shift_of(design) + shift_of(country) + stats::rnorm(n_studies, 0, 0.08)
smd <- true_effect + stats::rnorm(n_studies, 0, se)

authors <- c(
  "Adams", "Baker", "Chen", "Davies", "Evans", "Fischer", "Garcia", "Hughes",
  "Ito", "Jones", "Kumar", "Lee", "Martin", "Nguyen", "Okafor", "Patel",
  "Quinn", "Rossi", "Smith", "Taylor", "Usman", "Vargas", "Wang", "Young"
)
study <- paste(sample(authors, n_studies, replace = TRUE),
               sample(2005:2025, n_studies, replace = TRUE))
study <- make.unique(study, sep = " ")

forestmap_example <- data.frame(
  study = study,
  smd = round(smd, 3),
  vi = round(se^2, 5),
  n = as.integer(n),
  population = factor(population, levels = c("Adults", "Children", "Clinical")),
  outcome = factor(outcome, levels = c("Self-report", "Behavioural")),
  design = factor(design, levels = c("RCT", "Quasi-experimental")),
  country = factor(country, levels = c("USA", "UK", "Australia", "Germany", "Canada"))
)

save(forestmap_example, file = "data/forestmap_example.rda", compress = "bzip2")
