.onLoad <- future.tests:::.onLoad

message("*** .onLoad() ...")

.onLoad("future.tests", "future.tests")

Sys.setenv(R_FUTURE_TESTS_DEBUG = "TRUE")
options(future.tests.cmdargs = c("--cores=2"))
.onLoad("future.tests", "future.tests")


message("*** .onLoad() - preserves options set by user ...")

oopts <- options(
  future.tests.debug = FALSE,
  future.tests.cmdargs = character(0L),
  mc.cores = 3L
)
Sys.setenv(R_FUTURE_TESTS_DEBUG = "TRUE")
.onLoad("future.tests", "future.tests")
stopifnot(
  identical(getOption("future.tests.debug"), FALSE),
  identical(getOption("mc.cores"), 3L)
)

## Option 'future.tests.debug' is set from R_FUTURE_TESTS_DEBUG, if not set
options(future.tests.debug = NULL)
.onLoad("future.tests", "future.tests")
stopifnot(identical(getOption("future.tests.debug"), TRUE))
Sys.unsetenv("R_FUTURE_TESTS_DEBUG")
options(future.tests.debug = NULL)
.onLoad("future.tests", "future.tests")
stopifnot(identical(getOption("future.tests.debug"), FALSE))

## Option 'mc.cores' is set to at most two cores, if not set
options(mc.cores = NULL)
.onLoad("future.tests", "future.tests")
stopifnot(identical(getOption("mc.cores"), min(2L, future::availableCores())))

## Command-line option --cores=<n> overrides option 'mc.cores'
options(mc.cores = 3L, future.tests.cmdargs = c("--cores=1"))
.onLoad("future.tests", "future.tests")
stopifnot(identical(getOption("mc.cores"), 1L))

options(oopts)

message("*** .onLoad() - preserves options set by user ... DONE")

message("*** .onLoad() ... DONE")
