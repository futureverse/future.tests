## Evaluates a future with a misuse option set, and returns the
## FutureCondition signaled by value(), if any, together with the future
misuseCondition <- function(expr, option, onMisuse) {
  oopts <- options(structure(list(onMisuse), names = option))
  on.exit(options(oopts))

  f <- future(expr, substitute = FALSE)
  cond <- NULL
  res <- tryCatch({
    withCallingHandlers(value(f), warning = function(w) {
      if (inherits(w, "FutureCondition")) {
        cond <<- w
        invokeRestart("muffleWarning")
      }
    })
  }, error = identity)
  if (inherits(res, "error")) cond <- res
  print(cond)
  list(future = f, condition = cond)
}


make_test(title = "future() - RNG misuse is relayed", tags = c("future", "misuse", "rng", "devel"), bquote({
  misuseCondition <- .(misuseCondition)

  for (onMisuse in c("warning", "error")) {
    res <- misuseCondition(quote(rnorm(1L)), option = "future.rng.onMisuse", onMisuse = onMisuse)
    class <- switch(onMisuse, warning = "RngFutureWarning", error = "RngFutureError")
    stopifnot(inherits(res$condition, class))
  }
}), substitute = FALSE)


make_test(title = "future() - global environment misuse is relayed", tags = c("future", "misuse", "globalenv", "devel"), bquote({
  misuseCondition <- .(misuseCondition)

  names <- character(0L)
  on.exit({
    ## Cleanup, if evaluated in the current R session
    names <- names[vapply(names, FUN = exists, envir = globalenv(), inherits = FALSE, FUN.VALUE = NA)]
    rm(list = names, envir = globalenv(), inherits = FALSE)
  })

  for (onMisuse in c("warning", "error")) {
    ## Use a unique name, because an existing variable is not
    ## a misuse, e.g. when evaluated in the current R session
    name <- sprintf("future_tests_globalenv_misuse_%s", onMisuse)
    names <- c(names, name)
    expr <- call("assign", name, 42L, envir = quote(globalenv()))
    res <- misuseCondition(expr, option = "future.globalenv.onMisuse", onMisuse = onMisuse)
    class <- switch(onMisuse, warning = "GlobalEnvMisuseFutureWarning", error = "GlobalEnvMisuseFutureError")
    stopifnot(inherits(res$condition, class))
  }
}), substitute = FALSE)


make_test(title = "future() - connection misuse is relayed", tags = c("future", "misuse", "connections", "devel"), bquote({
  misuseCondition <- .(misuseCondition)

  pathnames <- character(0L)
  on.exit({
    ## Cleanup, if evaluated in the current R session
    conns <- showConnections(all = TRUE)
    idxs <- rownames(conns)[conns[, "description"] %in% pathnames]
    for (idx in idxs) close(getConnection(as.integer(idx)))
  })

  ## Leave a connection open
  expr <- quote({
    pathname <- tempfile(pattern = "future.tests-")
    con <- file(pathname, open = "w")
    pathname
  })
  for (onMisuse in c("warning", "error")) {
    res <- misuseCondition(expr, option = "future.connections.onMisuse", onMisuse = onMisuse)
    pathnames <- c(pathnames, result(res$future)$value)
    class <- switch(onMisuse, warning = "ConnectionMisuseFutureWarning", error = "ConnectionMisuseFutureError")
    stopifnot(inherits(res$condition, class))
  }
}), substitute = FALSE)


make_test(title = "future() - graphics device misuse is relayed", tags = c("future", "misuse", "devices", "devel"), bquote({
  misuseCondition <- .(misuseCondition)

  devs <- grDevices::dev.list()
  on.exit({
    ## Cleanup, if evaluated in the current R session
    new <- setdiff(grDevices::dev.list(), devs)
    for (dev in new) grDevices::dev.off(dev)
  })

  ## Leave a graphics device open
  expr <- quote({
    grDevices::pdf(NULL)
    NULL
  })
  for (onMisuse in c("warning", "error")) {
    res <- misuseCondition(expr, option = "future.devices.onMisuse", onMisuse = onMisuse)
    class <- switch(onMisuse, warning = "DeviceMisuseFutureWarning", error = "DeviceMisuseFutureError")
    stopifnot(inherits(res$condition, class))
  }
}), substitute = FALSE)
