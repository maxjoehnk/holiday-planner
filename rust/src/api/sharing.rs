use uuid::Uuid;

use super::DB;
use crate::handlers::{HandlerCreator, SharingHandler};
use super::events::{self, DataChangeEvent};

#[derive(Clone, Debug)]
pub struct TripMemberModel {
    pub user_id: Uuid,
    pub email: Option<String>,
    pub display_name: Option<String>,
    pub is_owner: bool,
    pub is_self: bool,
}

#[tracing::instrument]
pub async fn list_trip_members(trip_id: Uuid) -> anyhow::Result<Vec<TripMemberModel>> {
    let handler = DB.try_get::<SharingHandler>().await?;
    let summaries = handler.list_members(trip_id).await?;
    Ok(summaries
        .into_iter()
        .map(|m| TripMemberModel {
            user_id: m.user_id,
            email: m.email,
            display_name: m.display_name,
            is_owner: m.is_owner,
            is_self: m.is_self,
        })
        .collect())
}

#[tracing::instrument(skip(email))]
pub async fn invite_trip_member(trip_id: Uuid, email: String) -> anyhow::Result<()> {
    let handler = DB.try_get::<SharingHandler>().await?;
    handler.invite_member(trip_id, email).await?;
    events::emit(DataChangeEvent::TripMembersChanged { trip_id });
    Ok(())
}

#[tracing::instrument]
pub async fn remove_trip_member(trip_id: Uuid, user_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<SharingHandler>().await?;
    handler.remove_member(trip_id, user_id).await?;
    events::emit(DataChangeEvent::TripMembersChanged { trip_id });
    Ok(())
}

#[tracing::instrument]
pub async fn leave_trip(trip_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<SharingHandler>().await?;
    handler.leave_trip(trip_id).await?;
    events::emit(DataChangeEvent::TripMembersChanged { trip_id });
    Ok(())
}

#[derive(Clone, Debug)]
pub struct PendingInviteModel {
    pub id: Uuid,
    pub email: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[tracing::instrument]
pub async fn list_outbound_invites(trip_id: Uuid) -> anyhow::Result<Vec<PendingInviteModel>> {
    let handler = DB.try_get::<SharingHandler>().await?;
    let invites = handler.list_outbound_invites(trip_id).await?;
    Ok(invites
        .into_iter()
        .map(|i| PendingInviteModel {
            id: i.id,
            email: i.email,
            created_at: i.created_at,
        })
        .collect())
}

#[tracing::instrument]
pub async fn revoke_invite(trip_id: Uuid, invite_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<SharingHandler>().await?;
    handler.revoke_invite(invite_id).await?;
    events::emit(DataChangeEvent::TripMembersChanged { trip_id });
    Ok(())
}
