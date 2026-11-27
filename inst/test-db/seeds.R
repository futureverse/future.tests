make_test(title = 'Random Number Generation (RNG) - seeds and preserving RNGkind', tags = c("rng", "seed"), {
  okind <- RNGkind()

  ## A valid L'Ecuyer-CMRG RNG seed
  seed <- c(407L, 1420090545L, 65713854L, -990249945L,
            1780737596L, -1213437427L, 1082168682L)
  f <- future(42, seed = seed)
  print(f)

  ## Assert that random seed is reset
  stopifnot(identical(f$seed, seed))
  
  ## Assert that the RNG kind is reset
  stopifnot(identical(RNGkind()[1], okind[1]))
})


make_test(title = 'Random Number Generation (RNG) - seed = TRUE and seed = <integer>', args = list(lazy = c(FALSE, TRUE)), tags = c("rng", "seed", "lazy", "auto-seed"), {
  ## Reference values under sequential
  ref <- local({
    old_plan <- plan()
    plan("sequential")
    on.exit(plan(old_plan))

    y_int <- value(future(rnorm(3L), seed = 42L, lazy = lazy))

    set.seed(42L)
    y_true <- value(future(rnorm(3L), seed = TRUE, lazy = lazy))
    rng_after <- globalenv()$.Random.seed

    list(y_int = y_int, y_true = y_true, rng_after = rng_after)
  })

  ## Fixed integer seed: reproducible and does not alter parent RNG state
  set.seed(123L)
  rng0 <- globalenv()$.Random.seed
  y1 <- value(future(rnorm(3L), seed = 42L, lazy = lazy))
  y2 <- value(future(rnorm(3L), seed = 42L, lazy = lazy))
  stopifnot(
    identical(y1, ref$y_int),
    identical(y2, ref$y_int),
    identical(globalenv()$.Random.seed, rng0)
  )

  ## seed = TRUE: reproducible across backends and advances parent RNG state identically
  set.seed(42L)
  y3 <- value(future(rnorm(3L), seed = TRUE, lazy = lazy))
  stopifnot(
    identical(y3, ref$y_true),
    identical(globalenv()$.Random.seed, ref$rng_after)
  )
})



## See Section 6 on 'Random-number generation' in
## vignette("parallel", package = "parallel")
fsample <- function(x, size = 2L, seed = NULL, what = c("future", "%<-%"), lazy = FALSE) {
  what <- match.arg(what)
  
  ## Must use session-specific '.GlobalEnv' here
  .GlobalEnv <- globalenv()
  
  oseed <- .GlobalEnv$.Random.seed
  orng <- RNGkind("L'Ecuyer-CMRG")[1L]
  on.exit(RNGkind(orng))

  if (!is.null(seed)) {
    ## Reset state of random seed afterwards?
    on.exit({
      if (is.null(oseed)) {
        rm(list = ".Random.seed", envir = .GlobalEnv, inherits = FALSE)
      } else {
        .GlobalEnv$.Random.seed <- oseed
      }
    }, add = TRUE)

    set.seed(seed)
  }

  .seed <- .Random.seed

  if (what == "future") {
    fs <- list()
    for (ii in seq_len(size)) {
      .seed <- parallel::nextRNGStream(.seed)
      fs[[ii]] <- future({ sample(x, size = 1L) }, lazy = lazy, seed = .seed)
    }
    res <- value(fs)
  } else {
    res <- listenv::listenv()
    for (ii in seq_len(size)) {
      .seed <- parallel::nextRNGStream(.seed)
      res[[ii]] %<-% { sample(x, size = 1L) } %lazy% lazy %seed% .seed
    }
    res <- as.list(res)
  }
  
  res
} # fsample()


