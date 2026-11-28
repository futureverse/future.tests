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
  max_time <- 0.5 * getOption("future.tests.timeout", 30)
  t0 <- proc.time()[["elapsed"]]
  ws <- character(0L)
  withCallingHandlers({
    for (kk in 1:30) {
      f <- future(kk)
      v <- value(f)
      stopifnot(identical(v, kk))
      if (kk >= 5L && (proc.time()[["elapsed"]] - t0) >= max_time) break
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
  f0 <- future(NULL)
  v <- value(f0)

  if (inherits(f0, "BatchtoolsFuture") && packageVersion("future.batchtools") < "0.30.0-9001") {
    future.tests::skip_test("Test requires future.batchtools (>= 0.30.0-9001)")
  }
  
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
  if (getRversion() < "4.4") {
    future.tests::skip_test("Test requires R (>= 4.4.0)")
  }
  if (packageVersion("future") < "1.82.0") {
    future.tests::skip_test("Test requires future (>= 1.82.0)")
  }
  if (!is.finite(nbrOfWorkers())) {
    future.tests::skip_test("Test requires a finite number of workers")
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
  if (getRversion() < "4.4") {
    future.tests::skip_test("Test requires R (>= 4.4.0)")
  }
  if (!is.finite(nbrOfWorkers())) {
    future.tests::skip_test("Test requires a finite number of workers")
  }

  cl <- makeClusterFuture(nbrOfWorkers())
  on.exit(parallel::stopCluster(cl))

  res <- tryCatch(parallel::clusterEvalQ(cl, library(stats)), error = identity)
  stopifnot(!inherits(res, "error"))
  res <- tryCatch(parallel::clusterEvalQ(cl, { library(stats); library(utils) }), error = identity)
  stopifnot(!inherits(res, "error"))
})


make_test(title = "future() - a worker that terminates signals a FutureError and the backend remains usable", tags = c("future", "worker", "crash", "devel"), reset_workers = TRUE, {
  ## Never terminate the current R session
  f <- future(list(pid = Sys.getpid(), host = Sys.info()[["nodename"]]))
  worker_uuid <- result(f)[["session_uuid"]]
  if (!is.null(worker_uuid)) {
    same_session <- identical(as.vector(worker_uuid), as.vector(future:::session_uuid()))
  } else {
    info <- value(f)
    same_session <- identical(info$pid, Sys.getpid()) &&
                    identical(info$host, Sys.info()[["nodename"]])
  }
  if (same_session) {
    future.tests::skip_test("Test requires futures to be evaluated in a separate R process")
  }

  ## A future whose worker terminates abruptly
  f <- NULL
  v <- tryCatch({
    f <- future({ tools::pskill(Sys.getpid(), signal = tools::SIGKILL); 42L })
    value(f)
  }, error = identity)
  print(v)
  stopifnot(inherits(v, "FutureError"))

  ## Querying the future again must not hang or give an obscure error
  if (!is.null(f)) {
    r <- tryCatch(resolved(f), error = identity)
    stopifnot(is.logical(r) || inherits(r, "FutureError"))
  }

  ## The backend must remain usable, also for the worker slot that
  ## was used by the terminated worker
  n <- nbrOfWorkers()
  n <- if (is.finite(n)) min(n, 4L) else 2L
  fs <- lapply(seq_len(n), FUN = function(kk) future(kk))
  vs <- value(fs)
  stopifnot(identical(vs, as.list(seq_len(n))))
})


make_test(title = "future() - changes to existing options, environment variables, and working directory do not leak to the next future on the same worker", tags = c("future", "worker", "options", "envvars", "workdir", "devel"), reset_workers = TRUE, {
  uuid_of <- function(f) {
    uuid <- result(f)[["session_uuid"]]
    if (is.null(uuid)) return(NULL)
    as.vector(uuid)
  }

  ## A future that changes existing R options, environment variables,
  ## and the working directory of the worker. Note that the Future API
  ## only restores R options and environment variables that existed
  ## before the future was evaluated; added ones are left as-is on
  ## purpose, because packages loaded may rely on them
  f <- future({
    before <- list(
      option = getOption("digits"),
      envvar = Sys.getenv("R_HOME", NA_character_),
      workdir = getwd()
    )
    options(digits = if (getOption("digits") == 3L) 4L else 3L)
    Sys.setenv(R_HOME = file.path(Sys.getenv("R_HOME"), "future.tests"))
    setwd(tempdir())
    before
  })
  before <- value(f)
  worker <- uuid_of(f)
  if (is.null(worker)) {
    future.tests::skip_test("Future results do not identify the worker session")
  }
  if (identical(worker, as.vector(future:::session_uuid()))) {
    future.tests::skip_test("Test requires futures to be evaluated in a separate R process")
  }

  ## Evaluate futures, one at a time, until one runs on the same worker
  n <- nbrOfWorkers()
  n <- if (is.finite(n)) min(2L * n, 10L) else 2L
  after <- NULL
  for (kk in seq_len(n)) {
    f <- future(list(
      option = getOption("digits"),
      envvar = Sys.getenv("R_HOME", NA_character_),
      workdir = getwd()
    ))
    value <- value(f)
    if (identical(uuid_of(f), worker)) {
      after <- value
      break
    }
  }
  if (is.null(after)) {
    future.tests::skip_test(sprintf("Backend did not reuse the worker within %d futures", n))
  }

  str(list(before = before, after = after))
  stopifnot(
    identical(after$option, before$option),
    identical(after$envvar, before$envvar),
    identical(after$workdir, before$workdir)
  )
})
