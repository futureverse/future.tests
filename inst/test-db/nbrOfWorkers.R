make_test(title = "nbrOfWorkers()", tags = c("nbrOfWorkers"), {
  n <- nbrOfWorkers()
  message(sprintf("nbrOfWorkers: %g", n))
  stopifnot(is.numeric(n), length(n) == 1L, n >= 1L)
})


make_test(title = "nbrOfFreeWorkers()", tags = c("nbrOfWorkers", "nbrOfFreeWorkers"), reset_workers = TRUE, {
  f0 <- future(NULL)
  v <- value(f0)

  n <- nbrOfWorkers()
  nf <- nbrOfFreeWorkers()
  nf_bg <- nbrOfFreeWorkers(background = TRUE)
  message(sprintf("nbrOfWorkers: %g, nbrOfFreeWorkers: %g, background: %g", n, nf, nf_bg))
  stopifnot(
    is.numeric(nf), length(nf) == 1L, !is.na(nf), nf >= 0, nf == n,
    is.numeric(nf_bg), length(nf_bg) == 1L, !is.na(nf_bg), nf_bg >= 0, nf_bg <= nf
  )

  if (inherits(f0, "UniprocessFuture")) {
    stopifnot(nf_bg == 0)
  } else if (is.finite(n) && nf_bg >= 1) {
    f <- future({ Sys.sleep(0.5); 42L })
    nf_busy <- nbrOfFreeWorkers()
    message(sprintf("nbrOfFreeWorkers (while running): %g", nf_busy))
    stopifnot(is.numeric(nf_busy), length(nf_busy) == 1L, !is.na(nf_busy), nf_busy >= 0, nf_busy <= n)
    if (!resolved(f)) {
      stopifnot(nf_busy <= n - 1)
    }
    v <- value(f)
    stopifnot(identical(v, 42L))
    nf_after <- nbrOfFreeWorkers()
    message(sprintf("nbrOfFreeWorkers (after value): %g", nf_after))
    stopifnot(nf_after == n)
  }
})
