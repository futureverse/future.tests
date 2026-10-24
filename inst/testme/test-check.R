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

message("*** check() ... DONE")
