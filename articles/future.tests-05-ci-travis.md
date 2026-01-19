# future.tests: Continuous Integration on Travis CI

We can use continuous integration (CI) services such as GitHub Actions
and Travis CI to automatically validate
**[future](https://cran.r-project.org/package=future)** backends via the
**[future.tests](https://cran.r-project.org/package=future.tests)** test
suite.

Here’s an example `.travis.yaml` file that configures Travis CI to check
the `multisession` and the
[`future.callr::callr`](https://future.callr.futureverse.org/reference/callr.html)
backends via the **future.tests** test suite.

``` yaml
language: r
cache: packages
warnings_are_errors: false
r_check_args: --as-cran
latex: false

jobs:
  include:
    - os: linux
      r: release
      script:
        - R CMD build --no-build-vignettes --no-manual .
        - R CMD INSTALL --no-docs --no-html --no-help --no-demo *.tar.gz
        - Rscript -e future.tests::check --args --test-plan="${BACKEND}"
      env: BACKEND='sequential'
    - os: linux
      r: release
      script:
        - R CMD build --no-build-vignettes --no-manual .
        - R CMD INSTALL --no-docs --no-html --no-help --no-demo *.tar.gz
        - Rscript -e future.tests::check --args --test-plan="${BACKEND}"
      env: BACKEND='multicore'
    - os: linux
      r: release
      script:
        - R CMD build --no-build-vignettes --no-manual .
        - R CMD INSTALL --no-docs --no-html --no-help --no-demo *.tar.gz
        - Rscript -e future.tests::check --args --test-plan="${BACKEND}"
      env: BACKEND='multisession'
    - os: linux
      r: release
      script:
        - R CMD build --no-build-vignettes --no-manual .
        - R CMD INSTALL --no-docs --no-html --no-help --no-demo *.tar.gz
        - Rscript -e future.tests::check --args --test-plan="${BACKEND}"
      env: BACKEND='cluster'
    - os: linux
      r: release
      r_packages:
        - future.callr
      script:
        - R CMD build --no-build-vignettes --no-manual .
        - R CMD INSTALL --no-docs --no-html --no-help --no-demo *.tar.gz
        - Rscript -e future.tests::check --args --test-plan="${BACKEND}"
      env: BACKEND='future.callr::callr'
    - os: linux
      r: release
      r_packages:
        - future.batchtools
      script:
        - R CMD build --no-build-vignettes --no-manual .
        - R CMD INSTALL --no-docs --no-html --no-help --no-demo *.tar.gz
        - Rscript -e future.tests::check --args --test-plan="${BACKEND}"
      env: BACKEND='future.batchtools::batchtools_local'
    - os: linux
      r: release
      script:
        - R CMD build --no-build-vignettes --no-manual .
      r_packages:
        - covr
      after_success:
        - Rscript -e 'covr::codecov(quiet=FALSE)'
      env: NB='covr' ## Just a label

before_install:
  - Rscript -e 'c(physical = parallel::detectCores(logical = FALSE), logical = parallel::detectCores())'

notifications:
  email:
    on_success: change
    on_failure: change
```
