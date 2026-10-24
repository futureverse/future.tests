library(future.tests)

tests <- load_tests()
message("Number of tests: ", length(tests))

df_tests <- do.call(rbind, tests)
print(df_tests)

tests_a <- subset_tests(tests, tags = "stdout")
df_tests <- do.call(rbind, tests_a)
print(df_tests)

tests_b <- subset_tests(tests, tags = "stdout", args = list(stdout = TRUE))
df_tests <- do.call(rbind, tests_b)
print(df_tests)

tests_c <- subset_tests(tests, args = list(stdout = TRUE))
df_tests <- do.call(rbind, tests_c)
print(df_tests)


message("subset_tests(args, defaults) ...")
t_lazy <- make_test(1, title = "lazy = FALSE only", args = list(lazy = FALSE), register = FALSE)
t_none <- make_test(1, title = "no args", register = FALSE)
defaults <- list(lazy = FALSE, globals = TRUE)
## The test's own arguments are respected also with defaults
stopifnot(length(subset_tests(list(t_lazy), args = list(lazy = TRUE), defaults = defaults)) == 0L)
stopifnot(length(subset_tests(list(t_lazy), args = list(lazy = FALSE), defaults = defaults)) == 1L)
## Tests without the argument fall back to the default value
stopifnot(length(subset_tests(list(t_none), args = list(lazy = TRUE), defaults = defaults)) == 0L)
stopifnot(length(subset_tests(list(t_none), args = list(lazy = FALSE), defaults = defaults)) == 1L)
message("subset_tests(args, defaults) ... DONE")
