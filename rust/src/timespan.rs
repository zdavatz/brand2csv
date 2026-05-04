use chrono::NaiveDate;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Timespan {
    pub from: NaiveDate,
    pub to: NaiveDate,
}

#[derive(Debug, PartialEq, Eq)]
pub enum ValidateOutcome {
    Ok(Timespan),
    DidYouMean(String),
    Invalid,
}

pub fn validate(arg: &str) -> ValidateOutcome {
    let cleaned: String = arg.chars().filter(|c| c.is_ascii_digit() || *c == '.' || *c == '-').collect();
    let parts: Vec<&str> = cleaned.split('-').collect();
    if parts.is_empty() || parts.len() > 2 {
        return ValidateOutcome::Invalid;
    }

    let mut all_valid = true;
    let mut suggestion = String::new();
    let mut parsed: Vec<NaiveDate> = Vec::with_capacity(parts.len());

    for (i, raw) in parts.iter().enumerate() {
        if i > 0 {
            suggestion.push('-');
        }
        match parse_dmy(raw) {
            Some(d) => {
                parsed.push(d);
                suggestion.push_str(&format_dmy(d));
            }
            None => {
                all_valid = false;
                match coerce_last_day_of_month(raw) {
                    Some(d) => {
                        parsed.push(d);
                        suggestion.push_str(&format_dmy(d));
                    }
                    None => return ValidateOutcome::Invalid,
                }
            }
        }
    }

    if all_valid {
        let from = parsed[0];
        let to = *parsed.last().unwrap();
        ValidateOutcome::Ok(Timespan { from, to })
    } else {
        ValidateOutcome::DidYouMean(format!("Did you mean {} ?", suggestion))
    }
}

fn parse_dmy(s: &str) -> Option<NaiveDate> {
    let bits: Vec<&str> = s.split('.').collect();
    if bits.len() != 3 {
        return None;
    }
    let day: u32 = bits[0].parse().ok()?;
    let month: u32 = bits[1].parse().ok()?;
    let year: i32 = bits[2].parse().ok()?;
    NaiveDate::from_ymd_opt(year, month, day)
}

fn coerce_last_day_of_month(s: &str) -> Option<NaiveDate> {
    let bits: Vec<&str> = s.split('.').collect();
    if bits.len() != 3 {
        return None;
    }
    let month: u32 = bits[1].parse().ok()?;
    let year: i32 = bits[2].parse().ok()?;
    if !(1..=12).contains(&month) {
        return None;
    }
    let first_next = if month == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1)?
    } else {
        NaiveDate::from_ymd_opt(year, month + 1, 1)?
    };
    Some(first_next.pred_opt()?)
}

fn format_dmy(d: NaiveDate) -> String {
    d.format("%d.%m.%Y").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn invalid(s: &str) -> bool {
        matches!(validate(s), ValidateOutcome::Invalid)
    }
    fn dym(s: &str) -> Option<String> {
        if let ValidateOutcome::DidYouMean(m) = validate(s) {
            Some(m)
        } else {
            None
        }
    }
    fn ok(s: &str) -> Option<Timespan> {
        if let ValidateOutcome::Ok(t) = validate(s) {
            Some(t)
        } else {
            None
        }
    }

    #[test]
    fn single_invalid_last_day_of_month() {
        assert_eq!(dym("29.02.2010").as_deref(), Some("Did you mean 28.02.2010 ?"));
    }

    #[test]
    fn single_invalid_month() {
        assert!(invalid("28.13.2010"));
    }

    #[test]
    fn single_valid() {
        let t = ok("31.12.2010").unwrap();
        assert_eq!(t.from, NaiveDate::from_ymd_opt(2010, 12, 31).unwrap());
        assert_eq!(t.to, t.from);
    }

    #[test]
    fn range_invalid_start_day() {
        assert_eq!(
            dym("29.02.2010-31.03.2010").as_deref(),
            Some("Did you mean 28.02.2010-31.03.2010 ?")
        );
    }

    #[test]
    fn range_invalid_end_day() {
        assert_eq!(
            dym("28.04.2010-99.03.2010").as_deref(),
            Some("Did you mean 28.04.2010-31.03.2010 ?")
        );
    }

    #[test]
    fn range_invalid_both_days() {
        assert_eq!(
            dym("32.01.2010-99.05.2010").as_deref(),
            Some("Did you mean 31.01.2010-31.05.2010 ?")
        );
    }

    #[test]
    fn range_invalid_start_month() {
        assert!(invalid("31.99.2010-31.05.2010"));
    }

    #[test]
    fn range_invalid_end_month() {
        assert!(invalid("31.01.2010-31.20.2010"));
    }

    #[test]
    fn range_valid() {
        let t = ok("28.02.2010-31.05.2010").unwrap();
        assert_eq!(t.from, NaiveDate::from_ymd_opt(2010, 2, 28).unwrap());
        assert_eq!(t.to, NaiveDate::from_ymd_opt(2010, 5, 31).unwrap());
    }
}
