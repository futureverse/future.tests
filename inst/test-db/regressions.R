make_test(title = "future(..., packages = 'missing-package') - signals an error", tags = c("future", "packages", "error"), {
  if (packageVersion("future") < "1.69.0") {
    future.tests::skip_test("Test requires future (>= 1.69.0)")
  }

  res <- tryCatch({
    f <- future(42L, packages = "missing-package")
    value(f)
  }, error = identity)
  print(res)
  stopifnot(inherits(res, "error"))
})


make_test(title = "value(<listenv>, idxs)", tags = c("value", "listenv"), {
  if (packageVersion("future") < "1.75.0") {
    future.tests::skip_test("Test requires future (>= 1.75.0)")
  }

  x <- listenv::listenv()
  for (kk in 1:3) x[[kk]] <- future(kk * 10L)

  v <- value(x, idxs = 2)
  stopifnot(identical(unlist(v, use.names = FALSE), 20L))

  v <- value(x, idxs = c(1, 3))
  stopifnot(identical(unlist(v, use.names = FALSE), c(10L, 30L)))
})


make_test(title = "value(<list>, reduce = structure('+', init = 42))", tags = c("value", "reduce"), {
  if (packageVersion("future") < "1.68.0") {
    future.tests::skip_test("Test requires future (>= 1.68.0)")
  }

  fs <- lapply(1:3, function(kk) future(kk))
  v <- value(fs, reduce = structure("+", init = 42))
  stopifnot(identical(as.numeric(v), 48))
})


make_test(title = "result() - on a canceled and interrupted future", tags = c("future", "cancel", "result", "devel"), {
  if (packageVersion("future") < "1.68.0") {
    future.tests::skip_test("Test requires future (>= 1.68.0)")
  }

  f <- future({ Sys.sleep(3); 42L })
  f <- cancel(f, interrupt = TRUE)
  r <- tryCatch(result(f), error = identity)
  print(class(r))

  ## Either the future finished or an interrupt error is signaled;
  ## never the future object itself
  stopifnot(inherits(r, "FutureResult") || inherits(r, "FutureInterruptError"))
})


make_test(title = "makeClusterFuture() - errors are signaled as by other clusters", tags = c("future", "makeClusterFuture", "error", "devel"), {
  if (packageVersion("future") < "1.69.0") {
    future.tests::skip_test("Test requires future (>= 1.69.0)")
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
