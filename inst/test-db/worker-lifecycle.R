make_test(title = "future() - switching plan while a future is running", tags = c("future", "plan", "devel"), {
  current_plan <- plan()
  on.exit(plan(current_plan))

  f <- future({ Sys.sleep(1); 42L })
  plan(sequential)

  ## Either the value is still available or an informative FutureError
  ## is signaled; never an obscure error
  r <- tryCatch(resolved(f), error = identity)
  stopifnot(is.logical(r) || inherits(r, "FutureError"))
  v <- tryCatch(value(f), error = identity)
  stopifnot(identical(v, 42L) || inherits(v, "FutureError"))
})


make_test(title = "value() - repeated on a canceled and interrupted future", tags = c("future", "cancel", "value", "devel"), {
  f <- future({ Sys.sleep(3); 42L })
  f <- cancel(f, interrupt = TRUE)

  v1 <- tryCatch(value(f), error = identity)
  v2 <- tryCatch(value(f), error = identity)
  v3 <- tryCatch(value(f), error = identity)
  print(v1)
  stopifnot(identical(class(v1), class(v2)), identical(class(v1), class(v3)))

  ## Querying 'resolved' afterward must not fail
  stopifnot(is.logical(resolved(f)))
})


make_test(title = "future() - launching many futures leaves no unused connections", tags = c("future", "connections", "devel"), {
  conns_before <- nrow(showConnections(all = TRUE))
  ws <- character(0L)
  withCallingHandlers({
    for (kk in 1:30) {
      f <- future(kk)
      v <- value(f)
      stopifnot(identical(v, kk))
    }
    rm(list = c("f", "v"))
    gc()
  }, warning = function(w) {
    ws <<- c(ws, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  stopifnot(!any(grepl("closing unused connection", ws)))
  conns_after <- nrow(showConnections(all = TRUE))
  stopifnot(conns_after - conns_before <= 5L)
})


make_test(title = "resolved() and value() - immediate conditions are not re-signaled", tags = c("future", "conditions", "immediateCondition", "devel"), {
  cond <- structure(
    class = c("myImmediateCondition", "immediateCondition", "condition"),
    list(message = "hello", call = NULL)
  )

  count <- 0L
  f <- withCallingHandlers({
    future({ signalCondition(cond); Sys.sleep(0.5); 42L })
  }, myImmediateCondition = function(c) count <<- count + 1L)

  withCallingHandlers({
    while (!resolved(f)) Sys.sleep(0.1)
    v <- value(f)
  }, myImmediateCondition = function(c) count <<- count + 1L)
  stopifnot(identical(v, 42L), count >= 1L)

  ## Querying again must not re-signal
  count_before <- count
  withCallingHandlers({
    r <- resolved(f)
    v <- value(f)
  }, myImmediateCondition = function(c) count <<- count + 1L)
  stopifnot(count == count_before)
})


make_test(title = "makeClusterFuture() - language objects are passed as-is", tags = c("future", "makeClusterFuture", "devel"), {
  if (packageVersion("future") < "1.80.0-9016") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9016)")
  }

  cl <- makeClusterFuture(nbrOfWorkers())
  on.exit(parallel::stopCluster(cl))

  objs <- list(quote(a), quote(a + b), y ~ x)
  res <- parallel::parLapply(cl, objs, class)
  stopifnot(identical(res, lapply(objs, class)))

  res <- parallel::clusterCall(cl, function(x) class(x), quote(a + b))
  stopifnot(all(vapply(res, identical, NA, "call")))
})


make_test(title = "makeClusterFuture() - clusterEvalQ() that only attaches packages", tags = c("future", "makeClusterFuture", "devel"), {
  if (packageVersion("future") < "1.76.0") {
    future.tests::skip_test("Test requires future (>= 1.76.0)")
  }

  cl <- makeClusterFuture(nbrOfWorkers())
  on.exit(parallel::stopCluster(cl))

  res <- tryCatch(parallel::clusterEvalQ(cl, library(stats)), error = identity)
  stopifnot(!inherits(res, "error"))
  res <- tryCatch(parallel::clusterEvalQ(cl, { library(stats); library(utils) }), error = identity)
  stopifnot(!inherits(res, "error"))
})
