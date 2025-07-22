use std::ops::Deref;
use flutter_rust_bridge::frb;
use tokio::sync::{RwLock, RwLockReadGuard};
use crate::database::Database;
use crate::handlers::{Handler, HandlerCreator};
use crate::jobs::BackgroundJobHandler;

pub mod trips;
pub mod packing_list;
pub mod accommodations;
pub mod attachments;
pub mod points_of_interest;
pub mod bookings;
pub mod timeline;
pub mod transits;

static DB: RwLock<Option<Database>> = RwLock::const_new(None);

#[frb(ignore)]
pub(crate) struct HandlerGuard<'a, T: Send> {
    db_guard: RwLockReadGuard<'a, Option<Database>>,
    handler: T,
}

impl<'a, T: Send> Deref for HandlerGuard<'a, T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.handler
    }
}

impl HandlerCreator for RwLock<Option<Database>> {
    type Guard<'a, T: Handler> = HandlerGuard<'a, T>;

    async fn try_get<'a, T: Handler>(&'a self) -> anyhow::Result<Self::Guard<'a, T>> {
        let db_guard = self.read().await;
        let db = db_guard.as_ref().unwrap();
        let handler = T::create(db.clone());

        Ok(HandlerGuard {
            db_guard,
            handler,
        })
    }
}

#[frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    // flutter_rust_bridge::setup_default_user_utils();

    crate::logger::init();
}

pub async fn connect_db() -> anyhow::Result<()> {
    let database = Database::new().await?;
    let mut db = DB.write().await;
    *db = Some(database);

    Ok(())
}


#[tracing::instrument]
pub async fn run_background_jobs() -> anyhow::Result<()> {
    let handler = DB.try_get::<BackgroundJobHandler>().await?;
    handler.run().await
}
