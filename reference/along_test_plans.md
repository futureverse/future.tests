# Evaluate an Expression Across A Set of Future Plans

Evaluate an Expression Across A Set of Future Plans

## Usage

``` r
along_test_plans(
  expr,
  substitute = TRUE,
  envir = parent.frame(),
  local = TRUE,
  plans = test_plans()
)
```

## Arguments

- expr:

  An R expression.

- substitute:

  ...

- envir:

  The environment where tests are run.

- local:

  Should tests be evaluated in a local environment or not.

- plans:

  A list of future plans.

## Value

A list of results, one for each future plan tested against. If
evaluating `expr` under a plan produces an error, then the corresponding
element is the error
[base::condition](https://rdrr.io/r/base/conditions.html), and
evaluation continues with the next plan.
