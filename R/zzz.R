## covr: skip=all
#' @importFrom future availableCores
.onLoad <- function(libname, pkgname) {
  ## Don't override option 'future.tests.debug', if already set
  debug <- getOption("future.tests.debug")
  if (is.null(debug)) {
    debug <- isTRUE(as.logical(Sys.getenv("R_FUTURE_TESTS_DEBUG", FALSE)))
    options(future.tests.debug = debug)
  }
  debug <- isTRUE(debug)

  value <- getOption("future.tests.undo")
  if (is.null(value)) {
    value <- Sys.getenv("R_FUTURE_TESTS_UNDO", "envvars,graphics,objects,options,rng")
    value <- unlist(strsplit(value, split = ","))
    value <- gsub(" ", "", value)
    options(future.tests.undo = value)
  }

  value <- getOption("future.tests.devel")
  if (is.null(value)) {
    value <- Sys.getenv("R_FUTURE_TESTS_DEVEL", NA_character_)
    if (!is.na(value)) {
      value <- isTRUE(as.logical(value))
      options(future.tests.devel = value)
    }
  }

  args <- parseCmdArgs()
  cores <- args$cores
  if (!is.null(cores)) {
    if (debug) mdebug("R command-line argument: --cores=%s", cores)
    options(mc.cores = cores)
  } else if (is.null(getOption("mc.cores"))) {
    ## Use at most two cores by default, unless option 'mc.cores' is set
    options(mc.cores = min(2L, availableCores()))
  }
  if (debug) mdebug("Available cores: %d", availableCores())
  
  ## Pre-load all tests
  load_tests()

  register_vignette_engine_during_build_only(pkgname)
}
