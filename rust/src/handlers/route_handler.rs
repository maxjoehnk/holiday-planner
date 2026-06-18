use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::commands::{ImportKomootRoute, UpdateRoute};
use crate::database::entities::route::{self, RouteProvider as EntityRouteProvider};
use crate::database::{repositories, Database};
use crate::handlers::Handler;
use crate::models::{Coordinate, RouteModel, RoutePoint, RouteProvider};
use crate::third_party::komoot;

pub struct RouteHandler {
    db: Database,
}

impl Handler for RouteHandler {
    fn create(db: Database) -> Self {
        Self { db }
    }
}

impl RouteHandler {
    pub async fn import_komoot_route(
        &self,
        command: ImportKomootRoute,
    ) -> anyhow::Result<RouteModel> {
        let tour_ref = komoot::parse_tour_ref(&command.tour_url)
            .ok_or_else(|| anyhow::anyhow!("Could not parse Komoot tour from URL"))?;

        tracing::debug!(
            "Importing Komoot {:?} {} into trip {}",
            tour_ref.kind,
            tour_ref.id,
            command.trip_id
        );

        let tour = komoot::fetch_tour(&tour_ref).await?;

        let polyline_points: Vec<StoredPoint> = tour
            .coordinates
            .iter()
            .map(|c| StoredPoint {
                lat: c.latitude,
                lng: c.longitude,
                alt: c.altitude,
            })
            .collect();
        let polyline_json = serde_json::to_string(&polyline_points)?;
        let start = tour
            .coordinates
            .first()
            .copied()
            .ok_or_else(|| anyhow::anyhow!("Komoot tour returned empty coordinate list"))?;
        let external_url = komoot::tour_url(&tour_ref);
        // Namespace ids by kind so a tour and a smarttour that happen to share a
        // numeric id don't collide on the unique (trip, provider, id) index.
        let provider_route_id = format!(
            "{}:{}",
            match tour_ref.kind {
                komoot::KomootTourKind::Tour => "tour",
                komoot::KomootTourKind::SmartTour => "smarttour",
            },
            tour_ref.id
        );

        let existing = repositories::routes::find_by_provider_route(
            &self.db,
            command.trip_id,
            EntityRouteProvider::Komoot,
            &provider_route_id,
        )
        .await?;

        let saved_id = if let Some(existing) = existing {
            let preserved_note = existing.note.clone();
            let id = existing.id;
            let mut active = existing.into_active_model();
            active.name.set_if_not_equals(tour.name.clone());
            active.sport.set_if_not_equals(tour.sport.clone());
            active
                .distance_meters
                .set_if_not_equals(tour.distance_meters);
            active
                .duration_seconds
                .set_if_not_equals(tour.duration_seconds);
            active
                .elevation_up_meters
                .set_if_not_equals(tour.elevation_up_meters);
            active
                .elevation_down_meters
                .set_if_not_equals(tour.elevation_down_meters);
            active.start_latitude.set_if_not_equals(start.latitude);
            active.start_longitude.set_if_not_equals(start.longitude);
            active.polyline.set_if_not_equals(polyline_json);
            active.note.set_if_not_equals(preserved_note);
            active.external_url.set_if_not_equals(external_url.clone());
            repositories::routes::update(&self.db, active).await?;
            id
        } else {
            // Content-addressed id so two members importing the same
            // Komoot tour offline arrive at the same row instead of
            // hitting the server-side
            // `(trip_id, provider, provider_route_id)` unique
            // constraint with two different uuid_v4 ids.
            let id = crate::sync::wire::route_id_for(
                command.trip_id,
                "komoot",
                &provider_route_id,
            );
            let active = route::ActiveModel {
                id: Set(id),
                trip_id: Set(command.trip_id),
                provider: Set(EntityRouteProvider::Komoot),
                provider_route_id: Set(provider_route_id),
                name: Set(tour.name.clone()),
                sport: Set(tour.sport.clone()),
                distance_meters: Set(tour.distance_meters),
                duration_seconds: Set(tour.duration_seconds),
                elevation_up_meters: Set(tour.elevation_up_meters),
                elevation_down_meters: Set(tour.elevation_down_meters),
                start_latitude: Set(start.latitude),
                start_longitude: Set(start.longitude),
                polyline: Set(polyline_json),
                note: Set(None),
                external_url: Set(external_url),
                trip_day_id: Set(None),
                day_order: Set(None),
                scheduled_at: Set(None),
                updated_at: Set(chrono::Utc::now()),
                deleted_at: Set(None),
                last_modified_by: Set(crate::sync::session::current_user().await.map(|u| u.to_string())),
            };
            repositories::routes::insert(&self.db, active).await?;
            id
        };

        let model = repositories::routes::find_by_id(&self.db, saved_id)
            .await?
            .ok_or_else(|| anyhow::anyhow!("Route disappeared after write"))?;
        self.enqueue_after_write(saved_id, crate::database::entities::pending_mutation::MutationOperation::Insert).await?;
        to_model(model)
    }

