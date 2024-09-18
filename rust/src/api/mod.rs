use std::ops::Deref;
use flutter_rust_bridge::frb;
use parking_lot::{RwLock, RwLockReadGuard};
use crate::database::Database;
use crate::handlers::{Handler, HandlerCreator};
use crate::jobs::BackgroundJobHandler;

pub mod trips;
pub mod packing_list;
pub mod attachments;

static DB: RwLock<Option<Database>> = RwLock::new(None);

#[frb(opaque)]
pub(crate) struct HandlerGuard<'a, T> {
    db_guard: RwLockReadGuard<'a, Option<Database>>,
    handler: T,
}

impl<'a, T> Deref for HandlerGuard<'a, T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.handler
    }
}

impl HandlerCreator for RwLock<Option<Database>> {
    type Guard<'a, T: Handler> = HandlerGuard<'a, T>;

    fn try_get<'a, T: Handler>(&'a self) -> anyhow::Result<Self::Guard<'a, T>> {
        let db_guard = self.read();
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
    let mut db = DB.write();
    *db = Some(Database::new());
}

#[tracing::instrument]
pub fn run_background_jobs() -> anyhow::Result<()> {
    let handler = DB.try_get::<BackgroundJobHandler>()?;
    handler.run()
}
