library(future.tests)
library(future)

tests <- load_tests()

test <- tests[[1]]
print(test)

## Create default values
defaults <- test[["args"]]
defaults <- lapply(defaults, FUN = function(arg) arg[[1]])

result <- run_test(test, defaults = defaults)
print(result)
