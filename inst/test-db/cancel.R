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
  if (lazy) {
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

  ## Did we require an interrupt and does the backend support it?
  interrupt2 <- interrupt && plan("backend")[["interrupts"]]
  if (interrupt2) {
    if (lazy || inherits(f0, c("UniprocessFuture", "BatchtoolsUniprocessFuture"))) {
      stopifnot(
        !inherits(v, "FutureInterruptError"),
        v == 42L
      )
    } else {
      stopifnot(inherits(v, "FutureInterruptError"))
    }
  } else {
    if (lazy) {
      stopifnot(!inherits(v, "FutureInterruptError"))
    } else {
      stopifnot(
        !inherits(v, "FutureInterruptError"),
        v == 42L
      )
    }
  }
})
