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
