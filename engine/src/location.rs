// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Location messages: one point, sent as an ordinary encrypted Matrix
//! location message ("geo:" address). The phone never asks a map server
//! about it; opening a map is the reader's own choice.

/// Accuracy is capped so a silly value can't break the screen.
const MAX_ACCURACY: f64 = 100_000.0;

/// The canonical "geo:" address for a point, or None if it is not a real
/// place on Earth.
pub fn geo_uri(lat: f64, lon: f64, accuracy: Option<f64>) -> Option<String> {
    if !(lat.is_finite()
        && lon.is_finite()
        && (-90.0..=90.0).contains(&lat)
        && (-180.0..=180.0).contains(&lon))
    {
        return None;
    }
    let mut s = format!("geo:{lat:.6},{lon:.6}");
    if let Some(a) = accuracy.filter(|a| a.is_finite() && *a > 0.0) {
        s.push_str(&format!(";u={:.0}", a.min(MAX_ACCURACY).max(1.0)));
    }
    Some(s)
}

/// Reads a received "geo:" address (from anyone), keeping only a valid
/// point; the result is always in our own canonical form.
pub fn parse(uri: &str) -> Option<String> {
    let rest = uri.trim().strip_prefix("geo:")?;
    let mut parts = rest.split(';');
    let mut nums = parts.next()?.split(',');
    let lat: f64 = nums.next()?.trim().parse().ok()?;
    let lon: f64 = nums.next()?.trim().parse().ok()?;
    let acc = parts.find_map(|p| p.trim().strip_prefix("u=")?.parse::<f64>().ok());
    geo_uri(lat, lon, acc)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_real_points_pass() {
        assert_eq!(
            geo_uri(37.5665, 126.978, Some(12.4)).as_deref(),
            Some("geo:37.566500,126.978000;u=12")
        );
        assert_eq!(geo_uri(91.0, 0.0, None), None);
        assert_eq!(geo_uri(f64::NAN, 0.0, None), None);
        assert_eq!(
            parse("geo:37.5,127.0;u=1e30").as_deref(),
            Some("geo:37.500000,127.000000;u=100000")
        );
        assert_eq!(
            parse("geo:37.5,127.0,30;crs=wgs84").as_deref(),
            Some("geo:37.500000,127.000000")
        );
        assert_eq!(parse("geo:abc,1"), None);
        assert_eq!(parse("https://evil.example"), None);
        assert_eq!(
            parse("geo:-33.9,151.2").as_deref(),
            Some("geo:-33.900000,151.200000")
        );
    }
}
