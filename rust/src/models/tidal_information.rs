use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
pub enum TideType {
    High,
    Low
}

impl From<TideType> for crate::database::entities::tidal_information::Tide {
    fn from(tide_type: TideType) -> Self {
        match tide_type {
            TideType::High => Self::High,
            TideType::Low => Self::Low,
        }
    }
}

impl From<crate::database::entities::tidal_information::Tide> for TideType {
    fn from(tide: crate::database::entities::tidal_information::Tide) -> Self {
        match tide {
            crate::database::entities::tidal_information::Tide::High => Self::High,
            crate::database::entities::tidal_information::Tide::Low => Self::Low,
        }
    }
}

#[derive(Debug, Clone)]
pub struct TidalInformation {
    pub date: DateTime<Utc>,
    pub height: f64,
    pub tide: TideType,
}
