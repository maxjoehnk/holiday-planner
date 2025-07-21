use serde::{Deserialize, Serialize};

const API_KEY: Option<&str> = option_env!("UNSPLASH_ACCESS_KEY");

#[derive(Debug, Serialize, Deserialize)]
pub struct UnsplashImage {
    pub id: String,
    pub urls: UnsplashUrls,
    pub user: UnsplashUser,
    pub description: Option<String>,
    pub alt_description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnsplashUrls {
    pub raw: String,
    pub full: String,
    pub regular: String,
    pub small: String,
    pub thumb: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnsplashUser {
    pub name: String,
    pub username: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnsplashSearchResponse {
    pub total: u32,
    pub total_pages: u32,
    pub results: Vec<UnsplashImage>,
}

pub async fn search_images(query: &str) -> anyhow::Result<Vec<UnsplashImage>> {
    let Some(api_key) = API_KEY else {
        anyhow::bail!("Missing Unsplash API key");
    };
    let url = format!("https://api.unsplash.com/search/photos?query={query}&per_page=20");
    
    let client = reqwest::Client::new();
    let res = client
        .get(&url)
        .header("Authorization", format!("Client-ID {}", api_key))
        .send()
        .await?;
    
    if !res.status().is_success() {
        return Err(anyhow::anyhow!(
            "Failed to search images: {}",
            res.status()
        ));
    }
    
    let search_response: UnsplashSearchResponse = res.json().await?;
    Ok(search_response.results)
}

pub async fn download_image(url: &str) -> anyhow::Result<Vec<u8>> {
    let res = reqwest::get(url).await?;
    
    if !res.status().is_success() {
        return Err(anyhow::anyhow!(
            "Failed to download image: {}",
            res.status()
        ));
    }
    
    let bytes = res.bytes().await?;
    Ok(bytes.to_vec())
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    #[ignore] // Ignore this test by default as it requires an API key
    async fn test_search_images() {
        let images = search_images("beach").await.unwrap();
        assert!(!images.is_empty());
    }
}
