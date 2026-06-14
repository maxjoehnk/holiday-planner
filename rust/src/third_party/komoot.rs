use anyhow::{anyhow, bail};
use serde::Deserialize;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KomootTourKind {
    Tour,
    SmartTour,
}

impl KomootTourKind {
    fn endpoint_segment(&self) -> &'static str {
        match self {
            KomootTourKind::Tour => "tours",
            KomootTourKind::SmartTour => "discover_tours",
        }
    }

    fn url_segment(&self) -> &'static str {
        match self {
            KomootTourKind::Tour => "tour",
            KomootTourKind::SmartTour => "smarttour",
        }
    }
}

#[derive(Debug, Clone)]
pub struct KomootTourRef {
    pub kind: KomootTourKind,
    pub id: String,
}

#[derive(Debug, Clone)]
pub struct KomootTour {
    pub id: String,
    pub kind: KomootTourKind,
    pub name: String,
    pub sport: Option<String>,
    pub distance_meters: f64,
    pub duration_seconds: i64,
    pub elevation_up_meters: Option<f64>,
    pub elevation_down_meters: Option<f64>,
    pub coordinates: Vec<KomootCoordinate>,
}

#[derive(Debug, Clone, Copy)]
pub struct KomootCoordinate {
    pub latitude: f64,
    pub longitude: f64,
    pub altitude: Option<f64>,
}

pub fn tour_url(tour_ref: &KomootTourRef) -> String {
    format!(
        "https://www.komoot.com/{}/{}",
        tour_ref.kind.url_segment(),
        tour_ref.id
    )
}

/// Parse a Komoot tour reference from a shared URL.
///
/// Accepts both `komoot.com` and `komoot.de` hosts, with or without locale prefix
/// (`/en-us/`, `/de-de/`, etc.), and both `/tour/<id>` and `/smarttour/<id>` paths.
/// Tour ids are numeric; smarttour ids may also include an alphabetic prefix
/// (e.g. `e1216430880`).
pub fn parse_tour_ref(url: &str) -> Option<KomootTourRef> {
    if !url.contains("komoot.") {
        return None;
    }
    let (kind, id) = if let Some(idx) = url.find("/smarttour/") {
        (KomootTourKind::SmartTour, &url[idx + "/smarttour/".len()..])
    } else if let Some(idx) = url.find("/tour/") {
        (KomootTourKind::Tour, &url[idx + "/tour/".len()..])
    } else {
        return None;
    };
    let id: String = id
        .chars()
        .take_while(|c| c.is_ascii_alphanumeric())
        .collect();
    if id.is_empty() {
        return None;
    }
    match kind {
        KomootTourKind::Tour if !id.chars().all(|c| c.is_ascii_digit()) => return None,
        _ => {}
    }
    Some(KomootTourRef { kind, id })
}

pub async fn fetch_tour(tour_ref: &KomootTourRef) -> anyhow::Result<KomootTour> {
    let url = format!(
        "https://api.komoot.de/v007/{}/{}?_embedded=coordinates&hl=en",
        tour_ref.kind.endpoint_segment(),
        tour_ref.id
    );
    let res = reqwest::get(&url).await?;
    let status = res.status();
    if status == reqwest::StatusCode::FORBIDDEN || status == reqwest::StatusCode::NOT_FOUND {
        bail!("Tour is private or unavailable");
    }
    if !status.is_success() {
        bail!("Komoot API returned {status}");
    }
    let body: ApiTour = res.json().await?;
    body.try_into_tour(tour_ref.clone())
}

#[derive(Debug, Deserialize)]
struct ApiTour {
    name: String,
    sport: Option<String>,
    #[serde(default)]
    distance: Option<f64>,
    #[serde(default)]
    duration: Option<i64>,
    #[serde(default)]
    elevation_up: Option<f64>,
    #[serde(default)]
    elevation_down: Option<f64>,
    #[serde(rename = "_embedded")]
    embedded: Option<ApiEmbedded>,
}

#[derive(Debug, Deserialize)]
struct ApiEmbedded {
    coordinates: Option<ApiCoordinates>,
}

#[derive(Debug, Deserialize)]
struct ApiCoordinates {
    items: Vec<ApiCoordinate>,
}

#[derive(Debug, Deserialize)]
struct ApiCoordinate {
    lat: f64,
    lng: f64,
    #[serde(default)]
    alt: Option<f64>,
}

impl ApiTour {
    fn try_into_tour(self, tour_ref: KomootTourRef) -> anyhow::Result<KomootTour> {
        let embedded = self
            .embedded
            .ok_or_else(|| anyhow!("Komoot tour response missing _embedded section"))?;
        let coordinates = embedded
            .coordinates
            .ok_or_else(|| anyhow!("Komoot tour has no coordinates"))?;
        let coordinates = coordinates
            .items
            .into_iter()
            .map(|c| KomootCoordinate {
                latitude: c.lat,
                longitude: c.lng,
                altitude: c.alt,
            })
            .collect::<Vec<_>>();
        if coordinates.is_empty() {
            bail!("Komoot tour returned empty coordinate list");
        }
        Ok(KomootTour {
            id: tour_ref.id,
            kind: tour_ref.kind,
            name: self.name,
            sport: self.sport,
            distance_meters: self.distance.unwrap_or(0.0),
            duration_seconds: self.duration.unwrap_or(0),
            elevation_up_meters: self.elevation_up,
            elevation_down_meters: self.elevation_down,
            coordinates,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parsed(url: &str) -> Option<(KomootTourKind, String)> {
        parse_tour_ref(url).map(|r| (r.kind, r.id))
    }

    #[test]
    fn parse_tour_plain() {
        assert_eq!(
            parsed("https://www.komoot.com/tour/123456"),
            Some((KomootTourKind::Tour, "123456".to_string()))
        );
    }

    #[test]
    fn parse_tour_locale_prefix() {
        assert_eq!(
            parsed("https://www.komoot.com/en-us/tour/987654321"),
            Some((KomootTourKind::Tour, "987654321".to_string()))
        );
    }

    #[test]
    fn parse_tour_with_query_string() {
        assert_eq!(
            parsed("https://www.komoot.com/tour/42?ref=share"),
            Some((KomootTourKind::Tour, "42".to_string()))
        );
    }

    #[test]
    fn parse_tour_with_trailing_path() {
        assert_eq!(
            parsed("https://www.komoot.com/tour/7/details"),
            Some((KomootTourKind::Tour, "7".to_string()))
        );
    }

    #[test]
    fn parse_smarttour_komoot_de() {
        assert_eq!(
            parsed("https://www.komoot.de/smarttour/42935081?ref=atd"),
            Some((KomootTourKind::SmartTour, "42935081".to_string()))
        );
    }

    #[test]
    fn parse_smarttour_with_alpha_id_and_slug() {
        assert_eq!(
            parsed("https://www.komoot.com/smarttour/e1216430880/the-three-lakes-loop"),
            Some((KomootTourKind::SmartTour, "e1216430880".to_string()))
        );
    }

    #[test]
    fn parse_smarttour_locale_prefix() {
        assert_eq!(
            parsed("https://www.komoot.com/de-de/smarttour/42935081"),
            Some((KomootTourKind::SmartTour, "42935081".to_string()))
        );
    }

    #[test]
    fn parse_garbage_returns_none() {
        assert!(parsed("https://example.com/foo").is_none());
        assert!(parsed("not a url").is_none());
        // /tour/ requires numeric id
        assert!(parsed("https://www.komoot.com/tour/abc").is_none());
    }
}
