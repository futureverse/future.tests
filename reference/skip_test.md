# Skip The Current Test

Signals a `TestSkipped` condition.

## Usage

``` r
skip_test(..., domain = NULL)
```

## Arguments

- ...:

  zero or more objects which can be coerced to character (and which are
  pasted together with no separator) or (for `message` only) a single
  condition object.

- domain:

  see [`gettext`](https://rdrr.io/r/base/gettext.html). If `NA`,
  messages will not be translated, see also the note in
  [`stop`](https://rdrr.io/r/base/stop.html).

## Value

(invisible) A [base::condition](https://rdrr.io/r/base/conditions.html)
of class `TestSkipped`.
