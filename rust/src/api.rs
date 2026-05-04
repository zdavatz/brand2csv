use anyhow::{anyhow, Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::timespan::Timespan;

const BASE: &str = "https://www.swissreg.ch";
const SEARCH_PATH: &str = "/database/resources/query/search";
const DETAIL_PATH: &str = "/database/resources/ds/";
const X_IPI_VERSION: &str = "10.0.9";

pub struct SwissregClient {
    http: reqwest::Client,
}

impl SwissregClient {
    pub fn new() -> Result<Self> {
        let http = reqwest::Client::builder()
            .user_agent(
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 \
                 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            )
            .cookie_store(true)
            .build()
            .context("building http client")?;
        Ok(Self { http })
    }

    pub async fn search(
        &self,
        target: &str,
        search_string: &str,
        timespan: &Timespan,
        page_size: u32,
    ) -> Result<SearchResponse> {
        let body = json!({
            "target": target,
            "searchString": search_string,
            "filters": {
                "hinterlegungsdatum__type_date": [date_range_filter(timespan)],
            },
            "sortByField": "hinterlegungsdatum__type_date",
            "sortOrder": "ASC",
            "pageSize": page_size,
        });
        let resp = self
            .http
            .post(format!("{BASE}{SEARCH_PATH}"))
            .header("Content-Type", "application/json")
            .header("X-IPI-VERSION", X_IPI_VERSION)
            .json(&body)
            .send()
            .await
            .context("posting search")?;
        let status = resp.status();
        let text = resp.text().await.context("reading search body")?;
        if !status.is_success() {
            return Err(anyhow!("search returned {}: {}", status, text));
        }
        serde_json::from_str(&text).with_context(|| format!("parsing search JSON: {}", &text[..text.len().min(500)]))
    }

    pub async fn detail(&self, urn: &str) -> Result<Detail> {
        let url = format!("{BASE}{DETAIL_PATH}{urn}");
        let mut last_err: Option<anyhow::Error> = None;
        for attempt in 0..3u32 {
            if attempt > 0 {
                tokio::time::sleep(std::time::Duration::from_millis(500 * (1 << attempt))).await;
            }
            match self
                .http
                .get(&url)
                .header("X-IPI-VERSION", X_IPI_VERSION)
                .header("Accept", "application/json, text/plain, */*")
                .header("Referer", "https://www.swissreg.ch/database-client/")
                .send()
                .await
            {
                Ok(resp) => {
                    let status = resp.status();
                    let text = resp.text().await.unwrap_or_default();
                    if status.is_success() {
                        return serde_json::from_str(&text)
                            .with_context(|| format!("parsing detail {urn}"));
                    }
                    last_err = Some(anyhow!("detail {urn} returned {status}"));
                }
                Err(e) => last_err = Some(anyhow::Error::from(e)),
            }
        }
        Err(last_err.unwrap_or_else(|| anyhow!("detail {urn} unreachable")))
    }
}

fn date_range_filter(t: &Timespan) -> String {
    format!(
        "[{}T00:00:00.000Z TO {}T23:59:59.999Z]",
        t.from.format("%Y-%m-%d"),
        t.to.format("%Y-%m-%d")
    )
}

#[derive(Debug, Deserialize)]
pub struct SearchResponse {
    #[serde(default)]
    pub results: Vec<SearchHit>,
    #[serde(rename = "totalItems", default)]
    pub total_items: u64,
}

/// A search-result row. The API encodes most fields as single-element arrays
/// (Solr multi-value convention), and `ra_inhaber__type_text_mv` is a
/// pipe-delimited string: `[id|]name|street|plz town|country_code`.
#[derive(Debug, Deserialize, Serialize)]
pub struct SearchHit {
    #[serde(rename = "id", default)]
    pub id: Vec<String>,
    #[serde(rename = "doctype", default)]
    pub doctype: Vec<String>,
    #[serde(rename = "markennummer_formatiert__type_string", default)]
    pub markennummer: Vec<String>,
    #[serde(rename = "gesuchsnummer__type_text_split_num", default)]
    pub gesuchsnummer: Vec<String>,
    #[serde(rename = "titel__type_text", default)]
    pub titel: Vec<String>,
    #[serde(rename = "wortbestandteil__type_text", default)]
    pub wortbestandteil: Vec<String>,
    #[serde(rename = "bild_trefferliste_screen_hash__type_string", default)]
    pub image_hash: Vec<String>,
    #[serde(rename = "ra_inhaber__type_text_mv", default)]
    pub inhaber_raw: Vec<String>,
    #[serde(rename = "ra_vertreter__type_text_mv", default)]
    pub vertreter_raw: Vec<String>,
}

impl SearchHit {
    pub fn urn(&self) -> Option<&str> {
        self.id.first().map(|s| s.as_str())
    }

    pub fn brand_text(&self) -> String {
        if let Some(t) = self.titel.first() {
            return t.clone();
        }
        if let Some(w) = self.wortbestandteil.first() {
            return w.clone();
        }
        if let Some(h) = self.image_hash.first() {
            return format!("{BASE}/database/resources/ds/image/urn:ige:img:{h}");
        }
        String::new()
    }
}

#[derive(Debug, Deserialize)]
pub struct Detail {
    #[serde(default)]
    pub hinterlegungsdatum: Option<String>,
}

pub fn parse_pipe_address(raw: &str) -> ParsedAddress {
    let mut parts: Vec<&str> = raw.split('|').collect();
    if parts.first().map_or(false, |p| !p.is_empty() && p.chars().all(|c| c.is_ascii_digit())) {
        parts.remove(0);
    }
    let name = parts.first().copied().unwrap_or("").to_string();
    let street = parts.get(1).copied().unwrap_or("").to_string();
    let plz_town = parts.get(2).copied().unwrap_or("");
    let country = parts.get(3).copied().unwrap_or("").to_string();
    let (plz, ort) = split_plz_town(plz_town);
    ParsedAddress { name, street, plz, ort, country }
}

fn split_plz_town(s: &str) -> (String, String) {
    let s = s.trim();
    if s.is_empty() {
        return (String::new(), String::new());
    }
    if let Some((first, rest)) = s.split_once(' ') {
        if first.chars().any(|c| c.is_ascii_digit()) {
            return (first.to_string(), rest.trim().to_string());
        }
    }
    (String::new(), s.to_string())
}

pub struct ParsedAddress {
    pub name: String,
    pub street: String,
    pub plz: String,
    pub ort: String,
    pub country: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_pipe_with_id() {
        let a = parse_pipe_address("18461112|Kingdom First Trust|2606 N York Hwy, Box 22|TN 38577 Pall Mall|US");
        assert_eq!(a.name, "Kingdom First Trust");
        assert_eq!(a.street, "2606 N York Hwy, Box 22");
        // US-style "TN 38577 Pall Mall": first chunk has no digits, so we
        // can't guess a postcode — keep the whole thing as Ort.
        assert_eq!(a.plz, "");
        assert_eq!(a.ort, "TN 38577 Pall Mall");
        assert_eq!(a.country, "US");
    }

    #[test]
    fn parses_pipe_without_id() {
        let a = parse_pipe_address("Aspectra AG|Weberstrasse 4|8004 Zürich|CH");
        assert_eq!(a.name, "Aspectra AG");
        assert_eq!(a.street, "Weberstrasse 4");
        assert_eq!(a.plz, "8004");
        assert_eq!(a.ort, "Zürich");
        assert_eq!(a.country, "CH");
    }
}
