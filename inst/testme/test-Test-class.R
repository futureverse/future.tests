#' @tags Test-class
#' @tags detritus-files
#' @tags detritus-connections
library(future.tests)

tests <- load_tests()
message("Number of tests: ", length(tests))

df_tests <- do.call(rbind, tests)
print(df_tests)


message("Run first three tests ...")
tests_3 <- head(tests, 3L)
## Create default values
defaults <- lapply(tests_3, FUN = function(test) test[["args"]])
defaults <- do.call(c, unname(defaults))
defaults <- lapply(defaults, FUN = function(arg) arg[[1]])
results <- run_tests(tests_3, defaults = defaults)
print(results)

df_results <- do.call(rbind, results)
print(df_results)

message("Run first three tests ... DONE")


message("Run a few tests across different future plans ...")

tests <- tests[seq(from = 1L, to = length(tests), length.out = 5L)]

library(future)

ntests <- length(tests)

add_test_plan(plan(sequential))
add_test_plan(plan(multisession, workers = 1L))
add_test_plan(plan(multisession, workers = 2L))

test_plans <- test_plans()
print(test_plans)

res <- along_test_plans({
  res_plan <- list()
  for (lazy in c(FALSE, TRUE)) {
    for (global in c(FALSE, TRUE)) {
      for (stdout in c(FALSE, TRUE)) {
        args <- c(lazy = lazy, global = global, stdout = stdout)
        args_tag <- paste(sprintf("%s=%s", names(args), args), collapse = ",")
        message(sprintf("Running tests with (%s) ...", args_tag))
    
        tests_tt <- subset_tests(tests, args = args)
        ntests_tt <- length(tests_tt)
        message(sprintf(" - Number of tests: %d out of %d", ntests_tt, ntests))
      
        res_tt <- run_tests(tests_tt)
        print(res_tt)
	stopifnot(is.list(res_tt))
    
        res_plan[[args_tag]] <- res_tt
  
        message(sprintf("Running tests with (%s) ... DONE", args_tag))
      }
    }
  }
  stopifnot(is.list(res_plan), length(res_plan) == 2*2*2)
  res_plan
})
print(res)

message("Run a few tests across different future plans ... DONE")


message("make_test() requires a title ...")
res <- tryCatch(make_test(1, register = FALSE), error = identity)
stopifnot(inherits(res, "error"))
res <- tryCatch(make_test(1, title = "", register = FALSE), error = identity)
stopifnot(inherits(res, "error"))
message("make_test() requires a title ... DONE")


message("run_tests(defaults = NULL) ...")
t <- make_test({ 42 }, title = "run_tests() with NULL defaults", register = FALSE)
res <- run_tests(list(t), defaults = NULL)
stopifnot(length(res) == 1L, identical(res[[1]]$value, 42))
message("run_tests(defaults = NULL) ... DONE")


message("run_tests() with default arguments ...")
t <- make_test({ if (lazy) "lazy" else "eager" }, title = "run_tests() without defaults",
               args = list(lazy = c(FALSE, TRUE)), register = FALSE)
## Arguments not given via 'defaults' or 'envir' default to the first
## declared value
res <- local(run_tests(list(t)), envir = new.env(parent = globalenv()))
stopifnot(length(res) == 1L, identical(res[[1]]$value, "eager"))
## Values in 'defaults' take precedence
res <- local(run_tests(list(t), defaults = list(lazy = TRUE)), envir = new.env(parent = globalenv()))
stopifnot(identical(res[[1]]$value, "lazy"))
## Values in 'envir' take precedence
res <- local({ lazy <- TRUE; run_tests(list(t)) }, envir = new.env(parent = globalenv()))
stopifnot(identical(res[[1]]$value, "lazy"))
message("run_tests() with default arguments ... DONE")


message("print() of TestResult for unsupported arguments ...")
t <- make_test({ 42 }, title = "lazy = FALSE only", args = list(lazy = FALSE), register = FALSE)
res <- run_test(t, args = list(lazy = TRUE))
out <- utils::capture.output(print(res))
stopifnot(
  any(grepl("Not run", out, fixed = TRUE)),
  any(grepl("Success: NA", out, fixed = TRUE)),
  !any(grepl("Success: TRUE", out, fixed = TRUE))
)
message("print() of TestResult for unsupported arguments ... DONE")

message("as.data.frame() of TestResult for skipped test ...")
t <- make_test({ future.tests::skip_test("skipping") }, title = "skip me", register = FALSE)
res <- run_test(t)
stopifnot(inherits(res$skipped, "TestSkipped"))
out <- utils::capture.output(print(res))
stopifnot(any(grepl("Success: NA", out, fixed = TRUE)))
df <- as.data.frame(res)
print(df)
stopifnot(is.na(df$success))
message("as.data.frame() of TestResult for skipped test ... DONE")

message("run_tests(timeout = <seconds>) ...")
t <- make_test({
  t0 <- Sys.time()
  while (difftime(Sys.time(), t0, units = "secs") < 5) NULL
}, title = "run_tests() with timeout", register = FALSE)
res <- run_tests(list(t), timeout = 0.5)
stopifnot(inherits(res[[1]]$error, "TimeoutError"))
message("run_tests(timeout = <seconds>) ... DONE")

## A missing argument must not be resolved to a function of the same name
message("run_test() - missing argument named after a function ...")
t <- make_test({ 42 }, title = "stdout argument", args = list(stdout = c(FALSE, TRUE)), register = FALSE)
res <- tryCatch(run_test(t), error = identity)
stopifnot(inherits(res, "error"), grepl("do not exist", conditionMessage(res), fixed = TRUE))
message("run_test() - missing argument named after a function ... DONE")

## Variables created by a test are removed from the evaluation environment
message("run_test(local = FALSE) - objects are undone ...")
t <- make_test({ leaked <- 42 }, title = "leaky", register = FALSE)
envir <- new.env()
assign("keep", 1, envir = envir)
res <- run_test(t, envir = envir, local = FALSE)
stopifnot(exists("keep", envir = envir, inherits = FALSE),
          !exists("leaked", envir = envir, inherits = FALSE))
message("run_test(local = FALSE) - objects are undone ... DONE")
