make_test(title = "future(..., packages = 'missing-package') - signals an error", tags = c("future", "packages", "error"), {
  res <- tryCatch({
    f <- future(42L, packages = "missing-package")
    value(f)
  }, error = identity)
  print(res)
  stopifnot(inherits(res, "error"))
})


make_test(title = "future(..., packages = 'missing-package') - backend remains usable afterward", tags = c("future", "packages", "error", "reset", "recovery", "devel"), reset_workers = TRUE, {
  f0 <- future(NULL)
  v <- value(f0)
  if (inherits(f0, "MulticoreFuture") && packageVersion("future") <= "1.82.0") {
    future.tests::skip_test("Test requires future (> 1.82.0) for MulticoreFuture")
  }
  if (inherits(f0, "CallrFuture") && packageVersion("future.callr") <= "1.0.2") {
    future.tests::skip_test("Test requires future.callr (> 1.0.2)")
  }
  if (inherits(f0, "BatchtoolsFuture") && packageVersion("future.batchtools") <= "0.32.0") {
    future.tests::skip_test("Test requires future.batchtools (> 0.32.0)")
  }

  n0 <- nbrOfFreeWorkers()

  f <- NULL
  res <- tryCatch({
    f <- future(42L, packages = "missing-package")
    value(f)
  }, error = identity)
  print(res)
  stopifnot(inherits(res, "error"))

  if (!is.null(f)) {
    stopifnot(!f[["state"]] %in% c("submitted", "running"))

    ## Repeated value() still signals an error cleanly
    res2 <- tryCatch(value(f), error = identity)
    stopifnot(inherits(res2, "error"))

    ## Failed future can be reset
    f_reset <- reset(f)
    stopifnot(identical(f_reset[["state"]], "created"))
  }

  ## Worker slot is freed and subsequent futures succeed
  stopifnot(nbrOfFreeWorkers() == n0)
  f2 <- future(1L)
  stopifnot(identical(value(f2), 1L))
  stopifnot(nbrOfFreeWorkers() == n0)
})


make_test(title = "value(<listenv>, idxs)", tags = c("value", "listenv"), {
  x <- listenv::listenv()
  for (kk in 1:3) x[[kk]] <- future(kk * 10L)

  v <- value(x, idxs = 2)
  stopifnot(identical(unlist(v, use.names = FALSE), 20L))

  v <- value(x, idxs = c(1, 3))
  stopifnot(identical(unlist(v, use.names = FALSE), c(10L, 30L)))
})


make_test(title = "value(<list>, reduce = structure('+', init = 42))", tags = c("value", "reduce"), {
  fs <- lapply(1:3, function(kk) future(kk))
  v <- value(fs, reduce = structure("+", init = 42))
  stopifnot(identical(as.numeric(v), 48))
})


make_test(title = "result() - on a canceled and interrupted future", tags = c("future", "cancel", "result", "devel"), {
  f <- future({ Sys.sleep(3); 42L })
  f <- cancel(f, interrupt = TRUE)
  r <- tryCatch(result(f), error = identity)
  print(class(r))

  ## Either the future finished or an interrupt error is signaled;
  ## never the future object itself
  stopifnot(inherits(r, "FutureResult") || inherits(r, "FutureInterruptError"))
})


make_test(title = "makeClusterFuture() - errors are signaled as by other clusters", tags = c("future", "makeClusterFuture", "error", "devel"), {
  if (getRversion() < "4.4") {
    future.tests::skip_test("Test requires R (>= 4.4.0)")
  }
  if (!is.finite(nbrOfWorkers())) {
    future.tests::skip_test("Test requires a finite number of workers")
  }

  cl <- makeClusterFuture(nbrOfWorkers())
  on.exit(parallel::stopCluster(cl))

  res <- tryCatch(parallel::parLapply(cl, 1:2, function(i) stop("boom")), error = identity)
  print(res)
  stopifnot(inherits(res, "error"), grepl("boom", conditionMessage(res)))

  ## The cluster is still usable
  res <- parallel::parLapply(cl, 1:2, function(i) i)
  stopifnot(identical(res, list(1L, 2L)))
})
