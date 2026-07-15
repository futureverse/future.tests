## Use sequential futures by default
oplan <- local({
  oopts <- options(future.debug = FALSE)
  on.exit(options(oopts))
  future::plan(future::sequential)
})
