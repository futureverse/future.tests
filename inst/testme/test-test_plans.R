library(future.tests)
library(future)

test_plans <- test_plans()
print(test_plans)

add_test_plan(plan(sequential))
add_test_plan(plan(multisession, workers = 1L))
add_test_plan(plan(multisession, workers = 2L))

test_plans <- test_plans()
print(test_plans)
stopifnot(length(test_plans) == 3L)

res <- along_test_plans({ 42L })
print(res)


message("along_test_plans() with errors and NULL values ...")
plans <- list(quote(plan(sequential)), quote(plan(sequential)))
res <- suppressMessages(along_test_plans(stop("boom"), plans = plans))
stopifnot(length(res) == 2L, all(vapply(res, FUN = inherits, what = "error", logical(1L))))
res <- suppressMessages(along_test_plans(NULL, plans = plans))
stopifnot(length(res) == 2L, all(vapply(res, FUN = is.null, logical(1L))))
message("along_test_plans() with errors and NULL values ... DONE")
