## Tests on value() for lists of futures. Several of these assert behavior
## that was fixed in the 'future' package, which is why they are skipped
## when testing against an older version of 'future'.

make_test(title = "value(<list>) - reduce with 'init' attribute", args = list(inorder = c(TRUE, FALSE)), tags = c("value", "reduce"), {
  ## 'init' was ignored for inorder = FALSE (fixed in future 1.80.0-9004)
  if (!inorder && packageVersion("future") < "1.80.0-9004") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9004)")
  }

  fs <- list(
    future(1),
    future({ Sys.sleep(0.5); 2 }),
    future(3)
  )
  reduce <- structure(function(x, y) x + y, init = 100)
  v <- value(fs, reduce = reduce, inorder = inorder)
  stopifnot(identical(v, 106))
})


make_test(title = "value(<list>) - arguments 'stdout' and 'signal'", args = list(inorder = c(TRUE, FALSE)), tags = c("value", "stdout", "conditions"), {
  ## 'stdout' and 'signal' were ignored for inorder = FALSE (fixed in
  ## future 1.80.0-9005)
  if (!inorder && packageVersion("future") < "1.80.0-9005") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9005)")
  }

  ## stdout = FALSE: Standard output is not relayed
  ## (for inorder = TRUE, this failed with "Cannot resignal future
  ## conditions" for some backends, e.g. multicore; fixed in future
  ## 1.80.0-9016)
  if (inorder && packageVersion("future") < "1.80.0-9016") {
    ## Skip this part
  } else {
    f <- future({ cat("hello\n"); 42 })
    out <- utils::capture.output({
      v <- value(list(f), stdout = FALSE, inorder = inorder)
    })
    stopifnot(identical(v, list(42)), length(out) == 0L)
  }

  ## stdout = TRUE: Standard output is relayed
  f <- future({ cat("hello\n"); 42 })
  out <- utils::capture.output({
    v <- value(list(f), stdout = TRUE, inorder = inorder)
  })
  stopifnot(identical(v, list(42)), identical(out, "hello"))

  ## signal = FALSE: Errors are returned, not signaled
  f <- future(stop("boom"))
  v <- value(list(f), signal = FALSE, inorder = inorder)
  stopifnot(
    is.list(v), length(v) == 1L,
    inherits(v[[1]], "error"),
    conditionMessage(v[[1]]) == "boom"
  )
})


make_test(title = "value(<list>) - an error cancels and resolves the remaining futures", args = list(inorder = c(TRUE, FALSE)), tags = c("value", "cancel", "resolve", "error"), reset_workers = TRUE, {
  ## For inorder = FALSE, the remaining futures were neither canceled nor
  ## resolved (fixed in future 1.80.0-9009)
  if (!inorder && packageVersion("future") < "1.80.0-9009") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9009)")
  }

  ## The first future is still running when the second one fails
  fs <- list(
    future({ Sys.sleep(1.0); 1 }),
    future({ Sys.sleep(0.1); stop("boom") })
  )
  res <- tryCatch(value(fs, inorder = inorder), error = identity)

  ## The error is the one produced by the future, and not an orchestration
  ## error, e.g. FutureInterruptError due to canceling a future
  stopifnot(
    inherits(res, "error"),
    !inherits(res, "FutureError"),
    conditionMessage(res) == "boom"
  )

  ## All futures are resolved when value() has signaled the error,
  ## regardless of the backend supporting interrupting futures or not
  stopifnot(all(resolved(fs)))
})


make_test(title = "value(<list>) - an error does not launch lazy futures", args = list(inorder = c(TRUE, FALSE)), tags = c("value", "lazy", "error"), {
  ## The lazy futures were launched, and waited for, before signaling the
  ## error (fixed in future 1.80.0-9015)
  if (packageVersion("future") < "1.80.0-9015") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9015)")
  }

  f1 <- future(stop("boom"))
  ## Make sure the first future has failed before calling value(), because
  ## value() launches lazy futures while waiting for others to resolve
  invisible(resolve(f1))
  f2 <- future(42, lazy = TRUE)
  stopifnot(f2[["state"]] %in% "created")

  res <- tryCatch(value(list(f1, f2), inorder = inorder), error = identity)
  stopifnot(inherits(res, "error"), conditionMessage(res) == "boom")

  ## The lazy future was never launched
  stopifnot(f2[["state"]] %in% "created")
})


make_test(title = "value(<list>) - future resolving to an error object", args = list(inorder = c(TRUE, FALSE), drop = c(FALSE, TRUE)), tags = c("value", "error"), {
  ## value(<list>) signaled an error for a future whose value is an
  ## error object, whereas value(<Future>) returned it (fixed in future
  ## 1.80.0-9014)
  if (packageVersion("future") < "1.80.0-9014") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9014)")
  }

  ## A future returning an error object has not failed
  f <- future(simpleError("boom"))
  v1 <- value(f)
  stopifnot(inherits(v1, "simpleError"))

  ## ... and value(<list>) must return it as-is, too
  f <- future(simpleError("boom"))
  v2 <- value(list(f), inorder = inorder, drop = drop)
  stopifnot(is.list(v2), length(v2) == 1L, identical(v2[[1]], v1))
})


make_test(title = "value(<list>) - relays standard output and messages of all futures in order", args = list(drop = c(FALSE, TRUE)), tags = c("value", "stdout", "conditions"), {
  ## With drop = TRUE, the standard output and messages of futures that
  ## were resolved before the ones preceding them were lost (fixed in
  ## future 1.80.0-9016)
  if (drop && packageVersion("future") < "1.80.0-9016") {
    future.tests::skip_test("Test requires future (>= 1.80.0-9016)")
  }

  ## The second future is typically resolved first
  fs <- list(
    future({ Sys.sleep(1.0); cat("out-a\n"); message("msg-a"); 1 }),
    future({                 cat("out-b\n"); message("msg-b"); 2 })
  )

  msgs <- character(0L)
  out <- utils::capture.output({
    v <- withCallingHandlers({
      value(fs, drop = drop)
    }, message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    })
  })

  stopifnot(
    identical(v, list(1, 2)),
    identical(out, c("out-a", "out-b")),
    identical(msgs, c("msg-a\n", "msg-b\n"))
  )
})
