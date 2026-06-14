use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::Coordinate;

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum RouteProvider {
    Komoot,
}

impl From<crate::database::entities::route::RouteProvider> for RouteProvider {
    fn from(provider: crate::database::entities::route::RouteProvider) -> Self {
        match provider {
            crate::database::entities::route::RouteProvider::Komoot => RouteProvider::Komoot,
        }
    }
}

impl From<RouteProvider> for crate::database::entities::route::RouteProvider {
    fn from(provider: RouteProvider) -> Self {
        match provider {
            RouteProvider::Komoot => Self::Komoot,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoutePoint {
    pub coordinate: Coordinate,
    pub altitude: Option<f64>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RouteModel {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub provider: RouteProvider,
    pub provider_route_id: String,
    pub name: String,
    pub sport: Option<String>,
    pub distance_meters: f64,
    pub duration_seconds: i64,
    pub elevation_up_meters: Option<f64>,
    pub elevation_down_meters: Option<f64>,
    pub start_coordinate: Coordinate,
    pub polyline: Vec<RoutePoint>,
    pub note: Option<String>,
    pub external_url: String,
}
