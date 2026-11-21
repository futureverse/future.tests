db_state <- future.tests:::db_state
options(future.tests.debug = TRUE)

message("*** db_state() ...")

res <- db_state("list")
str(res)

res <- db_state("reset")
str(res)

stack <- db_state("list")
str(stack)
stopifnot(length(stack) == 1L)

res <- db_state("push", title = "abc")
str(res)

options(foo = 42L)
Sys.setenv(BAR = "3.14")

stack <- db_state("list")
str(stack)
stopifnot(length(stack) == 2L)

res <- db_state("push", title = "def")
str(res)

stack <- db_state("list")
str(stack)
stopifnot(length(stack) == 3L)

res <- db_state("pop")
str(res)

stack <- db_state("list")
str(stack)
stopifnot(length(stack) == 2L)

res <- db_state("pop")
str(res)

stack <- db_state("list")
str(stack)
stopifnot(length(stack) == 1L)

## Popping an empty state stack is an error and leaves the state as-is
envs <- Sys.getenv()
opts <- options()
res <- tryCatch(db_state("pop"), error = identity)
print(res)
stopifnot(
  inherits(res, "error"),
  length(db_state("list")) == 1L,
  identical(Sys.getenv(), envs),
  identical(names(options()), names(opts))
)

message("*** db_state() ... DONE")
