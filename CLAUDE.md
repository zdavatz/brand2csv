# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`brand2csv` fetches Swiss trademark registrations from `swissreg.ch` for a given timespan and writes them to CSV. The repo holds two implementations:

- **Ruby gem at the repo root** — original, drives the legacy JSF UI at `/srclient/...` via Mechanize. Endpoints no longer exist; the gem is kept for historical reference and parser fixtures.
- **Rust port in `rust/`** — current. Calls the live SPA JSON API at `/database/resources/...`. This is what should actually run.

## Common commands

```bash
bundle install                       # install gem dependencies
bundle exec rspec                    # run the full spec suite
bundle exec rspec spec/csv_spec.rb   # run one spec file
bundle exec rspec spec/csv_spec.rb:17 # run a single example by line
bundle exec rake spec                # rake wrapper (also runs `clean` first)
bundle exec rake gem                 # build gem into pkg/
bundle exec exe/brand2csv 1.10.2005-31.10.2005   # run the CLI from source
brand2csv 01.01.2013 "b*"            # run installed gem; second arg is name filter (glob)
brand2csv --swiss_only 1.1.2017-29.3.2017   # restrict to Swiss-domiciled owners
```

The CLI accepts either a single date `dd.mm.yyyy` or a `dd.mm.yyyy-dd.mm.yyyy` range. Output goes to `./<timespan>.csv` in the cwd. Travis builds force `LANG=de_CH.UTF-8` — German locale matters because error strings from swissreg are matched in German (see `BekannteFehler` in `lib/brand2csv.rb`).

## Architecture

The interesting logic is concentrated in a single file: **`lib/brand2csv.rb`**. The CLI in `bin/brand2csv` only parses arguments, validates the timespan, and calls `Brand2csv::run`.

Three layers, all inside `module Brand2csv`:

1. **`Brand2csv::Marke`** — a `Struct` representing one trademark row in the output CSV (name, Markennummer, Inhaber, address lines split into `zeile_1..5` + `plz` + `ort`).

2. **`Brand2csv::Swissreg`** — the scraper. The flow in `parse_swissreg` + `fetchresult` is:
   - `init_swissreg` opens a Mechanize session, fetches `start.jsp`, navigates to the extended trademark search, and captures the `javax.faces.ViewState` token into `@state`. This token is required on every subsequent POST.
   - `parse_swissreg` posts the search form to `sr3.jsp` with `HitsPerPage = 250` and the configured filters (active marks + pending applications, all publication reasons, country = CH if `--swiss_only`).
   - `fetchresult` → `getAllHits` recurses through paginated result pages, scraping trademark numbers via the `DetailRegexp` against link IDs of the form `d_swissreg:mainContent:data:N:tm_no_detail:id_detail`.
   - `fetchDetails(nummer)` then GETs `sr300.jsp?id=<nummer>` for each hit. **Critical workaround**: every 90 hits the session is re-`init_swissreg`'d because swissreg appears to throttle long-lived sessions (`@counterDetails % 90 == 0`).
   - `getMarkenInfoFromDetail` extracts the brand name (or image link if `Markenabbildung`), Inhaber, Vertreter flag, and Hinterlegungsdatum by xpath-walking the detail table.
   - `parseAddress` splits the Inhaber line on `, `, finds the line matching `^\d{4}\W*(.*)` to extract `plz`/`ort`, then heuristically rejoins lines that look like dangling numbers (housenumbers split off from street names).

3. **`Brand2csv::Swissreg::Vereinfachte`** — wraps a parsed simplified-results page. Holds `pageNr`, `nrSubPages`, `firstHit`, `nrHits` (parsed via `HitRegexpDE` from German status text), `links2details`, and the JSF `ViewState`. Provides `getPostDataForSubpage` / `getPostDataForDetail` to construct the next POST body.

### Things to know before editing

