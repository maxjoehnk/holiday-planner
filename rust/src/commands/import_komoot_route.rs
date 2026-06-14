use uuid::Uuid;

#[derive(Debug)]
pub struct ImportKomootRoute {
    pub trip_id: Uuid,
    pub tour_url: String,
}
