make_test(title = "cancel()", args = list(lazy = c(FALSE, TRUE)), tags = c("cancel"), {
  f <- future({
    Sys.sleep(0.5)
    list(a = 1, b = 42L)
  }, lazy = lazy)

  f0 <- future(NULL)
  v <- value(f0)

  cat(sprintf("state = %s\n", sQuote(f[["state"]])))
  if (lazy) {
    stopifnot(f[["state"]] %in% "created")
  } else {
    stopifnot(f[["state"]] %in% c("submitted", "running", "finished"))
  }
  
  f <- cancel(f)
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
})
