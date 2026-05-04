use anyhow::Result;
use std::collections::HashSet;
use std::path::Path;

#[derive(Debug, Clone)]
pub struct Marke {
    pub name: String,
    pub markennummer: String,
    pub inhaber: String,
    pub land: String,
    pub hat_vertreter: String,
    pub hinterlegungsdatum: String,
    pub zeile_1: String,
    pub zeile_2: String,
    pub zeile_3: String,
    pub zeile_4: String,
    pub zeile_5: String,
    pub plz: String,
    pub ort: String,
}

/// Columns are emitted in alphabetical order (case-insensitive). The accessor
/// pairs here are the single source of truth for both header and row order.
fn columns() -> [(&'static str, fn(&Marke) -> &str); 13] {
    let mut cols: [(&'static str, fn(&Marke) -> &str); 13] = [
        ("hatVertreter", |m| &m.hat_vertreter),
        ("hinterlegungsdatum", |m| &m.hinterlegungsdatum),
        ("inhaber", |m| &m.inhaber),
        ("land", |m| &m.land),
        ("markennummer", |m| &m.markennummer),
        ("name", |m| &m.name),
        ("ort", |m| &m.ort),
        ("plz", |m| &m.plz),
        ("zeile_1", |m| &m.zeile_1),
        ("zeile_2", |m| &m.zeile_2),
        ("zeile_3", |m| &m.zeile_3),
        ("zeile_4", |m| &m.zeile_4),
        ("zeile_5", |m| &m.zeile_5),
    ];
    cols.sort_by(|a, b| a.0.to_ascii_lowercase().cmp(&b.0.to_ascii_lowercase()));
    cols
}

/// Mirrors Ruby's Swissreg::emitCsv: ; separator, dedup by `inhaber`
/// keeping the first occurrence. Columns are written in alphabetical order.
pub fn write_csv<P: AsRef<Path>>(path: P, marken: &[Marke]) -> Result<()> {
    let mut wtr = csv::WriterBuilder::new()
        .delimiter(b';')
        .has_headers(false)
        .from_path(path)?;
    let cols = columns();
    wtr.write_record(cols.iter().map(|(h, _)| *h))?;
    let mut seen: HashSet<&str> = HashSet::new();
    for m in marken {
        if !seen.insert(m.inhaber.as_str()) {
            continue;
        }
        wtr.write_record(cols.iter().map(|(_, get)| get(m)))?;
    }
    wtr.flush()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    fn sample(suffix: &str) -> Marke {
        Marke {
            name: format!("M{suffix}"),
            markennummer: format!("0832{suffix}/2000"),
            inhaber: "Aspectra AG, Weberstrasse 4, 8004 Zürich".into(),
            land: "Schweiz".into(),
            hat_vertreter: "Nein".into(),
            hinterlegungsdatum: "01.01.2000".into(),
            zeile_1: "Aspectra AG".into(),
            zeile_2: "Weberstrasse 4".into(),
            zeile_3: String::new(),
            zeile_4: String::new(),
            zeile_5: String::new(),
            plz: "8004".into(),
            ort: "Zürich".into(),
        }
    }

    #[test]
    fn dedups_by_inhaber() {
        let tmp = std::env::temp_dir().join("brand2csv_dedup.csv");
        write_csv(&tmp, &[sample("6"), sample("7")]).unwrap();
        let body = fs::read_to_string(&tmp).unwrap();
        let lines: Vec<&str> = body.lines().collect();
        assert_eq!(lines.len(), 2, "header + 1 deduped row, got: {body}");
        assert!(lines[1].contains("08326/2000"), "first inhaber wins");
        fs::remove_file(&tmp).ok();
    }

    #[test]
    fn header_is_alphabetical() {
        let tmp = std::env::temp_dir().join("brand2csv_alpha.csv");
        write_csv(&tmp, &[sample("9")]).unwrap();
        let body = fs::read_to_string(&tmp).unwrap();
        let header = body.lines().next().unwrap();
        assert_eq!(
            header,
            "hatVertreter;hinterlegungsdatum;inhaber;land;markennummer;name;ort;plz;zeile_1;zeile_2;zeile_3;zeile_4;zeile_5"
        );
        fs::remove_file(&tmp).ok();
    }
}