for (what in c("future", "%<-%")) {
  make_test(title = sprintf('Random Number Generation (RNG) - %s', what), args = list(lazy = c(FALSE, TRUE)), tags = c("rng", "seed", "lazy", what), bquote({
    fsample <- .(fsample)

    dummy <- sample(0:3, size = 1L)
    seed0 <- .Random.seed
  
    ## Reference sample with fixed random seed
    y0 <- local({
      print(unclass(plan))
      utils::str(plan)
      old_plan <- plan()
      plan("sequential")
      on.exit(plan(old_plan))
      fsample(0:3, seed = 42L)
    })
    
    ## Assert that random seed is reset
    stopifnot(identical(.GlobalEnv$.Random.seed, seed0))
  
    .GlobalEnv$.Random.seed <- seed0
  
    ## Fixed random seed
    y1 <- fsample(0:3, seed = 42L, what = .(what), lazy = lazy)
    print(y1)
    stopifnot(identical(y1, y0))
  
    ## Assert that random seed is reset
    stopifnot(identical(.GlobalEnv$.Random.seed, seed0))
  
    ## Fixed random seed
    y2 <- fsample(0:3, seed = 42L, what = .(what), lazy = lazy)
    print(y2)
    stopifnot(identical(y2, y1))
    stopifnot(identical(y2, y0))
  
    ## Assert that random seed is reset
    stopifnot(identical(.GlobalEnv$.Random.seed, seed0))
  
    ## No seed
    y3 <- fsample(0:3, what = .(what), lazy = lazy)
    print(y3)
  }), substitute = FALSE)
} ## for (what ...)



make_test(title = 'Orchestration Stability - future() does not update RNG state', tags = c("orchestration", "rng", "seed", "stealth"), {
  rng0 <- globalenv()$.Random.seed

  f1 <- future(1)
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))

  f2 <- future(2)
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))

  v1 <- value(f1)
  stopifnot(identical(v1, 1))
  
  v2 <- value(f2)
  stopifnot(identical(v2, 2))
})


make_test(title = 'Orchestration Stability - run() does not update RNG state', tags = c("orchestration", "rng", "seed", "stealth"), {
  f1 <- future(1, lazy = TRUE)
  f2 <- future(2, lazy = TRUE)

  rng0 <- globalenv()$.Random.seed

  f1 <- run(f1)
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))

  f2 <- run(f2)
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))

  v1 <- value(f1)
  stopifnot(identical(v1, 1))
  
  v2 <- value(f2)
  stopifnot(identical(v2, 2))
})


make_test(title = 'Orchestration Stability - resolved() does not update RNG state', tags = c("orchestration", "rng", "seed", "stealth", "resolved"), {
  f1 <- future({ Sys.sleep(0.2); 1 })
  f2 <- future(2, lazy = TRUE)

  rng0 <- globalenv()$.Random.seed

  while (!resolved(f1)) {
    ## Assert RNG state is still the same
    stopifnot(identical(globalenv()$.Random.seed, rng0))
    Sys.sleep(0.05)
  }
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))

  while (!resolved(f2)) {
    ## Assert RNG state is still the same
    stopifnot(identical(globalenv()$.Random.seed, rng0))
    Sys.sleep(0.05)
  }
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))

  v1 <- value(f1)
  stopifnot(identical(v1, 1))

  v2 <- value(f2)
  stopifnot(identical(v2, 2))
})


make_test(title = 'Orchestration Stability - result() does not update RNG state', tags = c("orchestration", "rng", "seed", "stealth"), {
  f1 <- future(1)
  f2 <- future(2)

  rng0 <- globalenv()$.Random.seed

  r1 <- result(f1)
  stopifnot(identical(r1$value, 1))
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))
  
  r2 <- result(f2)
  stopifnot(identical(r2$value, 2))
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))
})


make_test(title = 'Orchestration Stability - value() does not update RNG state', tags = c("orchestration", "rng", "seed", "stealth"), {
  f1 <- future(1)
  f2 <- future(2)

  rng0 <- globalenv()$.Random.seed

  v1 <- value(f1)
  stopifnot(identical(v1, 1))
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))
  
  v2 <- value(f2)
  stopifnot(identical(v2, 2))
  ## Assert RNG state is still the same
  stopifnot(identical(globalenv()$.Random.seed, rng0))
})
