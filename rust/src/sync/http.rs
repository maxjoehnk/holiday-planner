//! Hand-rolled PostgREST client.
//!
//! `supabase-lib-rs` v0.5 builds its HTTP client once with the anon key as
//! the default `Authorization` header and never re-injects the user's JWT
//! on subsequent requests, so every authenticated PostgREST call reaches
//! the server as the anonymous role and trips RLS. Until the library is
//! fixed (or replaced), we go direct via `reqwest`.

use std::sync::OnceLock;
use std::time::Duration;

use anyhow::{anyhow, Context};
use reqwest::{header, Client as HttpClient, StatusCode};
use serde::Serialize;
use serde_json::Value;

use crate::sync::session;

const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

fn http() -> &'static HttpClient {
    static CLIENT: OnceLock<HttpClient> = OnceLock::new();
    CLIENT.get_or_init(|| {
        HttpClient::builder()
            .timeout(REQUEST_TIMEOUT)
            .build()
            .expect("failed to build PostgREST client")
    })
}

struct AuthCtx {
    url: String,
    anon_key: String,
    jwt: String,
}

async fn auth_ctx() -> anyhow::Result<AuthCtx> {
    let url = session::supabase_url()
        .await
        .ok_or_else(|| anyhow!("Supabase URL not configured"))?;
    let anon_key = session::anon_key()
        .await
        .ok_or_else(|| anyhow!("Supabase anon key not configured"))?;
    let jwt = session::access_token()
        .await
        .ok_or_else(|| anyhow!("Not signed in"))?;
    Ok(AuthCtx { url, anon_key, jwt })
}

/// POST a fresh row. Returns `Ok(true)` on success and `Ok(false)` on
/// PK conflict (`23505`). The push pipeline uses this as the fallback
/// when a conditional PATCH found no live row to update: a duplicate-key
/// here means the server has a tombstone for the same PK, so the local
/// non-delete write should be dropped rather than resurrect the row.
pub async fn insert<T: Serialize>(table: &str, payload: &T) -> anyhow::Result<bool> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{table}", ctx.url);
    let resp = http()
        .post(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header(header::CONTENT_TYPE, "application/json")
        .header("Prefer", "return=minimal")
        .json(payload)
        .send()
        .await
        .with_context(|| format!("POST {url}"))?;
    let status = resp.status();
    if status.is_success() || status == StatusCode::NO_CONTENT {
        return Ok(true);
    }
    let body = resp.text().await.unwrap_or_default();
    if status == StatusCode::CONFLICT && body.contains("\"code\":\"23505\"") {
        return Ok(false);
    }
    Err(anyhow!("PostgREST insert {table}: {status} {body}"))
}

/// Patch the row identified by `id` with the given JSON document. Used
/// for soft-deletes where we set `deleted_at`/`updated_at`.
pub async fn patch_by_id(table: &str, id: &str, patch: &Value) -> anyhow::Result<()> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{table}", ctx.url);
    let resp = http()
        .patch(&url)
        .query(&[("id", &format!("eq.{id}"))])
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header(header::CONTENT_TYPE, "application/json")
        .header("Prefer", "return=minimal")
        .json(patch)
        .send()
        .await
        .with_context(|| format!("PATCH {url}"))?;
    expect_success(table, "patch", resp).await
}

/// DELETE the row identified by `id`. Used by the owner-hard-delete
/// path for trips; cascades on the server take care of the subtree.
pub async fn delete_by_id(table: &str, id: &str) -> anyhow::Result<()> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{table}", ctx.url);
    let resp = http()
        .delete(&url)
        .query(&[("id", &format!("eq.{id}"))])
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header("Prefer", "return=minimal")
        .send()
        .await
        .with_context(|| format!("DELETE {url}"))?;
    expect_success(table, "delete", resp).await
}

/// PATCH against an arbitrary PostgREST query string and return the
/// number of rows that matched. Uses `Prefer: return=representation` so
/// PostgREST echoes the updated rows; the array length is the count.
/// The push pipeline uses this to detect when a conditional update
/// silently no-ops because the filter rejected the row (e.g. it was
/// soft-deleted server-side).
pub async fn patch_query_returning(query: &str, patch: &Value) -> anyhow::Result<usize> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{query}", ctx.url);
    let resp = http()
        .patch(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header(header::CONTENT_TYPE, "application/json")
        .header("Prefer", "return=representation")
        .json(patch)
        .send()
        .await
        .with_context(|| format!("PATCH {url}"))?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("PostgREST patch_query_returning {query}: {status} {body}"));
    }
    let rows: Vec<Value> = resp
        .json()
        .await
        .with_context(|| format!("decode PATCH {query} response"))?;
    Ok(rows.len())
}

