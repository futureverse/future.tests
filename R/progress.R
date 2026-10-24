## Only report in-place progress (spinner) when both standard output and
## standard error are terminals. Otherwise, e.g. when output is piped (to
## 'tee') or logged to file, the carriage returns cannot erase anything, and
## the unbuffered standard-error output ends up interleaved with the
## buffered standard output.
progress_enabled <- function() {
  getOption("future.tests.progress", isatty(stdout()) && isatty(stderr()))
}

preset <- function(...) {
  if (!progress_enabled()) return(invisible())
  cat("\r", ..., sep = "", file = stderr())
}

#' @importFrom cli ansi_nchar ansi_substr
pcat <- function(..., indent = 2L, max_width = getOption("width")) {
  if (!progress_enabled()) return(invisible())
  line <- paste0(..., collapse = "")
  if (indent + ansi_nchar(line) > max_width) {
    line <- ansi_substr(line, start = 1L, stop = max_width - 3L - indent)
    line <- paste0(line, "...")
  }
  cat(line, file = stderr())
}

perase <- function() {
  if (!progress_enabled()) return(invisible())
  preset(rep(" ", times = getOption("width")), "\r")
}
