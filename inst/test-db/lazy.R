make_test(title = "future() - global variables with and without lazy evaluation", args = list(lazy = c(FALSE, TRUE)), tags = c("future", "lazy"), {
  ## Explicit lazy evaluation
  a <- 1
  f <- future({ 2 + a }, lazy = lazy)
  a <- 2
  v <- value(f)
  stopifnot(v == 3)
})


make_test(title = "resolved() on lazy futures", tags = c("resolved", "lazy"), {
  f <- future(42, lazy = TRUE)
  while (!resolved(f)) {
    Sys.sleep(0.1)
  }
  v <- value(f)
  stopifnot(identical(v, 42))
})

