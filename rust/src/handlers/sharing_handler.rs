//! Trip sharing: invite by email, list members, remove members, leave.
//!
//! Mutations go straight to Supabase (RPC for invite, direct PostgREST for
//! delete) rather than through the `pending_mutations` queue — there's
//! nothing useful to do for these operations when offline, so failing
//! fast is correct.
//!
//! There are no roles: a trip has an owner (the creator) plus optional
//! members. Owner and members have identical read/write access on the
//! trip and its children; only the owner can invite or remove others.

use std::ops::Deref;

use anyhow::{anyhow, Context};
use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder};
use serde_json::json;
use uuid::Uuid;

use crate::database::entities::profile::Entity as Profile;
use crate::database::entities::trip::Entity as Trip;
use crate::database::entities::trip_member::{self, Entity as TripMember};
use crate::database::Database;
use crate::handlers::Handler;
use crate::sync;

pub struct SharingHandler {
    db: Database,
}

impl Handler for SharingHandler {
    fn create(db: Database) -> Self {
        Self { db }
    }
}

#[derive(Debug, Clone)]
pub struct TripMemberSummary {
    pub user_id: Uuid,
    pub email: Option<String>,
    pub display_name: Option<String>,
    pub is_owner: bool,
    pub is_self: bool,
}

#[derive(Debug, Clone)]
pub struct PendingInvite {
    pub id: Uuid,
    pub email: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

impl SharingHandler {
    pub async fn list_members(&self, trip_id: Uuid) -> anyhow::Result<Vec<TripMemberSummary>> {
        let trip = Trip::find_by_id(trip_id)
            .one(self.db.deref())
            .await?
            .ok_or_else(|| anyhow!("Trip not found"))?;
        let owner_uuid: Option<Uuid> = trip
            .owner_id
            .as_deref()
            .and_then(|s| Uuid::parse_str(s).ok());
        let current_user = sync::session::current_user().await;

        let mut members = Vec::new();

        if let Some(owner) = owner_uuid {
            let profile = Profile::find_by_id(owner).one(self.db.deref()).await?;
            members.push(TripMemberSummary {
                user_id: owner,
                email: profile.as_ref().map(|p| p.email.clone()),
                display_name: profile.and_then(|p| p.display_name),
                is_owner: true,
                is_self: current_user == Some(owner),
            });
        }

        let rows = TripMember::find()
            .filter(trip_member::Column::TripId.eq(trip_id))
            .order_by_asc(trip_member::Column::AddedAt)
            .all(self.db.deref())
            .await?;

        for row in rows {
            if Some(row.user_id) == owner_uuid {
                continue;
            }
            let profile = Profile::find_by_id(row.user_id).one(self.db.deref()).await?;
            members.push(TripMemberSummary {
                user_id: row.user_id,
                email: profile.as_ref().map(|p| p.email.clone()),
                display_name: profile.and_then(|p| p.display_name),
                is_owner: false,
                is_self: current_user == Some(row.user_id),
            });
        }
        Ok(members)
    }

    pub async fn invite_member(
        &self,
        trip_id: Uuid,
        email: String,
    ) -> anyhow::Result<()> {
        if sync::session::current_user().await.is_none() {
            anyhow::bail!("You need to be signed in to invite collaborators.");
        }
        sync::http::rpc(
            "invite_to_trip",
            &json!({
                "p_trip_id": trip_id,
                "p_email": email,
            }),
        )
        .await
        .context("invite_to_trip RPC failed")?;
        Ok(())
    }

    pub async fn remove_member(&self, trip_id: Uuid, user_id: Uuid) -> anyhow::Result<()> {
        if sync::session::current_user().await.is_none() {
            anyhow::bail!("Not signed in");
        }
        let now = chrono::Utc::now();
        let url = format!("trip_members?trip_id=eq.{trip_id}&user_id=eq.{user_id}");
        sync::http::patch_by_query(&url, &json!({ "deleted_at": now, "updated_at": now })).await?;
        TripMember::delete_by_id((trip_id, user_id))
            .exec(self.db.deref())
            .await?;
        Ok(())
    }

    pub async fn leave_trip(&self, trip_id: Uuid) -> anyhow::Result<()> {
        let me = sync::session::current_user()
            .await
            .ok_or_else(|| anyhow!("Not signed in"))?;
        self.remove_member(trip_id, me).await
    }

    /// Pull every trip_invites row for this trip directly from
    /// PostgREST. RLS already restricts the result set to invites the
    /// caller is allowed to see (trip members). We don't mirror these
    /// locally because they're short-lived — they vanish the moment the
    /// invitee signs up.
    pub async fn list_outbound_invites(
        &self,
        trip_id: Uuid,
    ) -> anyhow::Result<Vec<PendingInvite>> {
        if sync::session::current_user().await.is_none() {
            return Ok(Vec::new());
        }
        let query = format!("trip_invites?trip_id=eq.{trip_id}&order=created_at.asc");
        let rows = sync::http::select(&query).await?;
        let mut out = Vec::with_capacity(rows.len());
        for row in rows {
            let id = row
                .get("id")
                .and_then(|v| v.as_str())
                .and_then(|s| Uuid::parse_str(s).ok())
                .ok_or_else(|| anyhow!("invite row missing id"))?;
            let email = row
                .get("email")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow!("invite row missing email"))?
                .to_string();
            let created_at = row
                .get("created_at")
                .and_then(|v| v.as_str())
                .and_then(|s| chrono::DateTime::parse_from_rfc3339(s).ok())
                .map(|d| d.with_timezone(&chrono::Utc))
                .ok_or_else(|| anyhow!("invite row missing created_at"))?;
            out.push(PendingInvite { id, email, created_at });
        }
        Ok(out)
    }

    /// Cancel a pending invite by id. No-op if the row is already gone
    /// (e.g. the invitee signed up between fetch and revoke).
    pub async fn revoke_invite(&self, invite_id: Uuid) -> anyhow::Result<()> {
        if sync::session::current_user().await.is_none() {
            anyhow::bail!("Not signed in");
        }
        sync::http::delete_by_id("trip_invites", &invite_id.to_string()).await?;
        Ok(())
    }
}
