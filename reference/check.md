# Run All or a Subset of the Tests Across Future Plans

Run All or a Subset of the Tests Across Future Plans

## Usage

``` r
check(
  plan = NULL,
  tags = character(),
  timeout = NULL,
  settings = TRUE,
  session_info = FALSE,
  envir = parent.frame(),
  local = TRUE,
  debug = FALSE,
  exit_value = !interactive(),
  .args = commandArgs()
)
```

## Arguments

- plan:

  (character vector) One or more future strategy plans to be validated.

- tags:

  (character vector; optional) Filter tests by tags. If NULL, all tests
  are performed.

- timeout:

  (numeric; optional) Maximum time (in seconds) each test may run before
  a timeout error is produced.

- settings:

  (logical) If TRUE, details on the settings are outputted before the
  tests start.

- session_info:

  (logical) If TRUE, session information is outputted after the tests
  complete.

- envir:

  The environment where tests are run.

- local:

  Should tests be evaluated in a local environment or not.

- debug:

  (logical) If TRUE, the raw test results are printed.

- exit_value:

  (logical) If TRUE, and in a non-interactive session, then use
  [`base::quit()`](https://rdrr.io/r/base/quit.html) to quit R with an
  exit code of 0 (zero) if all tests passed with all OKs and otherwise 1
  (one) if one or more tests failed.

- .args:

  (character vector; optional) Command-line arguments.

## Value

(list; invisible) A list of test results.

## Command-line interface (CLI)

This function can be called from the shell. To specify an argument, use
the format `--test-<arg_name>=<value>`. For example,
`--test-timeout=600` will set argument `timeout=600`, and
`--tags=lazy,rng`, or equivalently, `--tags=lazy --tags=rng` will set
argument `tags=c("lazy", "rng")`.

Here are some examples on how to call this function from the command
line:

    Rscript -e future.tests::check --args --test-plan=sequential
    Rscript -e future.tests::check --args --test-plan=multicore,workers=2
    Rscript -e future.tests::check --args --test-plan=sequential --test-plan=multicore,workers=2
    Rscript -e future.tests::check --args --test-plan=future.callr::callr
    Rscript -e future.tests::check --args --test-plan=future.batchtools::batchtools_local

The exit code will be 0 if all tests passed, otherwise 1. You can use
for instance `exit_code=$?` to retrieve the exit code of the most recent
call.

## Examples

``` r
if (FALSE) { # \dontrun{
results <- future.tests::check(plan = "sequential", tags = c("rng"))
exit_code <- attr(results, "exit_code")
if (exit_code != 0) stop("One or more tests failed")
} # }
```