- **Brittle by design.** Selectors, form field names (`id_swissreg:mainContent:...`), and German error strings are hard-coded against the live swissreg HTML. The mocked WebMock spec (`spec/swissreg_spec.rb`) is marked `pending('mocking swissreg no longer works')` — the only tests that still run are pure HTML-fixture unit tests in `spec/data/`. Don't expect to verify scraper changes via the mock harness.
- **Logs and HTML fixtures in `logs/`.** When `$VERBOSE` is true (or under RSpec) every page response is dumped to `logs/`. `fetchDetails` also reads back from `logs/detail_*.html` if a file already exists — a built-in resume cache. Keep this in mind when re-running: stale `logs/detail_*.html` files will be replayed instead of refetched.
- **Encoding.** Bodies are forced to UTF-8 (`body.force_encoding('utf-8')`) on Ruby ≥ 1.9. Various 1.8-compat branches still exist; new code should target ≥ 1.9.
- **Address-dedup.** `Swissreg::emitCsv` deduplicates rows by `inhaber` — only the first occurrence of each owner ends up in the CSV. This is intentional (verified by `spec/csv_spec.rb`'s "must create a csv file with only one address" test), so don't "fix" it.
- **`spike*.rb`, `swissreg.rb` at the repo root** are historical exploration scripts, not part of the gem. `Manifest.txt` lists them but they aren't loaded.

## Rust port (`rust/`)

```bash
cd rust
cargo build --release
cargo test                                                          # 13 unit tests
./target/release/brand2csv 01.01.2000-04.05.2026 parados            # single search
./target/release/brand2csv 01.01.2000-04.05.2026 parados '*parados*' # merged
./target/release/brand2csv 01.01.2017-29.03.2017 --swiss-only
```

Output goes to `rust/csv/<timespan>.csv` (or `<timespan>_combined.csv` when multiple `marken` are passed). Both `csv/` and `target/` are gitignored.

### Architecture

Four files in `rust/src/`:

- **`main.rs`** — clap CLI, orchestration. Multiple positional `marken` are looped: each runs one `/search` POST; results are merged with URN-based dedup before writing. Above `DETAIL_SOFT_CAP = 200` hits, per-result detail fetches are skipped automatically (the swissreg WAF hard-RSTs the connection on bursts).
- **`api.rs`** — `SwissregClient` (reqwest with cookie store + browser UA). Two endpoints:
  - `POST /database/resources/query/search` with `{target:"chmarke", searchString, filters:{hinterlegungsdatum__type_date:["[<from-iso> TO <to-iso>]"]}, sortByField, sortOrder, pageSize}`. `pageSize` accepts up to ~50000, so we ask for `PAGE_SIZE = 10_000` and don't paginate.
  - `GET /database/resources/ds/<urn>` for `hinterlegungsdatum`. Has retry+backoff. The documented `/fetch?ps=N` continuation endpoint uses encrypted Transit tokens that the WAF blocks for non-browser clients — don't try to use it.
  - `parse_pipe_address` splits the API's pipe-delimited Inhaber string `[id|]name|street|plz town|country_code` (with the optional all-digit `id` prefix detected and skipped).
- **`csv_writer.rs`** — `;`-delimited writer. Columns are emitted in alphabetical order via a `[(header, fn(&Marke) -> &str); 13]` table (single source of truth for header + per-row order). Inhaber-dedup behavior is preserved from Ruby (first occurrence wins).
- **`timespan.rs`** — port of Ruby's `validates_timespan` with the same "Did you mean?" suggestion (rolls invalid days back to the last valid day of the month; rejects out-of-range months). Test cases mirror `spec/brand2csv_spec.rb`.

### Things to know before editing the Rust port

- **WAF rate-limiting is real.** The first burst of 16-concurrent detail fetches against ~4000 hits got our IP RST-blocked for several minutes. Current settings: `DETAIL_CONCURRENCY = 4`, retry-with-backoff in `SwissregClient::detail`, soft-cap at 200 hits. If you see `Connection reset by peer` from `/search`, the WAF caught us — back off, don't retry-storm.
- **Solr `searchString` is fuzzy.** `parados` returns 2 ranked hits; `*parados*` returns 4158 hits across all indexed fields including ones not in the response, so the result set is mostly noise. Don't be surprised by huge counts on bare wildcards.
- **No `hinterlegungsdatum` in `/search` response.** That field only comes from the per-URN detail call. The CSV column will be blank when detail fetches are skipped (auto above 200 hits, or via `--no-details`).
- **`--swiss-only` is a post-hoc filter** on `country == "CH"` from the parsed Inhaber pipe-string. There may be a server-side country filter we haven't found; if needed, capture a country-filtered request from the SPA and add it to the `filters` map.
- **`Cargo.lock` is gitignored.** This is a binary, not a published library — the lockfile would just churn. Reproducible builds happen via the Rust toolchain version.
