use anyhow::{Context, Result};
use clap::Parser;
use futures::stream::StreamExt;
use std::collections::HashSet;
use std::sync::Arc;

mod api;
mod csv_writer;
mod timespan;

use api::{parse_pipe_address, SearchHit, SwissregClient};
use csv_writer::{write_csv, Marke};
use timespan::{validate, ValidateOutcome};

const PAGE_SIZE: u32 = 10_000;
const DETAIL_CONCURRENCY: usize = 4;
/// Above this many hits, skip per-result detail fetches by default — the
/// swissreg WAF starts dropping connections at higher volumes.
const DETAIL_SOFT_CAP: usize = 200;

#[derive(Parser, Debug)]
#[command(
    name = "brand2csv",
    version,
    about = "Find Swiss trademarks registered during a timespan and write them to csv/<timespan>.csv"
)]
struct Args {
    /// Timespan: dd.mm.yyyy or dd.mm.yyyy-dd.mm.yyyy
    timespan: String,

    /// Brand filters (Solr syntax). Pass multiple to merge several searches
    /// into a single deduped CSV (e.g. `parados '*parados*'`).
    marken: Vec<String>,

    /// Restrict to owners domiciled in Switzerland
    #[arg(long = "swiss-only", alias = "swiss_only")]
    swiss_only: bool,

    /// Skip the per-hit detail fetch (Hinterlegungsdatum column will be empty)
    #[arg(long = "no-details")]
    no_details: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let timespan = match validate(&args.timespan) {
        ValidateOutcome::Ok(t) => t,
        ValidateOutcome::DidYouMean(msg) => {
            println!("{msg}");
            std::process::exit(1);
        }
        ValidateOutcome::Invalid => {
            println!("Timespan is invalid");
            std::process::exit(1);
        }
    };

    let patterns: Vec<String> = if args.marken.is_empty() {
        vec!["*".to_string()]
    } else {
        args.marken.clone()
    };

    let client = Arc::new(SwissregClient::new()?);

    let mut hits: Vec<SearchHit> = Vec::new();
    let mut seen_urns: HashSet<String> = HashSet::new();
    for pattern in &patterns {
        let resp = client
            .search("chmarke", pattern, &timespan, PAGE_SIZE)
            .await
            .with_context(|| format!("searching swissreg for {pattern:?}"))?;
        println!(
            "Pattern {:?}: {} hits ({} in page).",
            pattern,
            resp.total_items,
            resp.results.len()
        );
        if (resp.results.len() as u64) < resp.total_items {
            eprintln!(
                "warning: pattern {:?} returned {} of {} hits — pageSize cap reached.",
                pattern,
                resp.results.len(),
                resp.total_items
            );
        }
        for h in resp.results {
            let urn = h.urn().unwrap_or("").to_string();
            if urn.is_empty() || seen_urns.insert(urn) {
                hits.push(h);
            }
        }
    }

    if args.swiss_only {
        hits.retain(|h| {
            h.inhaber_raw
                .first()
                .map(|raw| parse_pipe_address(raw).country == "CH")
                .unwrap_or(false)
        });
    }

    let marken = if args.no_details || hits.len() > DETAIL_SOFT_CAP {
        if !args.no_details && hits.len() > DETAIL_SOFT_CAP {
            eprintln!(
                "Skipping per-hit detail fetch ({} hits > soft cap of {}) — \
                 hinterlegungsdatum will be empty. Pass a narrower timespan \
                 to enable detail fetching.",
                hits.len(),
                DETAIL_SOFT_CAP
            );
        }
        hits.into_iter().map(|h| build_marke(&h, None)).collect::<Vec<_>>()
    } else {
        fetch_with_details(client.clone(), hits).await
    };

    let dir = std::path::Path::new("csv");
    std::fs::create_dir_all(dir).with_context(|| format!("creating {}", dir.display()))?;
    let stem = if patterns.len() > 1 || args.marken.len() > 1 {
        format!("{}_combined", args.timespan)
    } else {
        args.timespan.clone()
    };
    let filename = dir.join(format!("{stem}.csv"));
    write_csv(&filename, &marken).with_context(|| format!("writing {}", filename.display()))?;
    println!("Wrote {} rows to {}.", marken.len(), filename.display());
    Ok(())
}

async fn fetch_with_details(client: Arc<SwissregClient>, hits: Vec<SearchHit>) -> Vec<Marke> {
    let stream = futures::stream::iter(hits.into_iter().enumerate().map(|(idx, hit)| {
        let client = client.clone();
        async move {
            let detail = match hit.urn() {
                Some(urn) => client.detail(urn).await.map_err(|e| {
                    eprintln!("warn: detail fetch failed for {urn}: {e}");
                    e
                }).ok(),
                None => None,
            };
            (idx, build_marke(&hit, detail.as_ref()))
        }
    }));
    let mut collected: Vec<(usize, Marke)> = stream
        .buffer_unordered(DETAIL_CONCURRENCY)
        .collect()
        .await;
    collected.sort_by_key(|(i, _)| *i);
    collected.into_iter().map(|(_, m)| m).collect()
}

fn build_marke(hit: &SearchHit, detail: Option<&api::Detail>) -> Marke {
    let inhaber_raw = hit.inhaber_raw.first().cloned().unwrap_or_default();
    let addr = parse_pipe_address(&inhaber_raw);
    let inhaber_joined = [
        addr.name.as_str(),
        addr.street.as_str(),
        format!("{} {}", addr.plz, addr.ort).trim(),
    ]
    .iter()
    .filter(|s| !s.is_empty())
    .copied()
    .collect::<Vec<_>>()
    .join(", ");

    let land = match addr.country.as_str() {
        "CH" => "Schweiz".to_string(),
        other if !other.is_empty() => other.to_string(),
        _ => String::new(),
    };

    let hat_vertreter = if hit.vertreter_raw.first().map_or(false, |s| !s.is_empty()) {
        "Ja"
    } else {
        "Nein"
    };

    let hinterlegungsdatum = detail.and_then(|d| d.hinterlegungsdatum.clone()).unwrap_or_default();

    let markennummer = hit
        .gesuchsnummer
        .first()
        .cloned()
        .or_else(|| hit.markennummer.first().cloned())
        .unwrap_or_default();

    Marke {
        name: hit.brand_text(),
        markennummer,
        inhaber: inhaber_joined,
        land,
        hat_vertreter: hat_vertreter.to_string(),
        hinterlegungsdatum,
        zeile_1: addr.name,
        zeile_2: addr.street,
        zeile_3: String::new(),
        zeile_4: String::new(),
        zeile_5: String::new(),
        plz: addr.plz,
        ort: addr.ort,
    }
}