/// PATCH against an arbitrary PostgREST query string (e.g.
/// `"trip_members?trip_id=eq.<u>&user_id=eq.<u>"`). Used when the
/// row's primary key isn't a single `id` column.
pub async fn patch_by_query(query: &str, patch: &Value) -> anyhow::Result<()> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{query}", ctx.url);
    let resp = http()
        .patch(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header(header::CONTENT_TYPE, "application/json")
        .header("Prefer", "return=minimal")
        .json(patch)
        .send()
        .await
        .with_context(|| format!("PATCH {url}"))?;
    expect_success(query, "patch", resp).await
}

/// Call a PostgREST RPC (`POST /rest/v1/rpc/<name>`).
pub async fn rpc(name: &str, payload: &Value) -> anyhow::Result<Value> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/rpc/{name}", ctx.url);
    let resp = http()
        .post(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header(header::CONTENT_TYPE, "application/json")
        .json(payload)
        .send()
        .await
        .with_context(|| format!("POST {url}"))?;
    let status = resp.status();
    if !status.is_success() {
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("rpc {name}: {status} {body}"));
    }
    let json: Value = resp.json().await.with_context(|| format!("decode {name} response"))?;
    Ok(json)
}

/// Run a `GET /rest/v1/<query>` request and decode the JSON array
/// response. Used for one-off reads where the caller already knows the
/// filter / order it needs (`"trip_invites?trip_id=eq.<u>"`, etc.).
pub async fn select(query: &str) -> anyhow::Result<Vec<Value>> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{query}", ctx.url);
    let resp = http()
        .get(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .send()
        .await
        .with_context(|| format!("GET {url}"))?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("PostgREST select {query}: {status} {body}"));
    }
    resp.json().await.with_context(|| format!("decode {query} rows"))
}

/// Select all rows whose `column` is greater than `value`. Used by the
/// pull pipeline with `updated_at`.
pub async fn select_gt(table: &str, column: &str, value: &str) -> anyhow::Result<Vec<Value>> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/rest/v1/{table}", ctx.url);
    let resp = http()
        .get(&url)
        .query(&[
            ("select", "*"),
            (column, &format!("gt.{value}")),
            ("order", &format!("{column}.asc")),
        ])
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .send()
        .await
        .with_context(|| format!("GET {url}"))?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("PostgREST select {table}: {status} {body}"));
    }
    resp.json().await.with_context(|| format!("decode {table} rows"))
}

async fn expect_success(table: &str, op: &str, resp: reqwest::Response) -> anyhow::Result<()> {
    let status = resp.status();
    if status.is_success() || status == StatusCode::NO_CONTENT {
        return Ok(());
    }
    let body = resp.text().await.unwrap_or_default();
    Err(anyhow!("PostgREST {op} {table}: {status} {body}"))
}

// =====================================================================
// Supabase Storage
// =====================================================================
//
// Same auth situation as PostgREST — supabase-lib-rs's storage module
// uses the anon-key-default HttpClient, so we go direct.
//
// Endpoints follow the documented REST contract:
//   POST   /storage/v1/object/<bucket>/<path>   — upload (raw body)
//   GET    /storage/v1/object/<bucket>/<path>   — download (returns bytes)
//   DELETE /storage/v1/object/<bucket>/<path>   — remove

/// Upload `body` to `<bucket>/<path>`. Uses `x-upsert: true` so retries
/// after partial failure or content edits replace the object cleanly.
pub async fn storage_upload(
    bucket: &str,
    path: &str,
    content_type: &str,
    body: Vec<u8>,
) -> anyhow::Result<()> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/storage/v1/object/{bucket}/{path}", ctx.url);
    let resp = http()
        .post(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .header(header::CONTENT_TYPE, content_type)
        .header("x-upsert", "true")
        .body(body)
        .send()
        .await
        .with_context(|| format!("POST {url}"))?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("storage upload {bucket}/{path}: {status} {body}"));
    }
    Ok(())
}

pub async fn storage_download(bucket: &str, path: &str) -> anyhow::Result<Vec<u8>> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/storage/v1/object/{bucket}/{path}", ctx.url);
    let resp = http()
        .get(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .send()
        .await
        .with_context(|| format!("GET {url}"))?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("storage download {bucket}/{path}: {status} {body}"));
    }
    let bytes = resp.bytes().await.context("read storage body")?;
    Ok(bytes.to_vec())
}

pub async fn storage_delete(bucket: &str, path: &str) -> anyhow::Result<()> {
    let ctx = auth_ctx().await?;
    let url = format!("{}/storage/v1/object/{bucket}/{path}", ctx.url);
    let resp = http()
        .delete(&url)
        .header("apikey", &ctx.anon_key)
        .header(header::AUTHORIZATION, format!("Bearer {}", ctx.jwt))
        .send()
        .await
        .with_context(|| format!("DELETE {url}"))?;
    if !resp.status().is_success() && resp.status() != StatusCode::NOT_FOUND {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(anyhow!("storage delete {bucket}/{path}: {status} {body}"));
    }
    Ok(())
}
