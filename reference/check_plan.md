# Run All Tests

Run All Tests

## Usage

``` r
check_plan(
  tests = test_db(),
  defaults = list(),
  timeout = getOption("future.tests.timeout", 30),
  envir = parent.frame(),
  local = TRUE
)
```

## Arguments

- tests:

  A list of tests to subset.

- defaults:

  (optional) Named list with default argument values.

- timeout:

  Maximum time allowed for evaluation before a timeout error is
  produced.

- envir:

  The environment where tests are run.

- local:

  Should tests be evaluated in a local environment or not.

## Value

Nothing.
