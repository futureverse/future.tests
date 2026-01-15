# Evaluate an R Expression

Evaluate an R Expression

## Usage

``` r
evaluate_expr(
  expr,
  envir = parent.frame(),
  local = TRUE,
  output = c("stdout+stderr", "stdout", "none"),
  timeout = +Inf
)
```

## Arguments

- expr:

  An expression

- envir:

  The environment where tests are run.

- local:

  Should tests be evaluated in a local environment or not.

- output:

  Specifies whether standard output, standard error, or both should be
  captured or not.

- timeout:

  Maximum time allowed for evaluation before a timeout error is
  produced.

## Value

Value of test expression and benchmark information.
