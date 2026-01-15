# Run All Tests

Run All Tests

## Usage

``` r
run_tests(
  tests = test_db(),
  envir = parent.frame(),
  local = TRUE,
  defaults = list(),
  output = "stdout+stderr"
)
```

## Arguments

- tests:

  A list of tests to subset.

- envir:

  The environment where tests are run.

- local:

  Should tests be evaluated in a local environment or not.

- defaults:

  (optional) Named list with default argument values.

- output:

  If TRUE, standard output is captured, otherwise not.

## Value

List of test results.
