#' Run All Tests
#'
#' @inheritParams run_test
#'
#' @param tests A list of tests to subset.
#'
#' @return List of test results.
#' 
#' @export
run_tests <- function(tests = test_db(), envir = parent.frame(), local = TRUE, defaults = list(), output = "stdout+stderr", timeout = getOption("future.tests.timeout", 30)) {
  if (length(defaults) > 0) stopifnot(is.list(defaults), !is.null(names(defaults)))

  if (is.null(defaults)) defaults <- list()

  res <- vector("list", length = length(tests))
  for (kk in seq_along(tests)) {
    test <- tests[[kk]]
    res[[kk]] <- run_test(test, envir = envir, local = local, defaults = defaults, output = output, timeout = timeout)
  }

  res
}
