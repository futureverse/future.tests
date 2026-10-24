pcat <- future.tests:::pcat
perase <- future.tests:::perase
preset <- future.tests:::preset

message("*** progress ...")

perase()
cat("\n")

pcat("hello")
cat("\n")
pcat("hello world, how are you?", max_width = 10L)
cat("\n")

preset()
cat("\n")
preset("hello")
cat("\n")

## Width is calculated from the visible text, not from ANSI escape codes
old <- options(future.tests.progress = TRUE, cli.num_colors = 256L)
line <- cli::col_red("abcdefghij")
out <- utils::capture.output(pcat(line, max_width = 20L), type = "message")
options(old)
stopifnot(!grepl("...", out, fixed = TRUE))

message("*** progress ... DONE")
