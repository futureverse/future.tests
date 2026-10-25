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
  if (lazy && packageVersion("future") < "1.68.0-9100") {
    stopifnot(f[["state"]] %in% "created")
  } else {
    stopifnot(f[["state"]] %in% c("canceled", "finished"))
  }

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
  ## Canceling lazy futures, which are never launched, requires future >= 1.80.0-9024
  new <- (packageVersion("future") >= "1.80.0-9024")
  if (lazy && !new) {
    stopifnot(f[["state"]] %in% "created")
  } else {
    stopifnot(f[["state"]] %in% c("canceled", "finished"))
  }

  ## A canceled future may be resolved or not, which
  ## depends on future been interrupted or not
  r <- resolved(f)
  cat(sprintf("resolved = %s\n", sQuote(r)))

  v <- tryCatch({
    value(f)
  }, FutureInterruptError = identity)
  print(v)

  if (!new && (lazy || inherits(f0, "BatchtoolsUniprocessFuture"))) {
    ## Older versions did not cancel lazy futures, nor futures that were
    ## resolved when created
    stopifnot(
      !inherits(v, "FutureInterruptError"),
      v == 42L
    )
  } else if (new) {
    ## A canceled future is invalid, whether it was interrupted or not,
    ## the backend supports interrupts or not, the future was lazy or
    ## not, and was resolved when created or not. It is always reported
    ## as a FutureCanceledError, which inherits from FutureInterruptError,
    ## because it was actively canceled.
    stopifnot(inherits(v, "FutureCanceledError"))
  } else if (inherits(f0, "UniprocessFuture")) {
    ## Uniprocess futures are resolved already when created, so there
    ## was nothing left to cancel
    stopifnot(
      !inherits(v, "FutureInterruptError"),
      v == 42L
    )
  } else {
    ## Did we require an interrupt and does the backend support it?
    interrupt2 <- interrupt && plan("backend")[["interrupts"]]
    if (interrupt2) {
      stopifnot(inherits(v, "FutureInterruptError"))
    } else {
      stopifnot(
        !inherits(v, "FutureInterruptError"),
        v == 42L
      )
    }
  }
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
  ## and collected. Skipped for 'future' versions without this behavior.
  if (packageVersion("future") >= "1.80.0-9024") {
    stopifnot(inherits(v, "FutureCanceledError"))
  }
})
