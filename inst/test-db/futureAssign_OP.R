make_test(title = "%<-% - local evaluation", args = list(lazy = c(FALSE, TRUE)), tags = c("%<-%", "lazy"), {
  v %<-% { x <- 1 } %lazy% lazy
  stopifnot(!exists("x", inherits = FALSE), identical(v, 1))
})

make_test(title = "%<-% - local evaluation & global variable", args = list(lazy = c(FALSE, TRUE)), tags = c("%<-%", "lazy", "global"), {
  a <- 2
  v %<-% { x <- a } %lazy% lazy
  stopifnot(!exists("x", inherits = FALSE), identical(v, a))
})

make_test(title = "%<-% - errors", args = list(lazy = c(FALSE, TRUE)), tags = c("%<-%", "lazy", "error"), {
  v %<-% {
    x <- 3
    stop("Woops!")
    x
  } %lazy% lazy
  stopifnot(!exists("x", inherits = FALSE))
  res <- tryCatch(identical(v, 3), error = identity)
  stopifnot(inherits(res, "error"))
})


make_test(title = "%<-% - errors and listenv", args = list(lazy = c(FALSE, TRUE)), tags = c("%<-%", "lazy", "error", "listenv"), {
  y <- listenv::listenv()
  for (ii in 1:3) {
    y[[ii]] %<-% {
      if (ii %% 2 == 0) stop("Woops!")
      ii
    }
  } %lazy% lazy
  res <- tryCatch(as.list(y), error = identity)
  stopifnot(inherits(res, "error"))
  
  z <- y[c(1, 3)]
  z <- unlist(z)
  stopifnot(all(z == c(1, 3)))
  
  res <- tryCatch(y[[2]], error = identity)
  stopifnot(inherits(res, "error"))
  res <- tryCatch(y[1:2], error = identity)
  stopifnot(inherits(res, "error"))
})



make_test(title = "%<-% & %->%", args = list(lazy = c(FALSE, TRUE)), tags = c("%<-%", "%->%", "lazy"), {
  c %<-% 1 %lazy% lazy
  cat(sprintf("c = %s\n", c))
  1 %->% d %lazy% lazy
  cat(sprintf("d = %s\n", d))
  stopifnot(d == c)
})


## FIXME: This only tests plan(list(<strategy>, sequential))
## Need a way to formally specify that certain tests are nested
## and to what depth.
make_test(title = "%<-% - nested", tags = c("%<-%", "nested"), {
  a %<-% {
    b <- 1
    c %<-% 2
    3 -> d
    4 %->% e
    b + c + d + e
  }
  cat(sprintf("a = %s\n", a))
  stopifnot(a == 10)

  { a + 1 } %->% b
  cat(sprintf("b = %s\n", b))
  stopifnot(b == a + 1)
})


make_test(title = "future() - label", tags = c("future", "label", "frontend"), {
  f <- future(42L, label = "my-future")
  stopifnot(identical(f[["label"]], "my-future"))
  stopifnot(identical(value(f), 42L))
})


make_test(title = "futureOf(), futures(), and infix operators", tags = c("%<-%", "futureOf", "futures", "infix", "frontend"), {
  ## %label% + futureOf()
  v %<-% { 42L } %label% "my-assigned-future"
  f <- futureOf(v)
  stopifnot(inherits(f, "Future"), identical(f[["label"]], "my-assigned-future"))
  stopifnot(identical(v, 42L))

  ## futures() on listenv
  le <- listenv::listenv()
  le[[1]] %<-% { 1L }
  le[[2]] <- 2L
  fs <- futures(le)
  stopifnot(inherits(fs[[1]], "Future"), identical(fs[[2]], 2L))
  stopifnot(identical(as.list(le), list(1L, 2L)))

  ## %globals%
  a <- 10L
  y %<-% { a + 1L } %globals% list(a = 41L)
  stopifnot(identical(y, 42L))

  ## %packages%
  z %<-% { "utils" %in% loadedNamespaces() } %packages% "utils"
  stopifnot("utils" %in% futureOf(z)[["packages"]], isTRUE(z))

  ## %conditions% (muffle)
  msgs <- character(0L)
  w %<-% { message("hidden"); 42L } %conditions% character(0L)
  val <- withCallingHandlers(w, message = function(m) {
    msgs <<- c(msgs, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  stopifnot(identical(val, 42L), length(msgs) == 0L)
})
