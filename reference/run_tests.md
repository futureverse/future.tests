# Run All Tests

Run All Tests

## Usage

``` r
run_tests(
  tests = test_db(),
  envir = parent.frame(),
  local = TRUE,
  defaults = list(),
  output = "stdout+stderr",
  timeout = getOption("future.tests.timeout", 30)
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

- timeout:

  Maximum time allowed for evaluation before a timeout error is
  produced.

## Value

List of test results.

## Details

Test arguments, declared by `args` of
[`make_test()`](https://future.tests.futureverse.org/reference/make_test.md),
that are neither specified via `defaults` nor exist in `envir`, are set
to the first of the values declared by the test.
