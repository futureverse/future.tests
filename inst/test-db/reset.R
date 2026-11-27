make_test(title = "reset() - finished, failed, and canceled futures", tags = c("reset", "future"), {
  ## Finished future
  a <- 2L
  f <- future(21L * a)
  v1 <- value(f)
  stopifnot(identical(v1, 42L))
  f <- reset(f)
  stopifnot(identical(f[["state"]], "created"), isTRUE(f[["lazy"]]))
  v2 <- value(f)
  stopifnot(identical(v2, 42L))

  ## Failed future
  f <- future(stop("boom"))
  res1 <- tryCatch(value(f), error = identity)
  stopifnot(inherits(res1, "error"), conditionMessage(res1) == "boom")
  f <- reset(f)
  stopifnot(identical(f[["state"]], "created"), isTRUE(f[["lazy"]]))
  res2 <- tryCatch(value(f), error = identity)
  stopifnot(inherits(res2, "error"), conditionMessage(res2) == "boom")

  ## Canceled future
  f <- future({ Sys.sleep(0.2); 42L })
  f <- cancel(f)
  v1 <- tryCatch(value(f), FutureInterruptError = identity)
  f <- reset(f)
  stopifnot(identical(f[["state"]], "created"), isTRUE(f[["lazy"]]))
  v2 <- value(f)
  stopifnot(identical(v2, 42L))
})


make_test(title = "reset() - running future signals an error", tags = c("reset", "future", "error"), reset_workers = TRUE, {
  f0 <- future(NULL)
  v <- value(f0)
  if (inherits(f0, "UniprocessFuture")) {
    future.tests::skip_test("Test requires an asynchronous future backend")
  }

  f <- future({ Sys.sleep(1.0); 42L })
  on.exit(tryCatch(value(f), error = identity), add = TRUE)

  if (!f[["state"]] %in% c("submitted", "running")) {
    future.tests::skip_test("Future already resolved before reset() could be tested")
  }

  res <- tryCatch(reset(f), error = identity)
  print(res)
  stopifnot(inherits(res, "FutureError"))

  v <- value(f)
  stopifnot(identical(v, 42L))
})
