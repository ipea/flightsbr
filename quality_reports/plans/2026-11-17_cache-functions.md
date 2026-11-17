# Plan: cache-management functions for flightsbr (geocodebr-style)

**Status:** COMPLETED · 2026-11-17 · new branch from `origin/main` (after #59)


## Context

flightsbr gained a persistent download cache in #59. Its only management tool is `flightsbr_cache()`, which lists and deletes files, plus a session-only option, `flightsbr.cache_dir`. Neither has been released on CRAN.

geocodebr (`r-package/R/cache.R`) offers four clearer functions, and its main feature is a cache folder choice that **persists across sessions**:

| geocodebr | What it does |
|---|---|
| `definir_pasta_cache(path)` | Writes the folder to a config file at `R_user_dir("geocodebr", "config")/cache_dir`. `NULL` means the default. |
| `listar_pasta_cache()` | Reads the config file, or falls back to `R_user_dir("geocodebr", "cache")`. |
| `listar_dados_cache(print_tree)` | Lists the cached files, optionally as a tree with `fs::dir_tree()`. |
| `deletar_pasta_cache()` | `unlink(cache_dir, recursive = TRUE)` |

The goal is the same set in flightsbr, with English names.

**Decisions (user):**
- Names follow censobr's pattern: `set_flightsbr_cache_dir()`, `get_flightsbr_cache_dir()`, `list_flightsbr_cache()`, `delete_flightsbr_cache()`.
- `flightsbr_cache()` is **removed**. It was never on CRAN, so no deprecation is needed.

**Assumed:**
- The `flightsbr.cache_dir` option is also removed (also unreleased), so there is a single mechanism.
- No new dependencies. geocodebr uses `checkmate` and `cli`; flightsbr will use base `stop()` / `message()` and `fs`, which is already in Imports.

## Approach

### 1. `R/cache.R` (replaces `R/flightsbr_cache.R`)

Internal helpers:
- `default_cache_dir()` returns `tools::R_user_dir("flightsbr", which = "cache")`.
- `cache_config_file()` returns `fs::path(tools::R_user_dir("flightsbr", which = "config"), "cache_dir")`.

Exported, all `@family Cache data`:

- **`set_flightsbr_cache_dir(path = NULL, verbose = TRUE)`**
  - Checks that `path` is `NULL` or a single non-NA string.
  - If `path` is given, writes `fs::path_norm(path)` to the config file, creating the config folder first.
  - `path = NULL` **deletes** the config file, which restores the default. geocodebr writes the default path instead; deleting means a later change to the default still applies.
  - It does not move files that are already cached; the docs will say so.
  - Prints a message with the folder when `verbose`, and returns the folder invisibly.
- **`get_flightsbr_cache_dir()`**
  - Returns the path from the config file if one exists, otherwise the default, as a character string.
  - Never creates anything.
- **`list_flightsbr_cache(print_tree = FALSE)`**
  - Returns the cached file paths as a character vector.
  - If the folder doesn't exist or is empty, prints a message and returns `character(0)`. It doesn't create the folder.
  - `print_tree = TRUE` draws `fs::dir_tree()` and returns the paths invisibly.
- **`delete_flightsbr_cache(file = NULL, verbose = TRUE)`**
  - `NULL` deletes every cached file. Basenames such as `"basica2000-01.zip"` delete just those files; names that aren't in the cache get a message.
  - **Safety change from geocodebr:** it deletes only *files* directly in the cache folder (not recursive), then removes the folder if it ends up empty. geocodebr's `unlink(recursive = TRUE)` would wipe a whole folder, such as a Documents folder, if a user had pointed the cache at it.
  - Returns the cache folder invisibly.

### 2. Wire the download code to it (`R/utils.R`)

Change `flightsbr_cache_dir(create = TRUE)` so it builds on `get_flightsbr_cache_dir()` (creating the folder if asked) instead of `getOption("flightsbr.cache_dir")`. The 5 readers and the `dest_file` default of `download_flightsbr_file()` already call `flightsbr_cache_dir()`, so they need no change. Also update the roxygen references to `flightsbr_cache()` and to the option (in `R/utils.R` and in the `man/roxygen/templates/cache.R` template).

### 3. Tests: CRAN-safe isolation through environment variables

`tools::R_user_dir()` honours the `R_USER_CACHE_DIR` and `R_USER_CONFIG_DIR` environment variables. So:

- `tests/testthat/setup.R`:
  - Replace the option with `withr::local_envvar(R_USER_CACHE_DIR = <tempdir>/cache, R_USER_CONFIG_DIR = <tempdir>/config, .local_envir = testthat::teardown_env())`.
  - Tests then never touch the user's real cache or config, including on CRAN. geocodebr's own tests write to the real config file and restore it afterwards.
- Rewrite `tests/testthat/test_cache.R` (offline, runs on CRAN):
  - Set, get and reset round-trip; path normalisation; input errors.
  - `list_flightsbr_cache()` on a missing folder, an empty folder (and that it doesn't create one), files, and `print_tree`.
  - `delete_flightsbr_cache()` for one file, an unknown file, and everything. It must leave subfolders and their files alone.
  - The readers use the folder chosen with `set_flightsbr_cache_dir()`, checked through `flightsbr_cache_dir()`.
- `tests/testthat/test_read_airport_movements.R`: in the download-once test, switch from the option to `set_flightsbr_cache_dir(withr::local_tempdir())`, reset on exit.

### 4. Docs

- Examples:
  - `get_flightsbr_cache_dir()` and `list_flightsbr_cache()` run as normal, since they're read-only.
  - `set_` and `delete_` go under `@examplesIf interactive()`, so `R CMD check` never writes to the user's config or deletes their cache.
- Add a short "Cache" section to `vignettes/intro_flightsbr.Rmd` (`eval = FALSE`) covering where files go, and how to change, list and delete them.
- Rewrite the NEWS dev entry: replace the `flightsbr_cache()` and option bullets with the four functions. Then run `devtools::document()`. `NAMESPACE` gains 4 exports and loses `flightsbr_cache`. pkgdown has no reference index, so it needs no change.

## Order

0. Create branch `cache-functions` from `origin/main`. Move the plan file (see the housekeeping note at the top). Start the session log.
1. `R/cache.R` and the `R/utils.R` wiring. Delete `R/flightsbr_cache.R`.
2. Test setup and tests.
3. Docs, vignette and NEWS, then `devtools::document()`.
4. Verification.

## Verification

1. `devtools::test(filter = "cache")`, which is offline.
2. Manual session:
   - `get_flightsbr_cache_dir()` shows the default.
   - `set_flightsbr_cache_dir(tmp)`, restart R, and `get_flightsbr_cache_dir()` still returns `tmp`.
   - `read_airports()` saves its file into `tmp`. `list_flightsbr_cache()` lists it and `delete_flightsbr_cache()` empties it.
   - `set_flightsbr_cache_dir(NULL)` restores the default.
3. Check that the user's real `R_user_dir("flightsbr", "config")` is untouched after the tests.
4. Run `/r-package-check`, i.e. `devtools::check(args = "--as-cran")`. The bar is 0 errors and 0 warnings; the `.git` worktree note is expected.
