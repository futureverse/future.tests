## https://github.com/HenrikBengtsson/future.tests/issues/14
make_test(title = "future() - non-exported package objects", tags = c("future", "globals"), {
  if (requireNamespace("utils") && require("utils")) {
    ## Find a non-exported 'utils' function
    env <- pos.to.env(match("package:utils", search()))
    ns <- getNamespace("utils")
    privates <- setdiff(names(ns), names(env))
    non_exported <- NULL
    for (name in privates) {
      if (exists(name, envir = ns, mode = "function", inherits = FALSE)) {
        non_exported <- get(name, envir = ns, mode = "function", inherits = FALSE)
      }
    }
    stopifnot(is.function(non_exported))

    ## Use this non-exported function in a future
    f <- future({ non_exported }, lazy = TRUE)

    ## Assert that it is identified as a global
    stopifnot(
      "non_exported" %in% names(f$globals),
      identical(f$globals[["non_exported"]], non_exported)
    )
    v <- value(f)
    stopifnot(identical(v, non_exported))
  }
})



## https://github.com/HenrikBengtsson/future.tests/issues/15
make_test(title = "future() - NSE '...'", tags = c("future", "globals", "..."), {
  my_fcn <- function(...) {
    ## Grab '...' into a Globals object
    globals <- globals::globalsByName("...", envir=environment())

    ## Evaluate an expression with '...' in an environment that does not
    ## have an '...' object - hence the parent.frame().  This will produce
    ## an error unless we pass 'globals' which contains '...'
    
    f <- future({
      fcn <- function() sum(...)
      fcn()
    }, envir = parent.frame(), globals = globals)
    v <- value(f)
    v
  }

  y <- my_fcn()
  stopifnot(y == 0L)  ## sum(c()) is integer, but not sure it's guaranteed

  y <- my_fcn(1:10)
  stopifnot(identical(y, 55L))
})


make_test(title = "future() - globals specified as character vector with attributes 'add' and 'ignore'", tags = c("future", "globals"), {
  if (packageVersion("future") < "1.80.0") {
    future.tests::skip_test("Test requires future (>= 1.80.0)")
  }

  a <- 1
  b <- 2
  c <- 3

  ## Attribute 'add'
  globals <- structure(c("a", "b"), add = "c")
  f <- future({ a + b + c }, globals = globals, lazy = TRUE)
  stopifnot(all(c("a", "b", "c") %in% names(f$globals)))
  v <- value(f)
  stopifnot(identical(v, 6))

  ## Attribute 'ignore'
  globals <- structure(c("a", "b"), ignore = "b")
  f <- future({ a }, globals = globals, lazy = TRUE)
  stopifnot("a" %in% names(f$globals), !"b" %in% names(f$globals))
  v <- value(f)
  stopifnot(identical(v, 1))
})


make_test(title = "future() - unused variables are not exported as globals", tags = c("future", "globals"), {
  unused <- rnorm(1e4)
  used <- 42L
  f <- future({ used }, lazy = TRUE)
  stopifnot("used" %in% names(f$globals), !"unused" %in% names(f$globals))
  v <- value(f)
  stopifnot(identical(v, 42L))
})


## The pattern used by future.apply
make_test(title = "future() - global '...' together with global '...future.FUN'", tags = c("future", "globals", "..."), {
  if (packageVersion("future") < "1.80.0") {
    future.tests::skip_test("Test requires future (>= 1.80.0)")
  }

  FUN <- function(x, y = 0) x + y
  env_FUN <- environment(FUN)
  parent_FUN <- parent.env(env_FUN)

  my_fcn <- function(...) {
    ...future.FUN <- FUN
    f <- future({ ...future.FUN(1, ...) })
    value(f)
  }

  for (kk in 1:2) {
    v <- my_fcn()
    stopifnot(identical(v, 1))
    v <- my_fcn(y = 2)
    stopifnot(identical(v, 3))
  }

  ## The function's environment must not have been modified
  stopifnot(
    identical(environment(FUN), env_FUN),
    identical(parent.env(env_FUN), parent_FUN)
  )
})
