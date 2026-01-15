# Run a Test

Run a Test

## Usage

``` r
run_test(
  test,
  envir = parent.frame(),
  local = TRUE,
  args = list(),
  defaults = list(),
  output = "stdout+stderr",
  timeout = getOption("future.tests.timeout", 30)
)
```

## Arguments

- test:

  A Test.

- envir:

  The environment where tests are run.

- local:

  Should tests be evaluated in a local environment or not.

- args:

  Arguments used in this test.

- defaults:

  (optional) Named list with default argument values.

- output:

  If TRUE, standard output is captured, otherwise not.

- timeout:

  Maximum time allowed for evaluation before a timeout error is
  produced.

## Value

Value of test expression and benchmark information.
