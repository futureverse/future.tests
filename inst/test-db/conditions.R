captureConditions <- function(...) {
  conditions <- list()
  withCallingHandlers(..., condition = function(c) {
    conditions[[length(conditions) + 1L]] <<- c
    if (inherits(c, "message")) {
      invokeRestart("muffleMessage")
    } else if (inherits(c, "warning")) {
      invokeRestart("muffleWarning")
    }	
  })
  conditions
}


make_test(title = "future() - conditions", args = list(), tags = c("future", "conditions"), bquote({
  captureConditions <- .(captureConditions)
  
  truth <- captureConditions({
    message("hello")
    warning("whoops")
    message("world")
  })
  
  f <- future({
    print(1:3)
    message("hello")
    warning("whoops")
    message("world")
    42L
  })
  
  r <- result(f)
  str(r)
  stopifnot(value(f) == 42L)

  conditions <- r$conditions
  stopifnot(is.list(conditions), length(conditions) == 3L)
  conditions <- lapply(conditions, FUN = function(c) c$condition)
  for (kk in seq_along(conditions)) {
    stopifnot(
      identical(class(conditions[[kk]]), class(truth[[kk]])),
      identical(conditions[[kk]]$message, truth[[kk]]$message)
    )
  }

  conditions <- captureConditions(value(f))
  stopifnot(is.list(conditions), length(conditions) == 3L)
  for (kk in seq_along(conditions)) {
    stopifnot(
      identical(class(conditions[[kk]]), class(truth[[kk]])),
      identical(conditions[[kk]]$message, truth[[kk]]$message)
    )
  }
}), substitute = FALSE)


make_test(title = "%<-% - conditions", args = list(), tags = c("%<-%", "conditions"), bquote({
  captureConditions <- .(captureConditions)
  
  truth <- captureConditions({
    message("hello")
    warning("whoops")
    message("world")
  })
  
  v %<-% {
    print(1:3)
    message("hello")
    warning("whoops")
    message("world")
    42L
  }

  conditions <- captureConditions(v)
  stopifnot(v == 42L)
  stopifnot(is.list(conditions), length(conditions) == 3L)
  for (kk in seq_along(conditions)) {
    stopifnot(
      identical(class(conditions[[kk]]), class(truth[[kk]])),
      identical(conditions[[kk]]$message, truth[[kk]]$message)
    )
  }
}), substitute = FALSE)


make_test(title = "future() - muffle conditions", args = list(), tags = c("future", "conditions", "muffle"), bquote({
  captureConditions <- .(captureConditions)
  
  f <- future({
    print(1:3)
    message("hello")
    warning("whoops")
    message("world")
    42L
  }, conditions = character(0L))
  
  r <- result(f)
  str(r)
  stopifnot(value(f) == 42L)

  conditions <- r$conditions
  stopifnot(is.list(conditions), length(conditions) == 0L)

  conditions <- captureConditions(value(f))
  stopifnot(is.list(conditions), length(conditions) == 0L)
}), substitute = FALSE)


make_test(title = "future() - custom conditions are relayed with their classes", args = list(), tags = c("future", "conditions", "devel"), bquote({
  captureConditions <- .(captureConditions)

  expr <- quote({
    message(messageCondition("hello", class = "myMessage"))
    warning(warningCondition("whoops", class = "myWarning"))
    signalCondition(structure(
      class = c("myCondition", "condition"),
      list(message = "custom", call = NULL, data = 1:3)
    ))
    message("world")
    42L
  })

  truth <- captureConditions(eval(expr))

  f <- future(expr, substitute = FALSE)
  conditions <- captureConditions(v <- value(f))
  stopifnot(identical(v, 42L))
  stopifnot(is.list(conditions), length(conditions) == length(truth))
  for (kk in seq_along(conditions)) {
    stopifnot(
      identical(class(conditions[[kk]]), class(truth[[kk]])),
      identical(conditionMessage(conditions[[kk]]), conditionMessage(truth[[kk]]))
    )
  }
  stopifnot(identical(conditions[[3]]$data, 1:3))
}), substitute = FALSE)


make_test(title = "future() - errors are relayed with their class and fields", args = list(), tags = c("future", "conditions", "error", "devel"), {
  truth <- tryCatch(stop("boom"), error = identity)
  for (conditions in list("condition", character(0L))) {
    f <- future(stop("boom"), conditions = conditions)
    e <- tryCatch(value(f), error = identity)
    print(e)
    stopifnot(
      identical(class(e), class(truth)),
      identical(conditionMessage(e), conditionMessage(truth))
    )
  }

  truth <- errorCondition("boom", class = "myError", data = 1:3)
  for (conditions in list("condition", character(0L))) {
    f <- future(stop(errorCondition("boom", class = "myError", data = 1:3)), conditions = conditions)
    e <- tryCatch(value(f), error = identity)
    print(e)
    stopifnot(
      identical(class(e), class(truth)),
      identical(conditionMessage(e), conditionMessage(truth)),
      identical(e$data, truth$data)
    )
  }
})


make_test(title = "future() - argument 'conditions' controls which conditions are relayed", args = list(), tags = c("future", "conditions", "devel"), bquote({
  captureConditions <- .(captureConditions)

  expr <- quote({
    message("hello")
    warning("whoops")
    signalCondition(structure(
      class = c("myCondition", "condition"),
      list(message = "custom", call = NULL)
    ))
    message("world")
    42L
  })

  classesOf <- function(conditions) {
    vapply(conditions, FUN = function(c) class(c)[1], FUN.VALUE = NA_character_)
  }

  specs <- list(
    list(conditions = "message",
         expected = c("simpleMessage", "simpleMessage")),
    list(conditions = "warning",
         expected = c("simpleWarning")),
    list(conditions = structure("condition", exclude = "message"),
         expected = c("simpleWarning", "myCondition"))
  )

  for (spec in specs) {
    str(spec)
    f <- future(expr, substitute = FALSE, conditions = spec$conditions)
    conditions <- captureConditions(v <- value(f))
    stopifnot(identical(v, 42L))
    classes <- unname(classesOf(conditions))
    print(classes)
    stopifnot(identical(classes, spec$expected))

    ## Captured conditions reflect the same filtering
    classes <- unname(classesOf(lapply(result(f)$conditions, FUN = function(c) c$condition)))
    stopifnot(identical(classes, spec$expected))
  }
}), substitute = FALSE)
