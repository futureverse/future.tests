#' Run All Tests
#'
#' @inheritParams run_test
#'
#' @param tests A list of tests to subset.
#'
#' @return List of test results.
#'
#' @details
#' Test arguments, declared by `args` of [make_test()], that are neither
#' specified via `defaults` nor exist in `envir`, are set to the first of
#' the values declared by the test.
#
#' @export
run_tests <- function(tests = test_db(), envir = parent.frame(), local = TRUE, defaults = list(), output = "stdout+stderr", timeout = getOption("future.tests.timeout", 30)) {
  if (length(defaults) > 0) stopifnot(is.list(defaults), !is.null(names(defaults)))

  if (is.null(defaults)) defaults <- list()

  res <- vector("list", length = length(tests))
  for (kk in seq_along(tests)) {
    test <- tests[[kk]]

    ## Use the first declared value for test arguments that are neither
    ## among the defaults nor exist in 'envir'
    test_defaults <- defaults
    for (name in setdiff(names(test$args), names(defaults))) {
      if (exists(name, envir = envir, inherits = TRUE) &&
          !is.function(get(name, envir = envir, inherits = TRUE))) next
      test_defaults[[name]] <- test$args[[name]][[1]]
    }
    
    res[[kk]] <- run_test(test, envir = envir, local = local, defaults = test_defaults, output = output, timeout = timeout)
  }

  res
}
