#' @tags check_plan

library(future.tests)

message("*** check_plan() ...")

## check_plan() works also when the call of the current plan is
## deparsed into multiple strings
oplan <- future::plan(future::sequential, label = c(
  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
))
stopifnot(length(deparse(attr(future::plan("next"), "call"))) > 1L)
out <- utils::capture.output({
  results <- check_plan(
    list(make_test({ 42L }, title = "long plan call", register = FALSE))
  )
})
print(out)
stopifnot(
  length(results) == 1L,
  any(grepl("Number of test steps: 1", out, fixed = TRUE)),
  any(grepl("Running 1 test sets with future::plan(future::sequential, label = c(", out, fixed = TRUE))
)
future::plan(oplan)

message("*** check_plan() ... DONE")
