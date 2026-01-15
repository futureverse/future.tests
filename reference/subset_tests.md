# Identify Subset of Tests with Specified Tags and that Support Specified Argument Settings

Identify Subset of Tests with Specified Tags and that Support Specified
Argument Settings

## Usage

``` r
subset_tests(tests = test_db(), tags = NULL, args = NULL, defaults = list())
```

## Arguments

- tests:

  A list of tests to subset.

- tags:

  (optional) A character vector of tags that tests must have.

- args:

  Named arguments with sets of values to test against.

- defaults:

  (optional) Named list with default argument values.

## Value

A list of tests that support specified arguments.
