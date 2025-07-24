use uuid::Uuid;
use crate::models::ParsedTrainJourney;

#[derive(Debug)]
pub struct ImportParsedTrainJourney {
    pub trip_id: Uuid,
    pub journey: ParsedTrainJourney,
}
