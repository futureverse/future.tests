# Make a Test

Make a Test

## Usage

``` r
make_test(
  expr,
  title = NA_character_,
  args = list(),
  tags = NULL,
  substitute = TRUE,
  reset_workers = FALSE,
  register = !("devel" %in% tags) || isTRUE(getOption("future.tests.devel"))
)
```

## Arguments

- expr, substitute:

  The expression to be tested and whether it is passed as an expression
  already or not.

- title:

  (character) The title of the test.

- args:

  (optional) Named arguments.

- tags:

  (optional) Character vector of tags.

- reset_workers:

  (optional) Specifies whether background workers should futures.

- register:

  If TRUE, the test is registered in the test database, otherwise not.
  The default is to register the test, unless `tags` contains `"devel"`.

## Value

(invisibly) A Test.
