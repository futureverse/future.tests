# Loads Future Tests

Loads Future Tests

## Usage

``` r
load_tests(
  path = ".",
  recursive = TRUE,
  pattern = "[.]R$",
  root = getOption("future.tests.root", Sys.getenv("R_FUTURE_TESTS_ROOT",
    system.file("test-db", package = "future.tests", mustWork = TRUE)))
)
```

## Arguments

- path:

  A character string specifying a test script folder or file.

- recursive:

  If TRUE, test-definition scripts are searched recursively.

- pattern:

  Regular expression matching filenames to include.

- root:

  (internal) An alternative file directory from where future.tests tests
  are sourced.

## Value

(invisible) the value of
[`test_db()`](https://future.tests.futureverse.org/reference/test_db.md).
