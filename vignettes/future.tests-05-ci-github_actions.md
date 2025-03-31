<!--
%\VignetteIndexEntry{future.tests: Continuous Integration on GitHub Actions}
%\VignetteAuthor{Henrik Bengtsson}
%\VignetteKeyword{R}
%\VignetteKeyword{package}
%\VignetteKeyword{vignette}
%\VignetteKeyword{future}
%\VignetteKeyword{continuous integration}
%\VignetteKeyword{CI}
%\VignetteKeyword{GitHub Actions}
%\VignetteEngine{future.tests::selfonly}
-->

We can use continuous integration (CI) services such as GitHub Action and Travis CI to automatically validate **[future]** backends via the **[future.tests]** test suite.

Here is an example of a `.github/workflow/future.tests.yaml` file that configures GitHub Actions to check several backends via the **future.tests** test suite.

```yaml
on: [push, pull_request]

name: future_tests

jobs:
  future_tests:
    if: "! contains(github.event.head_commit.message, '[ci skip]')"    

    timeout-minutes: 30
    
    runs-on: ubuntu-latest

    name: future.plan=${{ matrix.future.plan }}

    strategy:
      fail-fast: false
      matrix:
        future:
          - { plan: 'cluster'                             }
          - { plan: 'multicore'                           }
          - { plan: 'multisession'                        }
          - { plan: 'sequential'                          }
          - { plan: 'future.batchtools::batchtools_local' }
          - { plan: 'future.batchtools::batchtools_bash'  }
          - { plan: 'future.callr::callr'                 }
          - { plan: 'future.mirai::mirai_multisession'    }
          - { plan: 'future.mirai::mirai_cluster'         }

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_REMOTES_NO_ERRORS_FROM_WARNINGS: true
      ## R CMD check
      _R_CHECK_MATRIX_DATA_: true
      _R_CHECK_CRAN_INCOMING_: false
      ## Specific to futures
      R_FUTURE_RNG_ONMISUSE: error
      
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::rcmdcheck
            any::remotes
            any::sessioninfo
            any::covr
          needs: check

      - name: Install dependencies
        run: |
          remotes::install_deps(dependencies = TRUE)
          install.packages(".", repos=NULL, type="source")
        shell: Rscript {0}

      - name: Session info
        run: |
          options(width = 100)
          pkgs <- installed.packages()[, "Package"]
          sessioninfo::session_info(pkgs, include_base = TRUE)
        shell: Rscript {0}
          
      - name: Install 'future.tests' and any backend R packages
        run: |
          remotes::install_cran("future.tests")
          remotes::install_github("HenrikBengtsson/future.tests", ref="develop")
          if (grepl("::", plan <- "${{ matrix.future.plan }}") && nzchar(pkg <- sub("::.*", "", plan))) install.packages(pkg)
        shell: Rscript {0}

      - name: Session info
        run: |
          options(width = 100)
          pkgs <- installed.packages()[, "Package"]
          sessioninfo::session_info(pkgs, include_base = TRUE)
        shell: Rscript {0}
    
      - name: Check future backend '${{ matrix.future.plan }}'
        run: |
          R CMD build --no-build-vignettes --no-manual . 
          R CMD INSTALL *.tar.gz 
          Rscript -e future.tests::check --args --test-plan=${{ matrix.future.plan }}

      - name: Upload check results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: ${{ runner.os }}-r${{ matrix.future.plan }}-results
          path: check
```

For real-world examples, see the GitHub repositories of [**future**](https://github.com/futureverse/future), [**future.batchtools**](https://github.com/futureverse/future.batchtools), [**future.callr**](https://github.com/futureverse/future.callr), and [**future.mirai**](https://github.com/futureverse/future.mirai).

[R]: https://www.r-project.org
[future]: https://future.futureverse.org
[future.tests]: https://future.tests.futureverse.org
