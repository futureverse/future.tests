make_test(title = "FutureBackend - print() and listFutures()", tags = c("FutureBackend", "backend", "listFutures"), reset_workers = TRUE, {
  backend <- plan("backend")
  if (!inherits(backend, "FutureBackend")) {
    future.tests::skip_test("Backend does not implement the FutureBackend API")
  }

  out <- utils::capture.output(res <- print(backend))
  stopifnot(identical(res, backend), length(out) > 0L)

  data <- listFutures(backend)
  stopifnot(is.data.frame(data), nrow(data) == 0L)

  if (nbrOfFreeWorkers(background = TRUE) >= 1) {
    f <- future({ Sys.sleep(0.5); 42L })
    on.exit(tryCatch(value(f), error = identity), add = TRUE)

    data_busy <- listFutures(backend)
    stopifnot(is.data.frame(data_busy))
    if (!resolved(f)) {
      stopifnot(nrow(data_busy) >= 1L)
    }

    v <- value(f)
    stopifnot(identical(v, 42L))

    data_after <- listFutures(backend)
    stopifnot(is.data.frame(data_after), nrow(data_after) == 0L)
  }
})


make_test(title = "FutureBackend - maxSizeOfObjects rejects oversized globals", tags = c("FutureBackend", "backend", "globals", "maxSizeOfObjects"), {
  backend <- plan("backend")
  if (!inherits(backend, "FutureBackend")) {
    future.tests::skip_test("Backend does not implement the FutureBackend API")
  }

  current_plan <- plan()
  current_tweaks <- attr(current_plan, "tweaks", exact = TRUE)
  if ("maxSizeOfObjects" %in% names(current_tweaks)) {
    future.tests::skip_test("Plan already fixes 'maxSizeOfObjects'")
  }

  plan(current_plan, maxSizeOfObjects = 100)
  x <- double(1000L)
  res <- tryCatch({
    f <- future(length(x))
    value(f)
  }, error = identity)
  print(res)
  stopifnot(inherits(res, "FutureError"))
})
