make_test(title = 'demo("mandelbrot", package = "future")', args = list(lazy = c(FALSE, TRUE)), tags = c("demo", "mandelbrot"), {
  options(future.demo.mandelbrot.nrow = 2L)
  options(future.demo.mandelbrot.resolution = 50L)
  options(future.demo.mandelbrot.delay = FALSE)

  ## FIXME: Should evaluateexpr() capture this?
  on.exit(grDevices::graphics.off())
  
  demo("mandelbrot", package = "future", ask = FALSE)
})
