#' @tags check
#' @tags detritus-files
#' @tags detritus-connections

check <- future.tests::check

message("*** check() ...")

## Validate options
check()
check(.args = c("--debug", "--help"))

## Run checks with plan(sequential)
results <- check(plan = "sequential", session_info = TRUE, debug = TRUE)
print(results)

## Run checks with plan(sequential) from CLI
results <- check(.args = c("--debug", "--test-timeout=30", "--test-tags=resolve,rng", "--test-plan=sequential"))
print(results)

## Flags --session-info and --debug are respected
out <- utils::capture.output({
  results <- check(.args = c("--session-info", "--debug", "--test-tags=resolve", "--test-plan=sequential"), exit_value = FALSE)
})
stopifnot(
  any(grepl("Session info", out, fixed = TRUE)),
  any(grepl("Total number of errors:", out, fixed = TRUE))
)

## Option 'future.tests.timeout' is not left modified
old <- options(future.tests.timeout = NULL)
utils::capture.output({
  results <- check(plan = "sequential", tags = "resolve", timeout = 60, exit_value = FALSE)
})
stopifnot(is.null(getOption("future.tests.timeout")))
options(old)

## check_plan() runs tests without arguments also when there are no defaults
out <- utils::capture.output({
  results <- future.tests::check_plan(
    list(make_test({ cat("RAN\n") }, title = "no args", register = FALSE)),
    defaults = list()
  )
})
stopifnot(
  any(grepl("Number of test steps: 1", out, fixed = TRUE)),
  grepl("RAN", results[[1]][[1]]$output, fixed = TRUE)
)

## A plan whose name contains 'plan' is still wrapped in plan()
res <- tryCatch(
  utils::capture.output(check(plan = "planned::foo", exit_value = FALSE)),
  error = identity
)
expr <- future.tests::test_plans()[[1]][[1]]
stopifnot(is.call(expr), identical(expr[[1]], quote(plan)))

## A plan specified as a statement(s) calling plan() is used as-is
utils::capture.output({
  results <- check(plan = "invisible(1); plan(sequential)", tags = "resolve", exit_value = FALSE)
})
stopifnot(length(results) == 1L)

message("*** check() ... DONE")
