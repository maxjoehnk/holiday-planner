#[derive(Debug, Clone)]
pub struct WebImage {
    pub id: String,
    pub url: String,
    pub thumbnail_url: String,
    pub author: String,
    pub description: Option<String>,
}
