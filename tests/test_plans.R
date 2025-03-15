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