    pub async fn get_trip_routes(&self, trip_id: Uuid) -> anyhow::Result<Vec<RouteModel>> {
        let routes = repositories::routes::find_all_by_trip(&self.db, trip_id).await?;
        routes.into_iter().map(to_model).collect()
    }

    pub async fn update_route(&self, command: UpdateRoute) -> anyhow::Result<()> {
        let Some(route) = repositories::routes::find_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown route");
        };
        let mut active = route.into_active_model();
        active.note.set_if_not_equals(command.note);
        active.updated_at = sea_orm::ActiveValue::Set(chrono::Utc::now());
        active.last_modified_by = sea_orm::ActiveValue::Set(
            crate::sync::session::current_user().await.map(|u| u.to_string()),
        );
        repositories::routes::update(&self.db, active).await?;
        self.enqueue_after_write(command.id, crate::database::entities::pending_mutation::MutationOperation::Update).await?;
        Ok(())
    }

    pub async fn delete_route(&self, route_id: Uuid) -> anyhow::Result<()> {
        repositories::routes::delete_by_id(&self.db, route_id).await?;
        if crate::sync::session::current_user().await.is_some() {
            crate::sync::push::enqueue_if_signed_in(
                &self.db,
                "routes",
                route_id,
                crate::database::entities::pending_mutation::MutationOperation::Delete,
                &serde_json::json!({ "id": route_id }),
            )
            .await?;
        }
        Ok(())
    }

    async fn enqueue_after_write(
        &self,
        id: Uuid,
        op: crate::database::entities::pending_mutation::MutationOperation,
    ) -> anyhow::Result<()> {
        if crate::sync::session::current_user().await.is_none() {
            return Ok(());
        }
        let Some(model) = repositories::routes::find_by_id(&self.db, id).await? else {
            return Ok(());
        };
        let row = crate::sync::wire::RouteRow::from_model(&model);
        crate::sync::push::enqueue_if_signed_in(&self.db, "routes", id, op, &row).await
    }
}

#[derive(Serialize, Deserialize)]
struct StoredPoint {
    lat: f64,
    lng: f64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    alt: Option<f64>,
}

fn to_model(model: route::Model) -> anyhow::Result<RouteModel> {
    let stored: Vec<StoredPoint> = serde_json::from_str(&model.polyline)?;
    let polyline = stored
        .into_iter()
        .map(|p| RoutePoint {
            coordinate: Coordinate {
                latitude: p.lat,
                longitude: p.lng,
            },
            altitude: p.alt,
        })
        .collect();

    Ok(RouteModel {
        id: model.id,
        trip_id: model.trip_id,
        provider: RouteProvider::from(model.provider),
        provider_route_id: model.provider_route_id,
        name: model.name,
        sport: model.sport,
        distance_meters: model.distance_meters,
        duration_seconds: model.duration_seconds,
        elevation_up_meters: model.elevation_up_meters,
        elevation_down_meters: model.elevation_down_meters,
        start_coordinate: Coordinate {
            latitude: model.start_latitude,
            longitude: model.start_longitude,
        },
        polyline,
        note: model.note,
        external_url: model.external_url,
    })
}
