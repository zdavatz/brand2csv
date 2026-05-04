# brand2csv

[![Build Status](https://secure.travis-ci.org/zdavatz/brand2csv.png)](http://travis-ci.org/zdavatz/brand2csv)

brand2csv uses swissreg.ch to fetch Swiss trademark registrations and write them to CSV.

## Two implementations

* **Ruby gem** (this directory) — original. Targets the legacy JSF UI at `swissreg.ch/srclient/...` which is no longer reachable; kept as historical reference.
* **Rust port** (`rust/`) — current. Targets the live SPA JSON API at `swissreg.ch/database/resources/...`.

The Rust port is the one to use.

## Rust usage

```
cd rust
cargo build --release
./target/release/brand2csv <timespan> [marke ...]
```

`<timespan>` is `dd.mm.yyyy` or `dd.mm.yyyy-dd.mm.yyyy`. Each `marke` is a Solr search string (e.g. `parados`, `*parados*`). Pass several to merge multiple searches into one deduped CSV.

```
./target/release/brand2csv 01.01.2013 'b*'
./target/release/brand2csv 1.10.2005-31.10.2005
./target/release/brand2csv 01.01.2000-04.05.2026 parados '*parados*'   # merged
./target/release/brand2csv 01.01.2017-29.03.2017 --swiss-only          # owners in CH only
```

Results land in `csv/<timespan>.csv` (or `csv/<timespan>_combined.csv` when merging multiple patterns). Columns are emitted in alphabetical order.

### Flags

* `--swiss-only` — keep only owners with country `CH`.
* `--no-details` — skip the per-hit detail fetch; `hinterlegungsdatum` will be empty but the run is much faster. Auto-applied when a search returns more than 200 hits, since the swissreg WAF rate-limits bursts of detail fetches.

## Ruby usage (legacy)

```
brand2csv 01.01.2013 "b*"
brand2csv 1.10.2005-31.10.2005
```

The Ruby implementation no longer functions against the live site.
