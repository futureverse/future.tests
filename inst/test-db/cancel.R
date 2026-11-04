make_test(title = "cancel()", args = list(lazy = c(FALSE, TRUE), interrupt = c(FALSE, TRUE)), tags = c("cancel", "devel"), {
  f0 <- future(NULL)
  v <- value(f0)
  print(class(f0))

  delay <- if (interrupt) 0.0 else 0.5
  f <- future({
    Sys.sleep(delay)
    42L
  }, lazy = lazy)

  cat(sprintf("state = %s\n", sQuote(f[["state"]])))
  if (lazy) {
    stopifnot(f[["state"]] %in% "created")
  } else {
    stopifnot(f[["state"]] %in% c("submitted", "running", "finished"))
  }
  
  cat(sprintf("interrupt = %s\n", sQuote(interrupt)))
  f <- cancel(f, interrupt = interrupt)
  cat(sprintf("state = %s\n", sQuote(f[["state"]])))
  stopifnot(f[["state"]] %in% c("canceled", "finished"))

  ## A canceled future may be resolved or not, which
  ## depends on future been interrupted or not
  r <- resolved(f)
  cat(sprintf("resolved = %s\n", sQuote(r)))

  v <- tryCatch({
    value(f)
  }, FutureInterruptError = identity)
  print(v)
})


make_test(title = "cancel() and value()", args = list(lazy = c(FALSE, TRUE), interrupt = c(FALSE, TRUE)), tags = c("cancel", "value", "devel"), {
  f0 <- future(NULL)
  v <- value(f0)
  print(class(f0))
  
  delay <- if (interrupt) 0.0 else 0.5
  f <- future({
    Sys.sleep(delay)
    42L
  }, lazy = lazy)

  cat(sprintf("state = %s\n", sQuote(f[["state"]])))
  if (lazy) {
    stopifnot(f[["state"]] %in% "created")
  } else {
    stopifnot(f[["state"]] %in% c("submitted", "running", "finished"))
  }
  
  cat(sprintf("interrupt = %s\n", sQuote(interrupt)))
  f <- cancel(f, interrupt = interrupt)
  cat(sprintf("state = %s\n", sQuote(f[["state"]])))
  stopifnot(f[["state"]] %in% c("canceled", "finished"))

  ## A canceled future may be resolved or not, which
  ## depends on future been interrupted or not
  r <- resolved(f)
  cat(sprintf("resolved = %s\n", sQuote(r)))

  v <- tryCatch({
    value(f)
  }, FutureInterruptError = identity)
  print(v)

  ## A canceled future is invalid, whether it was interrupted or not,
  ## the backend supports interrupts or not, the future was lazy or
  ## not, and was resolved when created or not. It is always reported
  ## as a FutureCanceledError, which inherits from FutureInterruptError,
  ## because it was actively canceled.
  stopifnot(inherits(v, "FutureCanceledError"))
})


make_test(title = "cancel() - a future that has already been collected", args = list(interrupt = c(FALSE, TRUE)), tags = c("cancel", "value", "devel"), {
  f0 <- future(NULL)
  v <- value(f0)
  print(class(f0))

  f <- future({
    Sys.sleep(0.2)
    42L
  })
  v <- value(f)
  stopifnot(v == 42L)

  f <- cancel(f, interrupt = interrupt)
  cat(sprintf("state = %s\n", sQuote(f[["state"]])))

  v <- tryCatch({
    value(f)
  }, FutureInterruptError = identity)
  print(v)

  ## A canceled future is invalid, also when it has already been resolved
  ## and collected.
  stopifnot(inherits(v, "FutureCanceledError"))
})
